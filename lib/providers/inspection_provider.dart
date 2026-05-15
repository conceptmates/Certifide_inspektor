import 'dart:async';
import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/inspection_state.dart';
import '../models/local_inspection.dart';
import '../services/api_services.dart';
import '../services/local_storage_services.dart';
import '../utils/connectivity_checker.dart';

part 'inspection_provider.g.dart';

@Riverpod(keepAlive: true)
class InspectionNotifier extends _$InspectionNotifier {
  Timer? _cooldownTimer;

  @override
  InspectionState build() {
    ref.onDispose(() => _cooldownTimer?.cancel());
    return const InspectionState();
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
          currentInspection =
              updated.firstWhere((i) => i.id == inspection.id);
        }

        state = state.copyWith(
          uploadingImagesStates: {
            ...state.uploadingImagesStates,
            inspection.id: false,
          },
        );
      }

      final inspectionData = Map<String, dynamic>.from(currentInspection.data);
      for (var entry in currentInspection.images.entries) {
        if (entry.value.startsWith('http')) {
          _updateNestedImagePath(inspectionData, entry.key, entry.value);
        }
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
