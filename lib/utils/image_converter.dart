import 'dart:convert';
import 'dart:developer';
import 'dart:io';

class ImageUtils {
  static String? encodeImageToBase64(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }

    try {
      final File imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        return null;
      }

      final List<int> imageBytes = imageFile.readAsBytesSync();
      final String base64Image = base64Encode(imageBytes);

      // Add the data URI prefix for images
      final String imageExtension = imagePath.split('.').last.toLowerCase();
      final String mimeType = 'image/$imageExtension';
      return 'data:$mimeType;base64,$base64Image';
    } catch (e) {
      log('Error encoding image: $e');
      return null;
    }
  }

  static Map<String, String> encodeFileToBase64(
      String? filePath, String fileName, String fileType) {
    if (filePath == null || filePath.isEmpty) {
      return {};
    }

    try {
      final File file = File(filePath);
      if (!file.existsSync()) {
        return {};
      }

      final List<int> fileBytes = file.readAsBytesSync();
      final String base64File = base64Encode(fileBytes);

      // Determine MIME type
      String mimeType;
      switch (fileType.toLowerCase()) {
        case 'pdf':
          mimeType = 'application/pdf';
          break;
        case 'doc':
        case 'docx':
          mimeType = 'application/msword';
          break;
        case 'xls':
        case 'xlsx':
          mimeType = 'application/vnd.ms-excel';
          break;
        case 'csv':
          mimeType = 'text/csv';
          break;
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        default:
          mimeType = 'application/octet-stream';
      }

      return {
        'attached_file': 'data:$mimeType;base64,$base64File',
        'attached_file_name': fileName,
        'attached_file_type': fileType,
      };
    } catch (e) {
      log('Error encoding file: $e');
      return {};
    }
  }
}
