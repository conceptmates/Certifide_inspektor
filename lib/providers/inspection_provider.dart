import 'dart:async';
import 'dart:convert';
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
  bool _isAutoSubmitting = false;

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
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        // Schedule async work without propagating the Future to the listener,
        // and catch any errors explicitly so they don't become unhandled.
        Future(() async {
          try {
            final hasInternet =
                await ConnectivityChecker.hasInternetConnection();
            if (hasInternet) await _autoSubmitPending();
          } catch (e) {
            log('Connectivity listener error: $e');
          }
        });
      }
    });
  }

  Future<void> _autoSubmitPending() async {
    if (_isAutoSubmitting) return;
    _isAutoSubmitting = true;
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
    } finally {
      _isAutoSubmitting = false;
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

          final url = result['url'] as String?;
          if (result['success'] == true && url != null && url.isNotEmpty) {
            uploadedImages[entry.key] = url;
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
          final url = result['url'] as String?;
          if (result['success'] == true && url != null && url.isNotEmpty) {
            uploadedImages[entry.key] = url;
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
            fieldName: 'image',
          );
          final url = result['url'] as String?;
          if (result['success'] == true && url != null && url.isNotEmpty) {
            videoReplacements[entry.key] = url;
          }
        }
      }

      for (var entry in currentInspection.audios.entries) {
        if (!entry.value.startsWith('http')) {
          final result = await ApiService.uploadImage(
            entry.value,
            section: '',
            itemId: entry.key,
            fieldName: 'image',
          );
          final url = result['url'] as String?;
          if (result['success'] == true && url != null && url.isNotEmpty) {
            audioReplacements[entry.key] = url;
          }
        }
      }

      for (var entry in currentInspection.files.entries) {
        if (!entry.value.startsWith('http')) {
          final result = await ApiService.uploadImage(
            entry.value,
            section: '',
            itemId: entry.key,
            fieldName: 'image',
          );
          final url = result['url'] as String?;
          if (result['success'] == true && url != null && url.isNotEmpty) {
            fileReplacements[entry.key] = url;
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

      // Build final submission payload with all uploaded URLs applied.
      // Deep-copy so mutations to nested item maps don't affect Riverpod state.
      final inspectionData =
          json.decode(json.encode(currentInspection.data)) as Map<String, dynamic>;
      final itemIndex = <String, Map<String, dynamic>>{};
      List<dynamic>? summaryImages;

      final inspDataRaw = inspectionData['inspection_data'];
      if (inspDataRaw is Map<String, dynamic>) {
        for (final section in inspDataRaw.values) {
          if (section is Map<String, dynamic>) {
            final items = section['items'];
            if (items is List) {
              for (final item in items) {
                if (item is Map<String, dynamic> && item['id'] != null) {
                  itemIndex[item['id'].toString()] = item;
                }
              }
            }
          }
        }
      }
      final summaryRaw = inspectionData['summaryImages'];
      if (summaryRaw is List) summaryImages = summaryRaw;

      for (var entry in currentInspection.images.entries) {
        if (!entry.value.startsWith('http')) continue;
        final item = itemIndex[entry.key];
        if (item != null) {
          item['imagePath'] = entry.value;
          if (item['multiImages'] is List) {
            for (final img in item['multiImages'] as List<dynamic>) {
              if (img is Map<String, dynamic> && img.containsKey('imagePath')) {
                final p = img['imagePath'];
                if (p is String && !p.startsWith('http')) img['imagePath'] = entry.value;
              }
            }
          }
        }
        if (summaryImages != null) {
          for (final img in summaryImages) {
            if (img is Map<String, dynamic> && img['key'] == entry.key) {
              img['imagePath'] = entry.value;
            }
          }
        }
      }
      for (var entry in videoReplacements.entries) {
        itemIndex[entry.key]?['videoPath'] = entry.value;
      }
      for (var entry in audioReplacements.entries) {
        itemIndex[entry.key]?['audioPath'] = entry.value;
      }
      for (var entry in fileReplacements.entries) {
        itemIndex[entry.key]?['filePath'] = entry.value;
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

}
