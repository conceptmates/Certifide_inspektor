import 'local_inspection.dart';

class InspectionState {
  final List<LocalInspection> inspections;
  final bool isLoading;
  final bool refreshCooldown;
  final bool isDirty;
  final Map<String, bool> submittingStates;
  final Map<String, bool> uploadingImagesStates;

  const InspectionState({
    this.inspections = const [],
    this.isLoading = false,
    this.refreshCooldown = false,
    this.isDirty = true,
    this.submittingStates = const {},
    this.uploadingImagesStates = const {},
  });

  InspectionState copyWith({
    List<LocalInspection>? inspections,
    bool? isLoading,
    bool? refreshCooldown,
    bool? isDirty,
    Map<String, bool>? submittingStates,
    Map<String, bool>? uploadingImagesStates,
  }) {
    return InspectionState(
      inspections: inspections ?? this.inspections,
      isLoading: isLoading ?? this.isLoading,
      refreshCooldown: refreshCooldown ?? this.refreshCooldown,
      isDirty: isDirty ?? this.isDirty,
      submittingStates: submittingStates ?? this.submittingStates,
      uploadingImagesStates:
          uploadingImagesStates ?? this.uploadingImagesStates,
    );
  }
}
