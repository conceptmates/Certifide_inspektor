import 'inspection_item.dart';
import '../models/inspection_item.dart';

/// Group all inspection item lists so they can be accessed by key.
// final Map<String, List<InspectionItem<String>>> inspectionItemGroups = {
//   'summary': summary,
//   'documents': documents,
//   'floodAffectedSigns': floodAffectedSigns,
//   'afterWarmUp': afterWarmUp,
//   'testDrive': testDrive,
//   'coolant': coolant,
//   'brakeFluid': brakeFluid,
//   'dicky': dicky,
//   'ac': ac,
//   'interior': interior,
//   'exterior': exterior,
//   'tire': tire,
//   'underHood': underHood,
//   'battery': battery,
//   'dataSet1': dataSet1,
//   'dataSet2': dataSet2,
//   'bodyPanel': bodyPanel,
// // };

// /// Map inspection item ids to their entries; duplicates are grouped together.
// final Map<String, List<InspectionItem<String>>> inspectionItemsById =
//     _indexById(inspectionItemGroups);

// /// Simple list of group names for dropdowns or chips.
// final List<String> inspectionGroupNames =
//     List<String>.unmodifiable(inspectionItemGroups.keys);

// /// Group name → list of item ids for quick secondary dropdown population.
// final Map<String, List<String>> inspectionGroupItemIds =
//     _indexGroupItemIds(inspectionItemGroups);

// /// Flat list of all inspection item ids (deduped, preserves first-seen order).
// final List<String> inspectionItemIds =
//     List<String>.unmodifiable(_collectAllItemIds(inspectionItemGroups));

/// Convenience helper to fetch item ids for a specific group.
// List<String> getItemIdsForGroup(String groupName) =>
//     inspectionGroupItemIds[groupName] ?? const <String>[];

Map<String, List<InspectionItem<String>>> _indexById(
  Map<String, List<InspectionItem<String>>> groups,
) {
  final Map<String, List<InspectionItem<String>>> byId = {};
  groups.forEach((_, items) {
    for (final item in items) {
      byId.putIfAbsent(item.id, () => <InspectionItem<String>>[]).add(item);
    }
  });
  return byId;
}

Map<String, List<String>> _indexGroupItemIds(
  Map<String, List<InspectionItem<String>>> groups,
) {
  final Map<String, List<String>> byGroup = {};
  groups.forEach((name, items) {
    byGroup[name] = items.map((item) => item.id).toList(growable: false);
  });
  return byGroup;
}

List<String> _collectAllItemIds(
  Map<String, List<InspectionItem<String>>> groups,
) {
  final seen = <String>{};
  final ordered = <String>[];
  groups.forEach((_, items) {
    for (final item in items) {
      if (seen.add(item.id)) {
        ordered.add(item.id);
      }
    }
  });
  return ordered;
}
