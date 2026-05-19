import 'dart:convert';
import 'dart:io';

import '../models/inspection_item.dart';

class InspectionDataFormatter {
  static Map<String, dynamic> formatData({
    required Map<String, String> itemValues,
    required Map<String, String?> itemImages,
    required Map<String, String> itemRemarks,
    required List<Map<String, dynamic>> sections,
    Map<String, dynamic>? additionalData,
    Map<String, List<String>?>? multiImages,
  }) {
    List<Map<String, dynamic>> formattedSections = [];
    Map<String, dynamic> summaryData = {};

    for (var section in sections) {
      List<Map<String, dynamic>> items = [];

      for (var item in section['items'] as List<InspectionItem>) {
        // Handle value
        String value = _processItemValue(item, itemValues);

        // Prepare item data
        Map<String, dynamic> itemData = {
          'id': item.uniqueId,
          'title': item.title,
          'value': value,
        };

        // Process remarks
        _addRemarksToItemData(item, itemRemarks, itemData);

        // Process attachments
        _processAttachments(item, itemImages, itemData);

        // Process multi-images for this item if available
        if (item.allowMultiImage && multiImages != null && multiImages.containsKey(item.uniqueId) && multiImages[item.uniqueId] != null) {
          _processMultiImageAttachment(multiImages[item.uniqueId]!, itemData);
        }

        items.add(itemData);
      }

      formattedSections.add({
        'sectionTitle': section['title'],
        'items': items,
      });
    }

    // Handle summary image paths if provided
    if (additionalData != null &&
        additionalData.containsKey('summaryImagePaths')) {
      Map<String, String> summaryImagePaths =
          additionalData['summaryImagePaths'];

      // Process summary image paths
      List<Map<String, dynamic>> processedSummaryImages = [];
      summaryImagePaths.forEach((key, imagePath) {
        try {
          // Check if the image path is a remote URL
          if (imagePath.startsWith('http')) {
            processedSummaryImages.add({
              'key': key,
              'imagePath': imagePath,
            });
          } else {
            // For local files, keep the path as-is
            // The images will be uploaded when submitting the inspection
            processedSummaryImages.add({
              'key': key,
              'imagePath': imagePath,
            });
          }
        } catch (e) {
          print('Error processing summary image $key: $e');
        }
      });

      // Add processed summary images to the data
      if (processedSummaryImages.isNotEmpty) {
        summaryData['summaryImages'] = processedSummaryImages;
      }
    }

    // Combine formatted data
    Map<String, dynamic> finalData = {
      'inspection_data': formattedSections,
    };

    // Add summary data if exists
    if (summaryData.isNotEmpty) {
      finalData.addAll(summaryData);
    }

    return finalData;
  }

  static String _processItemValue(
      InspectionItem item, Map<String, String> itemValues) {
    // Handle different types of item values
    if (item.useTextField) {
      return itemValues[item.uniqueId]?.trim() ?? '';
    }

    return itemValues[item.uniqueId]?.trim() ??
        item.options?.first.value.trim() ??
        '';
  }

  static void _addRemarksToItemData(InspectionItem item,
      Map<String, String> itemRemarks, Map<String, dynamic> itemData) {
    // Comprehensive remarks handling
    String? remarks = itemRemarks[item.uniqueId];

    if (remarks != null && remarks.trim().isNotEmpty) {
      itemData['remarks'] = remarks.trim();
    }
  }

  static void _processAttachments(InspectionItem item,
      Map<String, String?> itemImages, Map<String, dynamic> itemData) {
    String? attachmentPath = itemImages[item.uniqueId];

    if (attachmentPath == null || attachmentPath.isEmpty) return;

    try {
      // Handle image attachments
      if (item.allowImage) {
        _processImageAttachment(attachmentPath, itemData);
      }
      // Handle file attachments
      else if (item.allowFileAttachment) {
        _processFileAttachment(attachmentPath, itemData);
      }
    } catch (e) {
      print('Error processing attachment for ${item.uniqueId}: $e');
    }
  }

  static void _processImageAttachment(
      String imagePath, Map<String, dynamic> itemData) {
    // Check if the image path is a remote URL
    if (imagePath.startsWith('http')) {
      // Use the uploaded URL directly as imagePath
      itemData['imagePath'] = imagePath;
    } else {
      // For local files, keep the path as-is
      // The images will be uploaded when submitting the inspection
      // and the paths will be replaced with URLs
      itemData['imagePath'] = imagePath;
    }
  }

  static void _processMultiImageAttachment(
      List<String> imagePaths, Map<String, dynamic> itemData) {
    List<Map<String, dynamic>> processedImages = [];

    for (String imagePath in imagePaths) {
      if (imagePath.startsWith('http')) {
        // Use the uploaded URL directly
        processedImages.add({
          'imagePath': imagePath,
        });
      } else {
        // For local files, keep the path as-is
        // The images will be uploaded when submitting the inspection
        processedImages.add({
          'imagePath': imagePath,
        });
      }
    }

    if (processedImages.isNotEmpty) {
      itemData['multiImages'] = processedImages;
    }
  }

  static void _processFileAttachment(
      String attachmentPath, Map<String, dynamic> itemData) {
    // Parse the JSON string containing file information
    final fileInfo = json.decode(attachmentPath);

    final String filePath = fileInfo['filePath'];
    final String fileName = fileInfo['fileName'];
    final String fileType = fileInfo['fileType'];

    final File file = File(filePath);

    if (file.existsSync()) {
      final List<int> fileBytes = file.readAsBytesSync();
      final String base64File = base64Encode(fileBytes);
      final String mimeType = _getMimeType(fileType);

      // Add file data in required format
      itemData['attached_file'] = 'data:$mimeType;base64,$base64File';
      itemData['attached_file_name'] = fileName;
      itemData['attached_file_type'] = fileType;
    }
  }

  static String _getMimeType(String fileExtension) {
    switch (fileExtension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'csv':
        return 'text/csv';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}
