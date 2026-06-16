import 'dart:developer';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/drop_down.dart';
import 'inspection_field_info_sheet.dart';

class CustomInspectionItem<T> extends StatefulWidget {
  final String title;
  final T currentValue;
  final List<DropdownOption<T>>? dropdownOptions;
  final Function(T) onValueChanged;
  final bool allowImage;
  final String? imagePath;
  final Function(String?)? onImageChanged;
  final bool allowRemarks;
  final TextEditingController remarksController;
  final bool useTextField;
  final TextEditingController? textFieldController;
  final Function()? onDataChanged;
  final VoidCallback? onDispose;
  final bool allowFileAttachment;
  final bool allowMultiImage;
  final List<String>? multiImagePaths;
  final Function(List<String>?)? onMultiImageChanged;
  final String? placeholderText;
  final String? fieldId;
  final bool showInfoButton;

  const CustomInspectionItem({
    super.key,
    required this.title,
    required this.currentValue,
    this.dropdownOptions,
    required this.onValueChanged,
    this.allowImage = true,
    this.imagePath,
    this.onImageChanged,
    this.allowRemarks = false,
    required this.remarksController,
    this.useTextField = false,
    this.textFieldController,
    this.onDataChanged,
    this.onDispose,
    this.allowFileAttachment = false,
    this.allowMultiImage = false,
    this.multiImagePaths,
    this.onMultiImageChanged,
    this.placeholderText,
    this.fieldId,
    this.showInfoButton = false,
  });

  @override
  State<CustomInspectionItem<T>> createState() =>
      _CustomInspectionItemState<T>();
}

class _CustomInspectionItemState<T> extends State<CustomInspectionItem<T>> {
  bool _showRemarks = false;
  late TextEditingController _textFieldController;
  VoidCallback? _remarksListener;
  bool _isImagePickerActive = false;

  @override
  void initState() {
    super.initState();
    _textFieldController =
        widget.textFieldController ?? TextEditingController();

    if (widget.useTextField) {
      if (widget.currentValue is String) {
        _textFieldController.text = widget.currentValue as String;
      }
      _textFieldController.addListener(_onTextFieldChanged);
    }

    _remarksListener = () {
      widget.onDataChanged?.call();
    };
    widget.remarksController.addListener(_remarksListener!);
  }

  void _onTextFieldChanged() {
    if (widget.useTextField && mounted) {
      widget.onValueChanged(_textFieldController.text as T);
      widget.onDataChanged?.call();
    }
  }

  @override
  void didUpdateWidget(CustomInspectionItem<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.useTextField && widget.currentValue is String) {
      if (_textFieldController.text != widget.currentValue) {
        _textFieldController.text = widget.currentValue as String;
      }
    }

    if (oldWidget.remarksController != widget.remarksController) {
      oldWidget.remarksController.removeListener(_remarksListener!);
      widget.remarksController.addListener(_remarksListener!);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    // Prevent multiple simultaneous image picker calls
    if (_isImagePickerActive) return;

    if (!widget.allowImage || widget.onImageChanged == null) return;

    try {
      final hasPermission = await _ensureMediaPermission(
        source == ImageSource.camera ? Permission.camera : Permission.photos,
        source == ImageSource.camera ? 'Camera' : 'Gallery',
      );
      if (!hasPermission) return;

      // Set flag to prevent multiple calls
      _isImagePickerActive = true;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (image != null && mounted) {
        widget.onImageChanged!(image.path);
        widget.onDataChanged?.call();
      }
    } on PlatformException catch (e) {
      // Handle platform-specific exceptions
      log('Platform Exception in image picker: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Handle any other unexpected errors
      log('Unexpected error in image picker: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Reset the flag
      _isImagePickerActive = false;
    }
  }

  Future<void> _pickFile() async {
    if (!widget.allowFileAttachment || widget.onImageChanged == null) return;

    try {
      final hasPermission = await _ensureMediaPermission(
        Permission.photos,
        'File upload',
      );
      if (!hasPermission) return;

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'jpg',
          'jpeg',
          'png',
          'csv',
        ],
      );

      if (result != null && mounted) {
        final file = result.files.single;
        if (file.path != null) {
          final fileInfo = {
            'filePath': file.path!,
            'fileName': file.name,
            'fileType': file.extension?.toLowerCase() ?? '',
          };

          final fileInfoJson = json.encode(fileInfo);

          widget.onImageChanged!(fileInfoJson);
          widget.onDataChanged?.call();
        }
      }
    } catch (e) {
      log('Error picking file: $e');
    }
  }

  Future<bool> _ensureMediaPermission(
    Permission permission,
    String permissionName,
  ) async {
    if (!Platform.isIOS) return true;

    var status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      _showPermissionSnackBar(permissionName, openSettings: true);
      return false;
    }

    status = await permission.request();
    if (status.isGranted || status.isLimited) return true;

    _showPermissionSnackBar(
      permissionName,
      openSettings: status.isPermanentlyDenied || status.isRestricted,
    );
    return false;
  }

  void _showPermissionSnackBar(String permissionName,
      {bool openSettings = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$permissionName permission is required to continue.'),
        action: openSettings
            ? SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              )
            : null,
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context) {
    if (_isImagePickerActive) return;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file, color: Colors.blue),
                title: const Text('Upload Document'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilePreview() {
    try {
      final fileInfo = json.decode(widget.imagePath!);
      final fileName = fileInfo['fileName'] ?? 'Unknown file';

      return SizedBox(
        height: 48,
        width: 48,
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _showFilePreview(context, fileInfo),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.insert_drive_file, size: 20),
                      Text(
                        fileName.split('.').last.toUpperCase(),
                        style: const TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  if (mounted) {
                    widget.onImageChanged!(null);
                    widget.onDataChanged?.call();
                  }
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      log('Error building file preview: $e');
      return const SizedBox();
    }
  }

  Future<void> _openFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        log('Error opening file: ${result.message}');
      }
    } catch (e) {
      log('Error opening file: $e');
    }
  }

  void _showFilePreview(BuildContext context, Map<String, dynamic> fileInfo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        fileInfo['fileName'] ?? 'Document',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open File'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openFile(fileInfo['filePath']);
                  },
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Change File'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showFilePickerOptions(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImagePreview(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showImagePickerOptions(context);
                      },
                    ),
                  ],
                ),
                Flexible(
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickMultiImages() async {
    // Prevent multiple simultaneous image picker calls
    if (_isImagePickerActive) return;

    if (!widget.allowMultiImage || widget.onMultiImageChanged == null) return;

    // Check if already at max images
    if (widget.multiImagePaths != null &&
        widget.multiImagePaths!.length >= 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum of 11 images already added'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Set flag to prevent multiple calls
      _isImagePickerActive = true;

      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(imageQuality: 100);

      if (images.isNotEmpty && mounted) {
        // Calculate remaining slots
        final currentImageCount = widget.multiImagePaths?.length ?? 0;
        final remainingSlots = 11 - currentImageCount;

        // Limit images to remaining slots or 11 total
        final imagesToAdd = images.take(remainingSlots);

        if (imagesToAdd.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum of 11 images already added'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Convert to paths
        final List<String> imagePaths =
            imagesToAdd.map((image) => image.path).toList();

        // Combine existing images with new images
        final updatedImagePaths = [
          if (widget.multiImagePaths != null) ...widget.multiImagePaths!,
          ...imagePaths
        ];

        // Ensure we don't exceed 11 images
        final finalImagePaths = updatedImagePaths.take(11).toList();

        // Show warning if more images were selected than allowed
        if (images.length > imagesToAdd.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Only ${imagesToAdd.length} images added. Maximum is 11.'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        widget.onMultiImageChanged!(finalImagePaths);
        widget.onDataChanged?.call();
      }
    } on PlatformException catch (e) {
      // Handle platform-specific exceptions
      log('Platform Exception in image picker: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick images: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Handle any other unexpected errors
      log('Unexpected error in image picker: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Reset the flag
      _isImagePickerActive = false;
    }
  }

  Widget _buildMultiImagePreview() {
    if (widget.multiImagePaths == null || widget.multiImagePaths!.isEmpty) {
      return IconButton(
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        icon: const Icon(
          Icons.add_photo_alternate,
          color: Colors.blue,
          size: 22,
        ),
        onPressed: _pickMultiImages,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 350.0;

        return Container(
          margin: const EdgeInsets.only(top: 8),
          height: 150,
          width: width,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              direction: Axis.vertical,
              children: [
                ...widget.multiImagePaths!.map((imagePath) {
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _showImagePreview(context, imagePath),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: ResizeImage(FileImage(File(imagePath)),
                                  width: 150),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            final updatedPaths =
                                List<String>.from(widget.multiImagePaths!)
                                  ..remove(imagePath);
                            widget.onMultiImageChanged!(
                                updatedPaths.isEmpty ? null : updatedPaths);
                            widget.onDataChanged?.call();
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cancel,
                              size: 18,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                // Only show add button if less than 11 images
                if (widget.multiImagePaths!.length < 11)
                  GestureDetector(
                    onTap: _pickMultiImages,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_photo_alternate,
                          color: Colors.blue,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withAlpha(51),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).textTheme.titleMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.useTextField)
                  Expanded(
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 156, maxWidth: 195),
                      child: TextField(
                        controller: _textFieldController,
                        maxLines: null,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[850]
                                  : Colors.grey[50],
                          hintText: widget.placeholderText,
                          hintStyle: TextStyle(
                            color: Theme.of(context).hintColor.withAlpha(153),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  Theme.of(context).dividerColor.withAlpha(128),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                  )
                else if (widget.dropdownOptions != null)
                  Expanded(
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 120, maxWidth: 150),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[850]
                            : Colors.grey[50],
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withAlpha(128),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<T>(
                        isExpanded: true,
                        value: widget.dropdownOptions?.any(
                                  (option) =>
                                      option.value == widget.currentValue,
                                ) ==
                                true
                            ? widget.currentValue
                            : null,
                        underline: Container(),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        items: widget.dropdownOptions
                                ?.map((option) => DropdownMenuItem<T>(
                                      value: option.value,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (option.icon != null) ...[
                                            Icon(
                                              option.icon,
                                              size: 18,
                                              color: option.color,
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Flexible(
                                            child: Text(
                                              option.label,
                                              style: TextStyle(
                                                color: option.color,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList() ??
                            [],
                        onChanged: (T? newValue) {
                          if (newValue != null && mounted) {
                            widget.onValueChanged(newValue);
                            widget.onDataChanged?.call();
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.allowRemarks) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: widget.remarksController.text.isNotEmpty
                          ? Colors.green.withAlpha(25)
                          : Theme.of(context).primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _showRemarks
                            ? Icons.comment
                            : widget.remarksController.text.isNotEmpty
                                ? Icons.comment
                                : Icons.add_comment,
                        color: widget.remarksController.text.isNotEmpty
                            ? Colors.green
                            : Theme.of(context).primaryColor,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _showRemarks = !_showRemarks;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (widget.allowMultiImage) _buildMultiImagePreview(),
                if (widget.allowFileAttachment)
                  if (widget.imagePath == null)
                    IconButton(
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.attach_file,
                        color: Colors.blue,
                        size: 22,
                      ),
                      onPressed: () => _showFilePickerOptions(context),
                    )
                  else
                    _buildFilePreview()
                else if (widget.allowImage)
                  if (widget.imagePath == null)
                    IconButton(
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.add_a_photo,
                        color: Colors.blue,
                        size: 22,
                      ),
                      onPressed: () => _showImagePickerOptions(context),
                    )
                  else
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () =>
                                  _showImagePreview(context, widget.imagePath!),
                              child: Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.file(
                                        File(widget.imagePath!),
                                        height: 40,
                                        width: 40,
                                        fit: BoxFit.cover,
                                        cacheWidth: 80,
                                        gaplessPlayback: true,
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withAlpha(25),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Icon(
                                          Icons.zoom_in,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                if (mounted) {
                                  widget.onImageChanged!(null);
                                  widget.onDataChanged?.call();
                                }
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.cancel,
                                  size: 18,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
            if (widget.allowRemarks && _showRemarks) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[850]
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withAlpha(128),
                  ),
                ),
                child: TextField(
                  controller: widget.remarksController,
                  decoration: InputDecoration(
                    hintText: '✍️ Add remarks...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    if (mounted) {
                      widget.onDataChanged?.call();
                    }
                  },
                ),
              ),
            ],
            // Info button at bottom left corner
            if (widget.showInfoButton && widget.fieldId != null)
              Align(
                alignment: Alignment.centerLeft,
                child: InspectionInfoButton(
                  fieldId: widget.fieldId!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (widget.useTextField) {
      _textFieldController.removeListener(_onTextFieldChanged);
    }
    if (_remarksListener != null) {
      widget.remarksController.removeListener(_remarksListener!);
    }

    if (widget.textFieldController == null) {
      _textFieldController.dispose();
    }

    widget.onDispose?.call();

    super.dispose();
  }
}
