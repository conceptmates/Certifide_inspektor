import '../models/drop_down.dart';

class InspectionItem<T> {
  final String id;
  final String title;
  final List<DropdownOption<T>>? options;
  final bool allowRemarks;
  final bool allowNumberRemark;
  final bool allowImage;
  final bool useTextField;
  final bool allowMultiImage;
  final bool useLargeRemarksField;
  final bool allowFileAttachment; // Add this new property

  String get uniqueId => id;

  const InspectionItem({
    required this.id,
    required this.title,
    this.options,
    this.allowRemarks = false,
    this.allowNumberRemark = false,
    this.allowImage = true,
    this.useTextField = false,
    this.allowMultiImage = false,
    this.useLargeRemarksField = false,
    this.allowFileAttachment = false, // Add this to constructor
  })  : assert(!(allowImage && allowMultiImage),
            'Cannot allow both single and multi image simultaneously'),
        assert(
            !(allowImage && allowFileAttachment), // Add this assertion
            'Cannot allow both image and file attachment simultaneously'),
        assert(
            (options != null && !useTextField) ||
                useTextField ||
                options == null,
            'Either options or useTextField must be provided, but not both');

  // Factory constructor for validation
  factory InspectionItem.create({
    required String id,
    required String title,
    List<DropdownOption<T>>? options,
    bool allowRemarks = false,
    bool allowNumberRemark = false,
    bool allowImage = true,
    bool useTextField = false,
  }) {
    if (options != null) {
      if (options.isEmpty) {
        throw ArgumentError('If options is provided, it cannot be empty');
      }

      if (useTextField) {
        throw ArgumentError('Cannot provide both options and useTextField');
      }

      // Ensure no duplicate values
      final values = options.map((o) => o.value).toSet();
      if (values.length != options.length) {
        throw ArgumentError('Duplicate values found in options');
      }
    }

    return InspectionItem(
      id: id,
      title: title,
      options: options,
      allowRemarks: allowRemarks,
      allowNumberRemark: allowNumberRemark,
      allowImage: allowImage,
      useTextField: useTextField,
    );
  }
}
