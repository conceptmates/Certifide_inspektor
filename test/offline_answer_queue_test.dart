// Verifies the offline-after-init durability fix at the storage layer.
//
// Scenario being protected: an inspection is initialized online (so a server
// inspection id exists), the device goes offline, and the inspector fills in
// values/options (and possibly media) before leaving the screen WITHOUT
// pressing Submit. Previously, answer-only fields (no attached media) were
// dropped entirely and the queue container was deleted whenever it had no
// pending media, so that offline progress never synced.
//
// These tests exercise the pure-Hive queue logic that now preserves those
// answers (`pendingAnswerSteps`) and keeps the container alive until they are
// replayed on reconnect. No network / path_provider is involved.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:certifide_inspektor/models/local_inspection.dart';
import 'package:certifide_inspektor/models/pending_image.dart';
import 'package:certifide_inspektor/models/pending_media.dart';
import 'package:certifide_inspektor/services/local_storage_services.dart';

void main() {
  late Directory tmp;

  Map<String, dynamic> answerStep(String id, String section, String value) => {
        'section': section,
        'item': {'id': id, 'title': id, 'value': value},
      };

  setUpAll(() {
    tmp = Directory.systemTemp.createTempSync('offline_answer_queue_test');
    Hive.init(tmp.path);
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(LocalInspectionAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(PendingImageAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(PendingMediaAdapter());
  });

  // Each test starts from empty boxes so they stay isolated and deterministic.
  setUp(() async {
    await (await Hive.openLazyBox<LocalInspection>(
            LocalStorageService.INSPECTIONS_BOX))
        .clear();
    await (await Hive.openBox(LocalStorageService.INSPECTIONS_INDEX_BOX)).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    tmp.deleteSync(recursive: true);
  });

  group('upsertMediaQueue — answer-only offline progress', () {
    test(
        'Given media-less values entered offline, When queued, Then the '
        'container persists and surfaces in getInspectionsWithPendingSaveSteps',
        () async {
      // When
      final id = await LocalStorageService.upsertMediaQueue(
        serverInspectionId: 101,
        vehicleInfo: const {'registration_number': 'KA01AB1234'},
        pendingMedia: const {},
        saveStepItems: const {},
        answerStepItems: {
          'f1': answerStep('f1', 'documents', 'yes'),
          'f2': answerStep('f2', 'engine', 'pass'),
        },
      );

      // Then — the container exists and carries both answers.
      final container = await LocalStorageService.getMediaQueueById(id);
      expect(container, isNotNull);
      expect(container!.serverInspectionId, 101);
      final steps = (container.data['pendingAnswerSteps'] as Map);
      expect(steps.keys, containsAll(<String>['f1', 'f2']));

      // Then — it is found by the save-step drain query (ps flag set)...
      final pending =
          await LocalStorageService.getInspectionsWithPendingSaveSteps();
      expect(pending.map((e) => e.id), contains(id));

      // ...but is NOT treated as a full offline submission, nor as pending media.
      expect(await LocalStorageService.getPendingInspections(), isEmpty);
      expect(await LocalStorageService.getInspectionsWithPendingMedia(), isEmpty);
    });

    test(
        'Given nothing to upload or replay, When queued, Then no container is '
        'created', () async {
      final id = await LocalStorageService.upsertMediaQueue(
        serverInspectionId: 303,
        vehicleInfo: const {},
        pendingMedia: const {},
        saveStepItems: const {},
        answerStepItems: const {},
      );
      expect(await LocalStorageService.getMediaQueueById(id), isNull);
      expect(await LocalStorageService.getInspectionsWithPendingSaveSteps(),
          isEmpty);
    });

    test(
        'Given two offline commits for the same inspection, When queued, Then '
        'their answers accumulate (merge, not overwrite)', () async {
      final id = await LocalStorageService.upsertMediaQueue(
        serverInspectionId: 404,
        vehicleInfo: const {},
        pendingMedia: const {},
        saveStepItems: const {},
        answerStepItems: {'a': answerStep('a', 'documents', 'yes')},
      );
      await LocalStorageService.upsertMediaQueue(
        serverInspectionId: 404,
        vehicleInfo: const {},
        pendingMedia: const {},
        saveStepItems: const {},
        answerStepItems: {'b': answerStep('b', 'engine', 'fail')},
      );

      final container = await LocalStorageService.getMediaQueueById(id);
      final steps = (container!.data['pendingAnswerSteps'] as Map);
      expect(steps.keys, containsAll(<String>['a', 'b']));
    });
  });

  group('upsertMediaQueue — stale-container media path (iOS relaunch)', () {
    // Regression: on iOS the sandbox container path changes between launches,
    // so a media path captured in a previous session is absolute-but-stale.
    // upsertMediaQueue must re-base it onto the CURRENT documents root before
    // the existence check — otherwise the file reads as "missing" and the
    // offline media is silently dropped from the upload queue on relaunch.
    test(
        'Given media stored under a stale container prefix, When queued after '
        'relaunch, Then the entry is kept (not dropped as missing)', () async {
      // The file actually lives under the *current* docs root...
      final docsRoot = Directory('${tmp.path}/Documents_current')
        ..createSync(recursive: true);
      final imagesDir = Directory('${docsRoot.path}/inspection_images')
        ..createSync(recursive: true);
      File('${imagesDir.path}/photo.jpg').writeAsBytesSync(const [1, 2, 3]);

      // ...but it was persisted as an absolute path under a previous, now
      // non-existent container.
      const stalePath =
          '/var/old-container/Documents/inspection_images/photo.jpg';
      expect(File(stalePath).existsSync(), isFalse);

      LocalStorageService.debugDocsDirPath = docsRoot.path;
      addTearDown(() => LocalStorageService.debugDocsDirPath = null);

      final id = await LocalStorageService.upsertMediaQueue(
        serverInspectionId: 707,
        vehicleInfo: const {},
        pendingMedia: {
          'image_p': PendingMedia(
            localPath: stalePath,
            section: 'documents',
            itemId: 'p',
            mediaType: 'image',
            fieldKey: 'p',
          ),
        },
        saveStepItems: {'p': answerStep('p', 'documents', 'yes')},
        answerStepItems: const {},
      );

      final container = await LocalStorageService.getMediaQueueById(id);
      expect(container, isNotNull,
          reason: 'stale-but-resolvable media must not be dropped');
      expect(container!.pendingMedia.containsKey('image_p'), isTrue);
      expect(await LocalStorageService.getInspectionsWithPendingMedia(),
          hasLength(1));
    });
  });

  group('media-queue round-trip — resume rehydrate contract', () {
    // The inspection screen re-attaches offline media on resume by reading
    // back the queue's pendingMedia and mapping each entry by mediaType +
    // fieldKey to a form field (see _rehydratePendingMediaFromQueue). This
    // guards that those fields survive Hive persistence intact.
    test(
        'Given queued media of mixed types, When read back, Then each entry '
        'retains fieldKey, mediaType and localPath for re-attachment', () async {
      final img = File('${tmp.path}/r_img.jpg')..writeAsBytesSync(const [1]);
      final vid = File('${tmp.path}/r_vid.mp4')..writeAsBytesSync(const [2]);
      final m0 = File('${tmp.path}/r_m0.jpg')..writeAsBytesSync(const [3]);
      final m1 = File('${tmp.path}/r_m1.jpg')..writeAsBytesSync(const [4]);

      final id = await LocalStorageService.upsertMediaQueue(
        serverInspectionId: 808,
        vehicleInfo: const {},
        pendingMedia: {
          'image_engine': PendingMedia(
            localPath: img.path,
            section: 'Engine',
            itemId: 'engine_photo',
            mediaType: 'image',
            fieldKey: 'engine_photo',
          ),
          'video_engine': PendingMedia(
            localPath: vid.path,
            section: 'Engine',
            itemId: 'engine_video',
            mediaType: 'video',
            fieldKey: 'engine_video',
          ),
          'multi_damage_0': PendingMedia(
            localPath: m0.path,
            section: 'Damage',
            itemId: 'damage',
            mediaType: 'multiImage',
            fieldKey: 'damage',
          ),
          'multi_damage_1': PendingMedia(
            localPath: m1.path,
            section: 'Damage',
            itemId: 'damage',
            mediaType: 'multiImage',
            fieldKey: 'damage',
          ),
        },
        saveStepItems: const {},
      );

      final container = await LocalStorageService.getMediaQueueById(id);
      expect(container, isNotNull);
      final pending = container!.pendingMedia;

      // Single image/video re-attach by their own fieldKey.
      expect(pending['image_engine']!.mediaType, 'image');
      expect(pending['image_engine']!.fieldKey, 'engine_photo');
      expect(pending['image_engine']!.localPath, img.path);
      expect(pending['video_engine']!.fieldKey, 'engine_video');

      // Both multi-image frames share one fieldKey so they rebuild as a list.
      final multi = pending.values
          .where((e) => e.mediaType == 'multiImage' && e.fieldKey == 'damage')
          .map((e) => e.localPath)
          .toList();
      expect(multi, containsAll(<String>[m0.path, m1.path]));
    });
  });

  group('removeAnswerStepFor — draining replayed answers', () {
    test(
        'Given an answer-only container, When the last answer is removed, Then '
        'the whole container is deleted', () async {
      final id = await LocalStorageService.upsertMediaQueue(
        serverInspectionId: 202,
        vehicleInfo: const {},
        pendingMedia: const {},
        saveStepItems: const {},
        answerStepItems: {
          'f1': answerStep('f1', 'documents', 'yes'),
          'f2': answerStep('f2', 'engine', 'pass'),
        },
      );

      // Removing one leaves the container (f2 still pending).
      await LocalStorageService.removeAnswerStepFor(id, 'f1');
      expect(await LocalStorageService.getMediaQueueById(id), isNotNull);
      expect(
          await LocalStorageService.getInspectionsWithPendingSaveSteps(),
          hasLength(1));

      // Removing the last one drops the container entirely.
      await LocalStorageService.removeAnswerStepFor(id, 'f2');
      expect(await LocalStorageService.getMediaQueueById(id), isNull);
      expect(await LocalStorageService.getInspectionsWithPendingSaveSteps(),
          isEmpty);
    });
  });

  group('removePendingMedia — answer-step regression guard', () {
    test(
        'Given a container with media AND answers, When all media is drained, '
        'Then the container survives for the still-pending answers', () async {
      final file = File('${tmp.path}/regression_guard.jpg')
        ..writeAsBytesSync(const [1, 2, 3]);

      final id = await LocalStorageService.upsertMediaQueue(
        serverInspectionId: 505,
        vehicleInfo: const {},
        pendingMedia: {
          'image_x': PendingMedia(
            localPath: file.path,
            section: 'documents',
            itemId: 'x',
            mediaType: 'image',
            fieldKey: 'x',
          ),
        },
        saveStepItems: {'x': answerStep('x', 'documents', 'yes')},
        answerStepItems: {'y': answerStep('y', 'engine', 'pass')},
      );

      // Drain the only media entry (don't touch the local file in the test).
      await LocalStorageService.removePendingMedia(id, 'image_x',
          deleteLocalFile: false);

      // The container must NOT be deleted: answer-step 'y' is still unreplayed.
      final container = await LocalStorageService.getMediaQueueById(id);
      expect(container, isNotNull);
      expect(container!.pendingMedia, isEmpty);
      expect((container.data['pendingAnswerSteps'] as Map).containsKey('y'),
          isTrue);
      expect(
          await LocalStorageService.getInspectionsWithPendingSaveSteps(),
          hasLength(1));
    });

    test(
        'Given a media-only container (no answers), When its last media is '
        'drained, Then the container is deleted (existing behavior preserved)',
        () async {
      final file = File('${tmp.path}/media_only.jpg')
        ..writeAsBytesSync(const [4, 5, 6]);

      final id = await LocalStorageService.upsertMediaQueue(
        serverInspectionId: 606,
        vehicleInfo: const {},
        pendingMedia: {
          'image_z': PendingMedia(
            localPath: file.path,
            section: 'documents',
            itemId: 'z',
            mediaType: 'image',
            fieldKey: 'z',
          ),
        },
        saveStepItems: {'z': answerStep('z', 'documents', 'yes')},
        answerStepItems: const {},
      );

      await LocalStorageService.removePendingMedia(id, 'image_z',
          deleteLocalFile: false);

      expect(await LocalStorageService.getMediaQueueById(id), isNull);
    });
  });
}
