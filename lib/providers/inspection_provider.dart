import 'dart:async';
import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/inspection_state.dart';
import '../models/local_inspection.dart';
import '../services/api_services.dart';
import '../services/local_storage_services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/connectivity_checker.dart';

part 'inspection_provider.g.dart';

@Riverpod(keepAlive: true)
class InspectionNotifier extends _$InspectionNotifier {
  Timer? _cooldownTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  InspectionState build() {
    ref.onDispose(() {
      _cooldownTimer?.cancel();
      _connectivitySubscription?.cancel();
    });
    _startConnectivityListener();
    return const InspectionState();
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        final hasInternet = await ConnectivityChecker.hasInternetConnection();
        if (hasInternet) await _autoSubmitPending();
      }
    });
  }

  Future<void> _autoSubmitPending() async {
    try {
      final pending = await LocalStorageService.getPendingInspections();
      if (pending.isEmpty) return;
      for (final inspection in pending) {
        if (!(state.submittingStates[inspection.id] ?? false)) {
          await retrySubmission(inspection);
        }
      }
      state = state.copyWith(isDirty: true);
    } catch (e) {
      log('Error auto-submitting pending inspections: $e');
    }
  }

  void _startRefreshCooldown() {
    _cooldownTimer?.cancel();
    state = state.copyWith(refreshCooldown: true);
    _cooldownTimer = Timer(const Duration(seconds: 10), () {
      state = state.copyWith(refreshCooldown: false);
    });
  }

  Future<void> loadInspections() async {
    if (state.isLoading || state.refreshCooldown || !state.isDirty) return;

    _startRefreshCooldown();
    state = state.copyWith(isLoading: true);

    try {
      final inspections = await LocalStorageService.getPendingInspections();
      inspections.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = state.copyWith(
        inspections: inspections,
        isDirty: false,
        isLoading: false,
        submittingStates: {for (var i in inspections) i.id: false},
        uploadingImagesStates: {for (var i in inspections) i.id: false},
      );

      final hasInternet = await ConnectivityChecker.hasInternetConnection();
      if (hasInternet) await syncPendingImages();
    } catch (e) {
      log('Error loading inspections: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> syncPendingImages() async {
    try {
      final pending =
          await LocalStorageService.getInspectionsWithPendingImages();

      for (var inspection in pending) {
        if (inspection.pendingImages.isEmpty) continue;

        state = state.copyWith(
          uploadingImagesStates: {
            ...state.uploadingImagesStates,
            inspection.id: true,
          },
        );

        final uploadedImages = <String, String>{};

        for (var entry in inspection.pendingImages.entries) {
          final result = await ApiService.uploadImage(
            entry.value.imagePath,
            inspectionId: null,
            section: entry.value.section,
            itemId: entry.value.itemId,
          );

          if (result['success'] == true) {
            uploadedImages[entry.key] = result['url'] as String;
          }
        }

        if (uploadedImages.isNotEmpty) {
          await LocalStorageService.updateInspectionImages(
            inspectionId: inspection.id,
            uploadedImages: uploadedImages,
          );
        }

        state = state.copyWith(
          uploadingImagesStates: {
            ...state.uploadingImagesStates,
            inspection.id: false,
          },
        );
      }

      state = state.copyWith(isDirty: true);
      await loadInspections();
    } catch (e) {
      log('Error syncing pending images: $e');
    }
  }

  Future<bool> retrySubmission(LocalInspection inspection) async {
    if (state.submittingStates[inspection.id] ?? false) return false;

    state = state.copyWith(
      submittingStates: {...state.submittingStates, inspection.id: true},
    );

    try {
      final hasInternet = await ConnectivityChecker.hasInternetConnection();
      if (!hasInternet) {
        state = state.copyWith(
          submittingStates: {...state.submittingStates, inspection.id: false},
        );
        return false;
      }

      var currentInspection = inspection;

      // Upload pending images
      if (inspection.pendingImages.isNotEmpty) {
        state = state.copyWith(
          uploadingImagesStates: {
            ...state.uploadingImagesStates,
            inspection.id: true,
          },
        );

        final uploadedImages = <String, String>{};

        for (var entry in inspection.pendingImages.entries) {
          final result = await ApiService.uploadImage(
            entry.value.imagePath,
            inspectionId: null,
            section: entry.value.section,
            itemId: entry.value.itemId,
          );
          if (result['success'] == true) {
            uploadedImages[entry.key] = result['url'] as String;
          }
        }

        if (uploadedImages.isNotEmpty) {
          await LocalStorageService.updateInspectionImages(
            inspectionId: inspection.id,
            uploadedImages: uploadedImages,
          );
          final updated = await LocalStorageService.getPendingInspections();
          currentInspection = updated.firstWhere(
            (i) => i.id == inspection.id,
            orElse: () => currentInspection,
          );
        }

        state = state.copyWith(
          uploadingImagesStates: {
            ...state.uploadingImagesStates,
            inspection.id: false,
          },
        );
      }

      // Upload local videos, audios, and files
      // Maps: localPath -> uploadedUrl (for in-data replacement)
      final videoReplacements = <String, String>{};
      final audioReplacements = <String, String>{};
      final fileReplacements = <String, String>{};

      for (var entry in currentInspection.videos.entries) {
        if (!entry.value.startsWith('http')) {
          final result = await ApiService.uploadImage(
            entry.value,
            section: '',
            itemId: entry.key,
            fieldName: 'video',
          );
          if (result['success'] == true) {
            videoReplacements[entry.value] = result['url'] as String;
          }
        }
      }

      for (var entry in currentInspection.audios.entries) {
        if (!entry.value.startsWith('http')) {
          final result = await ApiService.uploadImage(
            entry.value,
            section: '',
            itemId: entry.key,
            fieldName: 'audio',
          );
          if (result['success'] == true) {
            audioReplacements[entry.value] = result['url'] as String;
          }
        }
      }

      for (var entry in currentInspection.files.entries) {
        if (!entry.value.startsWith('http')) {
          final result = await ApiService.uploadImage(
            entry.value,
            section: '',
            itemId: entry.key,
            fieldName: 'file',
          );
          if (result['success'] == true) {
            fileReplacements[entry.value] = result['url'] as String;
          }
        }
      }

      // Persist uploaded media URLs to local storage
      if (videoReplacements.isNotEmpty ||
          audioReplacements.isNotEmpty ||
          fileReplacements.isNotEmpty) {
        await LocalStorageService.updateInspectionMedia(
          inspectionId: inspection.id,
          uploadedVideos: {
            for (var e in currentInspection.videos.entries)
              if (videoReplacements.containsKey(e.value))
                e.key: videoReplacements[e.value]!,
          },
          uploadedAudios: {
            for (var e in currentInspection.audios.entries)
              if (audioReplacements.containsKey(e.value))
                e.key: audioReplacements[e.value]!,
          },
          uploadedFiles: {
            for (var e in currentInspection.files.entries)
              if (fileReplacements.containsKey(e.value))
                e.key: fileReplacements[e.value]!,
          },
        );
      }

      // Build final submission payload with all uploaded URLs applied
      final inspectionData = Map<String, dynamic>.from(currentInspection.data);

      for (var entry in currentInspection.images.entries) {
        if (entry.value.startsWith('http')) {
          _updateNestedImagePath(inspectionData, entry.key, entry.value);
        }
      }
      for (var entry in videoReplacements.entries) {
        _replaceValueInData(inspectionData, entry.key, entry.value);
      }
      for (var entry in audioReplacements.entries) {
        _replaceValueInData(inspectionData, entry.key, entry.value);
      }
      for (var entry in fileReplacements.entries) {
        _replaceValueInData(inspectionData, entry.key, entry.value);
      }

      final result = await ApiService.sendInspectionData(inspectionData);

      if (result['success'] == true) {
        await LocalStorageService.markInspectionAsSubmitted(inspection.id);
        final updatedList = state.inspections
            .where((i) => i.id != inspection.id)
            .toList();
        final updatedSubmitting =
            Map<String, bool>.from(state.submittingStates)
              ..remove(inspection.id);
        final updatedUploading =
            Map<String, bool>.from(state.uploadingImagesStates)
              ..remove(inspection.id);
        state = state.copyWith(
          inspections: updatedList,
          submittingStates: updatedSubmitting,
          uploadingImagesStates: updatedUploading,
        );
        return true;
      } else {
        state = state.copyWith(
          submittingStates: {
            ...state.submittingStates,
            inspection.id: false,
          },
        );
        return false;
      }
    } catch (e) {
      log('Error submitting inspection ${inspection.id}: $e');
      state = state.copyWith(
        submittingStates: {...state.submittingStates, inspection.id: false},
      );
      return false;
    }
  }

  Future<void> deleteInspection(String id) async {
    if (state.isLoading || (state.submittingStates[id] ?? false)) return;

    state = state.copyWith(isLoading: true);
    try {
      await LocalStorageService.deleteInspection(id);
      state = state.copyWith(isDirty: true, isLoading: false);
      await loadInspections();
    } catch (e) {
      log('Error deleting inspection: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void markDirty() {
    state = state.copyWith(isDirty: true);
  }

  void _replaceValueInData(
    Map<String, dynamic> data,
    String oldValue,
    String newValue,
  ) {
    for (final key in data.keys.toList()) {
      final val = data[key];
      if (val is String && val == oldValue) {
        data[key] = newValue;
      } else if (val is Map<String, dynamic>) {
        _replaceValueInData(val, oldValue, newValue);
      } else if (val is List) {
        _replaceValueInList(val, oldValue, newValue);
      }
    }
  }

  void _replaceValueInList(
    List<dynamic> list,
    String oldValue,
    String newValue,
  ) {
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is String && item == oldValue) {
        list[i] = newValue;
      } else if (item is Map<String, dynamic>) {
        _replaceValueInData(item, oldValue, newValue);
      } else if (item is List) {
        _replaceValueInList(item, oldValue, newValue);
      }
    }
  }

  void _updateNestedImagePath(
    Map<String, dynamic> data,
    String key,
    String url,
  ) {
    if (data.containsKey('inspection_data')) {
      final inspectionData = data['inspection_data'];
      if (inspectionData is List) {
        for (var section in inspectionData) {
          if (section is Map<String, dynamic> &&
              section.containsKey('items')) {
            for (var item in section['items'] as List<dynamic>) {
              if (item is Map<String, dynamic>) {
                if (item['id'] == key && item.containsKey('imagePath')) {
                  item['imagePath'] = url;
                }
                if (item.containsKey('multiImages') &&
                    item['multiImages'] is List) {
                  for (var img in item['multiImages'] as List<dynamic>) {
                    if (img is Map<String, dynamic> &&
                        img.containsKey('imagePath')) {
                      final p = img['imagePath'];
                      if (p is String && !p.startsWith('http')) {
                        img['imagePath'] = url;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    if (data.containsKey('summaryImages')) {
      final summaryImages = data['summaryImages'];
      if (summaryImages is List) {
        for (var img in summaryImages) {
          if (img is Map<String, dynamic> &&
              img['key'] == key &&
              img.containsKey('imagePath')) {
            img['imagePath'] = url;
          }
        }
      }
    }
  }
}
