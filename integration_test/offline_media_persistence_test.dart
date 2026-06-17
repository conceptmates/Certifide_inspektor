// On-device verification of offline inspection persistence.
//
// Reproduces the user-reported Android scenario using the REAL stack
// (path_provider documents container, real Hive boxes on disk, real file
// copies): offline capture/edit -> force-close (Hive.close + re-init forces the
// next read from disk, like a fresh process) -> resume, asserting the values,
// images and queued media all survive and are retrievable.
//
// Run: flutter test integration_test/offline_media_persistence_test.dart -d <android>

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'package:certifide_inspektor/services/local_storage_services.dart';
import 'package:certifide_inspektor/models/pending_media.dart';
import 'package:certifide_inspektor/data/inspection_storage_model.dart';
import 'package:certifide_inspektor/constants/hive_constants.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---- Test 1: offline media survives a restart via the upload queue --------
  testWidgets(
      'offline media is stored locally and retrieved after an app restart',
      (tester) async {
    await LocalStorageService.init();

    const serverId = 999001;
    final queueId = LocalStorageService.mediaQueueId(serverId);
    await LocalStorageService.clearMediaQueueFor(serverId); // clean slate

    final tmp = await getTemporaryDirectory();
    final src = File('${tmp.path}/cap_${DateTime.now().microsecondsSinceEpoch}.jpg');
    await src.writeAsBytes(List<int>.generate(256, (i) => i % 256));
    final savedPath = await LocalStorageService.saveImage(src.path);

    expect(File(savedPath).existsSync(), isTrue,
        reason: 'captured media must be copied into local app storage');
    expect(savedPath.contains('/${LocalStorageService.IMAGES_DIR}/'), isTrue,
        reason: 'media must live under the inspection images dir');

    await LocalStorageService.upsertMediaQueue(
      serverInspectionId: serverId,
      vehicleInfo: const {'registration_number': 'TEST123'},
      pendingMedia: {
        'image_field1': PendingMedia(
          localPath: savedPath,
          section: 'Engine',
          itemId: 'field1',
          mediaType: 'image',
          fieldKey: 'field1',
        ),
      },
      saveStepItems: const {},
    );

    // Simulate an APP RESTART: close every box so the next read is from disk.
    await Hive.close();
    await LocalStorageService.init();

    final container = await LocalStorageService.getMediaQueueById(queueId);
    expect(container, isNotNull,
        reason: 'media queue container must survive an app restart');
    final entry = container!.pendingMedia['image_field1'];
    expect(entry, isNotNull);
    expect(entry!.fieldKey, 'field1');
    expect(entry.mediaType, 'image');

    final resolved = LocalStorageService.resolveMediaPath(entry.localPath);
    expect(File(resolved).existsSync(), isTrue,
        reason: 'offline media file must still exist after an app restart');

    await LocalStorageService.clearMediaQueueFor(serverId);
    try {
      await File(savedPath).delete();
    } catch (_) {}
    try {
      await src.delete();
    } catch (_) {}
  });

  // ---- Test 2: the live working copy (values + images) survives force-close --
  testWidgets(
      'field values and images persist in CURRENT_INSPECTION_KEY across a '
      'force-close and are retrieved on resume',
      (tester) async {
    // Boot the documents-dir cache used by resolveMediaPath.
    await LocalStorageService.init();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(InspectionStorageModelAdapter());
    }

    // An image captured during inspection (real file in app storage).
    final tmp = await getTemporaryDirectory();
    final src = File('${tmp.path}/fc_${DateTime.now().microsecondsSinceEpoch}.jpg');
    await src.writeAsBytes(List<int>.generate(256, (i) => (i * 7) % 256));
    final savedImage = await LocalStorageService.saveImage(src.path);

    // Save the live working copy exactly as _saveDataLocally() does.
    var box = await Hive.openBox<InspectionStorageModel>(
        HiveConstants.INSPECTION_BOX);
    await box.put(
      HiveConstants.CURRENT_INSPECTION_KEY,
      InspectionStorageModel(
        itemValues: {'regno': 'KA01AB1234', 'odometer': '54000'},
        itemImages: {'engine_photo': savedImage},
        itemRemarks: {'engine_photo': 'minor scratch'},
        currentSection: 2,
        inspectionId: 777,
        status: 'draft',
      ),
    );

    // FORCE-CLOSE: drop all in-memory boxes; next read must come from disk.
    await Hive.close();

    // RESUME (fresh process): reopen and read back.
    await LocalStorageService.init();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(InspectionStorageModelAdapter());
    }
    box = await Hive.openBox<InspectionStorageModel>(
        HiveConstants.INSPECTION_BOX);
    final restored = box.get(HiveConstants.CURRENT_INSPECTION_KEY);

    expect(restored, isNotNull,
        reason: 'the in-progress inspection must survive a force-close');
    // Field values retained.
    expect(restored!.typedItemValues['regno'], 'KA01AB1234');
    expect(restored.typedItemValues['odometer'], '54000');
    expect(restored.typedItemRemarks['engine_photo'], 'minor scratch');
    expect(restored.currentSection, 2);
    expect(restored.inspectionId, 777,
        reason: 'inspectionId is used to match the same inspection on resume');

    // Image reference retained AND the file still on disk + resolvable.
    final imgPath = restored.typedItemImages['engine_photo'];
    expect(imgPath, isNotNull);
    expect(File(LocalStorageService.resolveMediaPath(imgPath!)).existsSync(),
        isTrue,
        reason: 'the captured image file must survive a force-close');

    // cleanup
    await box.delete(HiveConstants.CURRENT_INSPECTION_KEY);
    try {
      await File(savedImage).delete();
    } catch (_) {}
    try {
      await src.delete();
    } catch (_) {}
  });
}
