import 'package:flutter/foundation.dart';

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InspectionState &&
        listEquals(other.inspections, inspections) &&
        other.isLoading == isLoading &&
        other.refreshCooldown == refreshCooldown &&
        other.isDirty == isDirty &&
        mapEquals(other.submittingStates, submittingStates) &&
        mapEquals(other.uploadingImagesStates, uploadingImagesStates);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(inspections),
        isLoading,
        refreshCooldown,
        isDirty,
        Object.hashAll(
          submittingStates.entries.map((e) => Object.hash(e.key, e.value)),
        ),
        Object.hashAll(
          uploadingImagesStates.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );
}
