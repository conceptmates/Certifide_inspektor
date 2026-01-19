// lib/services/api_service.dart

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/inspection_history_model.dart';
import '../models/inspector.dart';
import '../models/pagination_data_model.dart';
import '../utils/exception_handler.dart';
import '../screens/auth/login_page.dart';

class ApiService {
  // static const String baseUrl = 'https://reports.certifide.in/api';
  static const String baseUrl = 'https://aalekittanilla.com/api';

  static final _storage = FlutterSecureStorage();

  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = 'auth/refresh';
  static const String profileEndPoint = '/auth/me';
  static const String getInspectorEndPoint = '/tokens/inspectors';
  static const String allocateTokensEndPoint = '/tokens/allocate';
  static const String sendDataEndPoint = '/inspections';
  static const String uploadImageEndPoint = '/inspection/upload-image';
  static const String getBalanceTokensEndPoint = '/tokens/balance';
  static const String getHistoryEndPoint = '/inspections';
  static const String initialInspectionEndPoint = '/inspections/initial';

  static Future<Map<String, dynamic>> createInitialInspection(
      Map<String, dynamic> vehicleData) async {
    try {
      log('Creating initial inspection with data: $vehicleData');

      final response = await http.post(
        Uri.parse('$baseUrl$initialInspectionEndPoint'),
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode(vehicleData),
      );

      log('Initial inspection response status: ${response.statusCode}');
      log('Initial inspection response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          log('Initial inspection created successfully. ID: ${responseData['data']['inspection_id']}');

          return {
            'success': true,
            'data': responseData['data'],
            'message': responseData['message'] ??
                'Initial inspection created successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ??
                'Failed to create initial inspection',
          };
        }
      } else {
        return {
          'success': false,
          'message': _handleError(response),
        };
      }
    } catch (e) {
      log('Error creating initial inspection: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static String _handleError(http.Response response) {
    try {
      final errorData = json.decode(response.body);
      if (errorData['message'] != null) {
        return errorData['message'];
      } else if (errorData['error'] != null) {
        return errorData['error'];
      }
      return 'An error occurred (${response.statusCode})';
    } catch (e) {
      return 'An error occurred (${response.statusCode})';
    }
  }

  static Future<void> handleUnauthorizedResponse(BuildContext context) async {
    await _storage.deleteAll(); // Clear all stored data
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  static Future<Map<String, String>> _getHeaders(
      {bool requiresAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        // Check if token is expired
        if (await isTokenExpired(token)) {
          // Try to refresh token
          final refreshResult = await refreshToken();
          if (!refreshResult['success']) {
            // If refresh fails, clear storage and return to login
            await _storage.deleteAll();
            throw UnauthorizedException('Token expired');
          }
          // Get new token after refresh
          final newToken = await _storage.read(key: 'jwt_token');
          headers['Authorization'] = 'Bearer $newToken';
        } else {
          headers['Authorization'] = 'Bearer $token';
        }
      }
    }

    return headers;
  }

  static Future<String?> getUserId() async {
    final userData = await _storage.read(key: 'user_data');
    if (userData != null) {
      final user = json.decode(userData);
      return user['id'].toString();
    }
    return null;
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$loginEndpoint'),
        headers: await _getHeaders(requiresAuth: false),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null &&
            responseData['data']['access_token'] != null &&
            responseData['data']['user'] != null) {
          await _storage.write(
            key: 'jwt_token',
            value: responseData['data']['access_token'],
          );
          await _storage.write(
            key: 'user_data',
            value: json.encode(responseData['data']['user']),
          );

          // CRITICAL FIX: Convert "status":"success" to "success":true for login screen
          return {
            'success': true, // This is what login screen expects!
            'data': responseData['data'],
            'message': responseData['message'] ?? 'Login successful',
          };
        } else {
          return {
            'success': false,
            'message': 'Invalid response data structure',
          };
        }
      } else {
        return {
          'success': false,
          'message': _handleError(response),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$registerEndpoint'),
        headers: await _getHeaders(requiresAuth: false),
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Remove token storage and user data storage
        return {
          'success': true,
          'data': responseData,
          'message': responseData['message'] ?? 'Registration successful',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> refreshToken() async {
    try {
      // Get the current token
      final currentToken = await _storage.read(key: 'jwt_token');

      if (currentToken == null) {
        return {
          'success': false,
          'message': 'No token found',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl$refreshTokenEndpoint'),
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Store the new access token
        if (responseData['data'] != null &&
            responseData['data']['access_token'] != null) {
          await _storage.write(
            key: 'jwt_token',
            value: responseData['data']['access_token'],
          );

          return {
            'success': true,
            'data': responseData,
            'message': 'Token refreshed successfully',
          };
        }
      }

      return {
        'success': false,
        'message': _handleError(response),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<bool> isTokenValid() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl$profileEndPoint'),
        headers: await _getHeaders(requiresAuth: true),
      );

      return response.statusCode == 200;
    } catch (e) {
      log('Error checking token validity: $e');
      return false;
    }
  }

  static Future<bool> isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return Future.value(true);

      final payload = json
          .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload['exp'];
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      return Future.value(exp < now);
    } catch (e) {
      return Future.value(true);
    }
  }

  static Future<Map<String, dynamic>> getProfile(BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$profileEndPoint'),
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data'] != null &&
            responseData['data']['user'] != null) {
          await _storage.write(
            key: 'user_data',
            value: json.encode(responseData['data']['user']),
          );
        }
        return {
          'success': true,
          'data': responseData['data'],
          'message': 'Profile retrieved successfully',
        };
      } else if (response.statusCode == 401) {
        await handleUnauthorizedResponse(context);
        return {
          'success': false,
          'message': 'Unauthorized access',
        };
      } else {
        return {
          'success': false,
          'message': _handleError(response),
        };
      }
    } on UnauthorizedException {
      await handleUnauthorizedResponse(context);
      return {
        'success': false,
        'message': 'Session expired',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getInspectors() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$getInspectorEndPoint'),
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          List<Inspector> inspectors = (responseData['data'] as List)
              .map((inspectorData) => Inspector.fromJson(inspectorData))
              .toList();

          return {
            'success': true,
            'data': inspectors,
            'message': 'Inspectors retrieved successfully',
          };
        }
      }

      return {
        'success': false,
        'message': _handleError(response),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> allocateTokens({
    required String userId,
    required String tokens,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$allocateTokensEndPoint'),
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode({
          'user_id': userId,
          'tokens': tokens,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Tokens allocated successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Token allocation failed',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  //submit inspection

  static Future<Map<String, dynamic>> sendInspectionData(
      Map<String, dynamic> inspectionData,
      {int? inspectionId}) async {
    try {
      final endpoint = inspectionId != null
          ? '$sendDataEndPoint/$inspectionId'
          : sendDataEndPoint;

      log('Sending inspection data to: $baseUrl$endpoint');
      log('Inspection data: $inspectionData');

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode(inspectionData),
      );

      log('Inspection submission response status: ${response.statusCode}');
      log('Inspection submission response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        log('Inspection submitted successfully');

        return {
          'success': true,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'Inspection data sent successfully',
        };
      } else {
        log('Error response: ${response.body}');
        return {
          'success': false,
          'message': _handleError(response),
        };
      }
    } catch (e) {
      log('Error sending inspection data: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> uploadImage(
    String imagePath, {
    int? inspectionId,
    required String section,
    required String itemId,
  }) async {
    try {
      log('Uploading image to: $baseUrl$uploadImageEndPoint');
      log('Section: $section, ItemId: $itemId');

      // Read the image file
      final file = File(imagePath);
      if (!await file.exists()) {
        log('Image file does not exist: $imagePath');
        return {
          'success': false,
          'message': 'Image file not found',
        };
      }

      final bytes = await file.readAsBytes();
      final fileName = imagePath.split('/').last;

      log('Image file name: $fileName, size: ${bytes.length} bytes');

      // Get auth token
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

      // Check if token is expired and refresh if needed
      if (await isTokenExpired(token)) {
        final refreshResult = await refreshToken();
        if (!refreshResult['success']) {
          await _storage.deleteAll();
          return {
            'success': false,
            'message': 'Session expired. Please login again.',
          };
        }
      }

      // Get fresh token after refresh
      final newToken = await _storage.read(key: 'jwt_token');

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$uploadImageEndPoint'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $newToken';
      request.headers['Accept'] = 'application/json';

      // Add the image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: fileName,
        ),
      );

      // Add form fields
      request.fields['section'] = section;
      request.fields['itemId'] = itemId;

      // Add inspection_id if available
      if (inspectionId != null) {
        request.fields['inspection_id'] = inspectionId.toString();
        log('Adding inspection_id to request: ${inspectionId.toString()}');
      }

      // Log the full request for debugging
      log('Upload request fields: section=$section, itemId=$itemId, inspectionId=$inspectionId');
      log('Request URL: $baseUrl$uploadImageEndPoint');

      // Send the request
      final response = await request.send();

      final responseBody = await response.stream.bytesToString();
      log('Image upload response status: ${response.statusCode}');
      log('Image upload response body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(responseBody);

        if (responseData['status'] == 'success' &&
            responseData['imagePath'] != null) {
          log('Image uploaded successfully. URL: ${responseData['imagePath']['url']}');

          return {
            'success': true,
            'url': responseData['imagePath']['url'],
            'path': responseData['imagePath']['path'],
            'message': responseData['message'] ?? 'Image uploaded successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to upload image',
          };
        }
      } else {
        log('Error response: $responseBody');
        return {
          'success': false,
          'message': _handleErrorFromString(responseBody, response.statusCode),
        };
      }
    } catch (e) {
      log('Error uploading image: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static String _handleErrorFromString(String responseBody, int statusCode) {
    try {
      final errorData = json.decode(responseBody);
      if (errorData['message'] != null) {
        return errorData['message'];
      } else if (errorData['error'] != null) {
        return errorData['error'];
      }
      return 'An error occurred ($statusCode)';
    } catch (e) {
      return 'An error occurred ($statusCode)';
    }
  }

  static Future<Map<String, dynamic>> getTokenBalance(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$getBalanceTokensEndPoint'),
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          return {
            'success': true,
            'data': {
              'available_tokens': responseData['data']['available_tokens'],
              'used_tokens': responseData['data']['used_tokens'],
            },
            'message': 'Token balance retrieved successfully',
          };
        }
      }

      return {
        'success': false,
        'message': _handleError(response),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // To be used in HistoryPage and ApprovalsPage
  static Future<Map<String, dynamic>> getInspectionHistory(BuildContext context,
      {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl$getHistoryEndPoint?page=$page'), // Add page parameter
        headers: await _getHeaders(requiresAuth: true),
      );
      log('Response status: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final data = responseData['data'];
          final inspections = (data['inspections'] as List)
              .map((item) => InspectionHistory.fromJson(item))
              .toList();
          final pagination = PaginationData.fromJson(data['pagination']);

          return {
            'success': true,
            'inspections': inspections,
            'pagination': pagination,
            'message': 'History retrieved successfully',
          };
        }
      } else if (response.statusCode == 401) {
        await handleUnauthorizedResponse(context);
        return {
          'success': false,
          'message': 'Unauthorized access',
        };
      }

      return {
        'success': false,
        'message': _handleError(response),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

// In api_services.dart
  static Future<Map<String, dynamic>> approveInspection(
      String inspectionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inspections/$inspectionId/approve-api'),
        headers: await _getHeaders(requiresAuth: true),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        return {
          'status': 'error',
          'message':
              'Failed to approve inspection. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to approve inspection: ${e.toString()}',
      };
    }
  }
}
