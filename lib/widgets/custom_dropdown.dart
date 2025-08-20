import '../models/drop_down.dart';

class InspectionItem<T> {
  final String id;
  final String title;
  final List<DropdownOption<T>>? options;
  final bool allowRemarks;
  final bool allowNumberRemark;
  final bool allowImage;
  final bool useTextField;

  String get uniqueId => id;

  const InspectionItem({
    required this.id,
    required this.title,
    this.options,
    this.allowRemarks = false,
    this.allowNumberRemark = false,
    this.allowImage = true,
    this.useTextField = false,
  }) : assert(
          (options != null && !useTextField) ||
              (useTextField) || // Allow useTextField or no options
              (options == null),
          'Either options or useTextField must be provided, but not both',
        );

  // Factory method for future enhancements if needed
  factory InspectionItem.create({
    required String id,
    required String title,
    List<DropdownOption<T>>? options,
    bool allowRemarks = false,
    bool allowNumberRemark = false,
    bool allowImage = true,
    bool useTextField = false,
  }) {
    if (options != null && options.isEmpty) {
      throw ArgumentError('If options is provided, it cannot be empty');
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
