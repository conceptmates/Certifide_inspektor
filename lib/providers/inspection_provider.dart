// lib/providers/inspection_provider.dart
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import '../models/local_inspection.dart';
import '../services/api_services.dart';
import '../services/local_storage_services.dart';
import '../utils/connectivity_checker.dart';

class InspectionProvider extends ChangeNotifier {
  List<LocalInspection> _inspections = [];
  bool _isLoading = false;
  bool _refreshCooldown = false;
  Map<String, bool> _submittingStates = {};
  Map<String, bool> _uploadingImagesStates = {};
  Timer? _cooldownTimer;

  List<LocalInspection> get inspections => _inspections;
  bool get isLoading => _isLoading;
  bool get refreshCooldown => _refreshCooldown;
  Map<String, bool> get submittingStates => _submittingStates;
  Map<String, bool> get uploadingImagesStates => _uploadingImagesStates;

  void startRefreshCooldown() {
    _refreshCooldown = true;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(seconds: 10), () {
      _refreshCooldown = false;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> loadInspections() async {
    // Prevent multiple simultaneous loading
    if (_isLoading || _refreshCooldown) return;

    startRefreshCooldown();
    _isLoading = true;
    notifyListeners();

    try {
      final inspections = await LocalStorageService.getPendingInspections();

      // Sort inspections by creation date (most recent first)
      inspections.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _inspections = inspections;
      _submittingStates = {
        for (var inspection in inspections) inspection.id: false
      };
      _uploadingImagesStates = {
        for (var inspection in inspections) inspection.id: false
      };

      // Automatically try to sync images if internet is available
      final hasInternet = await ConnectivityChecker.hasInternetConnection();
      if (hasInternet) {
        await syncPendingImages();
      }
    } catch (e) {
      print('Error loading inspections: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncPendingImages() async {
    try {
      final inspectionsWithPendingImages =
          await LocalStorageService.getInspectionsWithPendingImages();

      for (var inspection in inspectionsWithPendingImages) {
        if (inspection.pendingImages.isEmpty) continue;

        _uploadingImagesStates[inspection.id] = true;
        notifyListeners();

        final uploadedImages = <String, String>{};

        for (var entry in inspection.pendingImages.entries) {
          log('Uploading pending image: ${entry.key} from ${entry.value.imagePath}');
          log('Section: ${entry.value.section}, ItemId: ${entry.value.itemId}');

          final result = await ApiService.uploadImage(
            entry.value.imagePath,
            inspectionId: null,
            section: entry.value.section,
            itemId: entry.value.itemId,
          );

          if (result['success'] == true) {
            uploadedImages[entry.key] = result['url'] as String;
            log('Image uploaded successfully: ${result['url']}');
          } else {
            log('Failed to upload image: ${result['message']}');
            // Keep the local path and retry later
          }
        }

        // Update inspection with uploaded images
        if (uploadedImages.isNotEmpty) {
          await LocalStorageService.updateInspectionImages(
            inspectionId: inspection.id,
            uploadedImages: uploadedImages,
          );
        }

        _uploadingImagesStates[inspection.id] = false;
        notifyListeners();
      }

      // Reload inspections to get updated data
      await loadInspections();
    } catch (e) {
      log('Error syncing pending images: $e');
    }
  }

  Future<bool> retrySubmission(LocalInspection inspection) async {
    // Prevent multiple simultaneous submissions for the same inspection
    if (_submittingStates[inspection.id] ?? false) {
      return false;
    }

    try {
      // Set submitting state immediately
      _submittingStates[inspection.id] = true;
      notifyListeners();

      // Check internet connectivity
      final bool hasInternet =
          await ConnectivityChecker.hasInternetConnection();
      if (!hasInternet) {
        print('No internet connection for inspection ${inspection.id}');
        _submittingStates[inspection.id] = false;
        notifyListeners();
        return false;
      }

      // First, upload any pending images
      if (inspection.pendingImages.isNotEmpty) {
        log('Uploading pending images for inspection ${inspection.id}');
        _uploadingImagesStates[inspection.id] = true;
        notifyListeners();

        final uploadedImages = <String, String>{};

        for (var entry in inspection.pendingImages.entries) {
          log('Uploading pending image: ${entry.key}');
          log('Section: ${entry.value.section}, ItemId: ${entry.value.itemId}');

          final result = await ApiService.uploadImage(
            entry.value.imagePath,
            inspectionId: null,
            section: entry.value.section,
            itemId: entry.value.itemId,
          );

          if (result['success'] == true) {
            uploadedImages[entry.key] = result['url'] as String;
            log('Image uploaded: ${entry.key} -> ${result['url']}');
          } else {
            log('Failed to upload image ${entry.key}: ${result['message']}');
            // Continue with other images even if one fails
          }
        }

        // Update inspection with uploaded image URLs
        if (uploadedImages.isNotEmpty) {
          await LocalStorageService.updateInspectionImages(
            inspectionId: inspection.id,
            uploadedImages: uploadedImages,
          );

          // Reload to get updated inspection
          final updatedInspections =
              await LocalStorageService.getPendingInspections();
          final updatedInspection =
              updatedInspections.firstWhere((i) => i.id == inspection.id);

          // Update the local reference with uploaded URLs
          inspection = updatedInspection;
        }

        _uploadingImagesStates[inspection.id] = false;
      }

      // Prepare data with uploaded image URLs
      final inspectionData = Map<String, dynamic>.from(inspection.data);

      // Replace local image paths with uploaded URLs
      for (var entry in inspection.images.entries) {
        if (entry.value.startsWith('http')) {
          // Update the data map with the URL
          _updateNestedImagePath(inspectionData, entry.key, entry.value);
        }
      }

      // Perform submission
      final result = await ApiService.sendInspectionData(inspectionData);

      if (result['success'] == true) {
        // Mark as submitted in local storage
        await LocalStorageService.markInspectionAsSubmitted(inspection.id);

        // Remove from local list
        _inspections.removeWhere((item) => item.id == inspection.id);
        _submittingStates.remove(inspection.id);
        _uploadingImagesStates.remove(inspection.id);

        notifyListeners();
        return true;
      } else {
        // Log specific failure reason if available
        print(
            'Submission failed for inspection ${inspection.id}: ${result['message'] ?? 'Unknown error'}');
        _submittingStates[inspection.id] = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error submitting inspection ${inspection.id}: $e');
      _submittingStates[inspection.id] = false;
      notifyListeners();
      return false;
    }
  }

  void _updateNestedImagePath(
    Map<String, dynamic> data,
    String key,
    String url,
  ) {
    // This is a helper to update nested image paths in the data map
    // Implementation depends on how the data is structured
    if (data.containsKey('images')) {
      final images = data['images'] as Map<String, dynamic>?;
      if (images != null && images.containsKey(key)) {
        images[key] = url;
      }
    }
  }

  Future<void> deleteInspection(String id) async {
    if (_isLoading || (_submittingStates[id] ?? false)) return;

    _isLoading = true;
    notifyListeners();

    try {
      await LocalStorageService.deleteInspection(id);
      await loadInspections();
    } catch (e) {
      print('Error deleting inspection: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSubmittingState(String inspectionId, bool isSubmitting) {
    _submittingStates[inspectionId] = isSubmitting;
    notifyListeners();
  }

  void setUploadingImagesState(String inspectionId, bool isUploading) {
    _uploadingImagesStates[inspectionId] = isUploading;
    notifyListeners();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }
}
