import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/inspection_template_model.dart';

part 'inspection_session_provider.g.dart';

class InspectionSessionSnapshot {
  final Map<String, String?> itemImages;
  final Map<String, String?> itemVideos;
  final Map<String, String?> itemAudios;
  final Map<String, String?> itemFiles;
  final Map<String, String> itemRemarks;
  final Map<String, String> itemValues;
  final Map<String, List<String>?> itemMultiImages;
  final Map<String, List<String>> itemFlaggedIssues;
  final int currentSection;
  final int currentItemIndex;
  final Map<String, dynamic>? vehicleDetails;
  final InspectionInitializationResponse? inspectionTemplate;
  final bool useDynamicTemplate;
  final int? sessionInspectionId;

  const InspectionSessionSnapshot({
    required this.itemImages,
    required this.itemVideos,
    required this.itemAudios,
    required this.itemFiles,
    required this.itemRemarks,
    required this.itemValues,
    required this.itemMultiImages,
    required this.itemFlaggedIssues,
    required this.currentSection,
    required this.currentItemIndex,
    required this.vehicleDetails,
    required this.inspectionTemplate,
    required this.useDynamicTemplate,
    required this.sessionInspectionId,
  });
}

/// Holds active inspection data in memory across screen navigations.
/// Cleared on successful submit or explicit abandon.
@Riverpod(keepAlive: true)
class InspectionSessionNotifier extends _$InspectionSessionNotifier {
  @override
  InspectionSessionSnapshot? build() => null;

  void saveSnapshot(InspectionSessionSnapshot snapshot) {
    state = snapshot;
  }

  void clearSession() {
    if (state != null) state = null;
  }
}
