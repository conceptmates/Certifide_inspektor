// lib/providers/inspection_provider.dart
import 'dart:async';
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
  Timer? _cooldownTimer;

  List<LocalInspection> get inspections => _inspections;
  bool get isLoading => _isLoading;
  bool get refreshCooldown => _refreshCooldown;
  Map<String, bool> get submittingStates => _submittingStates;

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

      // Automatically try to submit if internet is available
      final hasInternet = await ConnectivityChecker.hasInternetConnection();
      if (hasInternet) {
        await Future.wait(
            inspections.map((inspection) => retrySubmission(inspection)));
      }
    } catch (e) {
      print('Error loading inspections: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
        return false;
      }

      // Perform submission
      final result = await ApiService.sendInspectionData(inspection.data);

      if (result['success'] == true) {
        // Mark as submitted in local storage
        await LocalStorageService.markInspectionAsSubmitted(inspection.id);

        // Remove from local list
        _inspections.removeWhere((item) => item.id == inspection.id);
        _submittingStates.remove(inspection.id);

        notifyListeners();
        return true;
      } else {
        // Log specific failure reason if available
        print(
            'Submission failed for inspection ${inspection.id}: ${result['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('Error submitting inspection ${inspection.id}: $e');
      return false;
    } finally {
      // Ensure submitting state is reset
      _submittingStates[inspection.id] = false;
      notifyListeners();
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

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }
}
