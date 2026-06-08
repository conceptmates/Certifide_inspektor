// lib/services/api_service.dart

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/inspection_history_model.dart';
import '../models/inspection_stats_model.dart';
import '../models/inspection_template_model.dart';
import '../models/inspector.dart';
import '../models/pagination_data_model.dart';
import '../models/public_cars_models.dart';
import '../models/vehicle_model.dart';
import '../utils/exception_handler.dart';
import '../screens/auth/login_page.dart';

class ApiService {
  // static const String baseUrl = 'https://api.estelledarcy.com/api';
  static const String baseUrl = 'https://api.certifide.in/api';
  static const Duration _requestTimeout = Duration(seconds: 30);

  static final _storage = FlutterSecureStorage();

  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String profileEndPoint = '/auth/me';
  static const String getInspectorEndPoint = '/tokens/inspectors';
  static const String allocateTokensEndPoint = '/tokens/allocate';
  static const String sendDataEndPoint = '/inspections';
  static const String uploadImageEndPoint = '/inspection/upload-image';
  static const String getBalanceTokensEndPoint = '/tokens/balance';
  static const String getHistoryEndPoint = '/dynamic-inspections';
  static const String initialInspectionEndPoint = '/inspections/initial';
  static const String initializeInspectionEndPoint = '/inspections/initialize';
  static const String initializeDynamicInspectionEndPoint =
      '/dynamic-inspections/initialize';
  static const String getModelsEndpoint = '/admin/vehicles/models';
  static const String submitDynamicInspectionEndPoint = '/dynamic-inspections';
  static const String newCarsEndPoint = '/cars/new';
  static const String userCarsEndPoint = '/cars/old';
  static const String carFiltersEndpoint = '/cars/filters';
  static const String vehicleDetailsEndPoint = '/ulip/vehicle-details';
  static const String getDynamicMyHistoryEndPoint =
      '/dynamic-inspections/my-history';
  static const String inspectionStatsEndPoint = '/dynamic-inspections/stats';

  static Future<Map<String, dynamic>> createInitialInspection(
      Map<String, dynamic> vehicleData) async {
    try {
      if (kDebugMode) log('Creating initial inspection with data: $vehicleData');

      final response = await http.post(
        Uri.parse('$baseUrl$initialInspectionEndPoint'),
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode(vehicleData),
      ).timeout(_requestTimeout);

      log('Initial inspection response status: ${response.statusCode}');
      if (kDebugMode) log('Initial inspection response body: ${response.body}');

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

  static Future<Map<String, dynamic>> initializeInspection({
    required int vehicleBrandId,
    required int vehicleModelId,
    String? year,
    String? variant,
    String? colour,
    String? transmission,
  }) async {
    try {
      log('Initializing inspection for brand_id: $vehicleBrandId, model_id: $vehicleModelId');

      final body = <String, dynamic>{
        'vehicle_brand_id': vehicleBrandId,
        'vehicle_model_id': vehicleModelId,
        if (year != null && year.isNotEmpty) 'year': year,
        if (variant != null && variant.isNotEmpty) 'variant': variant,
        if (colour != null && colour.isNotEmpty) 'color': colour,
        if (transmission != null && transmission.isNotEmpty)
          'transmission': transmission,
      };

      final response = await http.post(
        Uri.parse('$baseUrl$initializeDynamicInspectionEndPoint'),
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode(body),
      ).timeout(_requestTimeout);

      log('Initialize inspection response status: ${response.statusCode}');
      if (kDebugMode) log('Initialize inspection response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          final data = responseData['data'];

          // Parse the inspection template structure
          InspectionInitializationResponse? inspectionResponse;
          try {
            inspectionResponse =
                InspectionInitializationResponse.fromJson(data);
          } catch (e) {
            log('Error parsing inspection template: $e');
          }

          log('Inspection initialized successfully');

          return {
            'success': true,
            'data': inspectionResponse ?? data,
            'inspection_id': data['inspection_id'] ?? data['inspectionId'] ?? data['id'],
            'message': responseData['message'] ??
                'Inspection initialized successfully',
          };
        } else {
          return {
            'success': false,
            'message':
                responseData['message'] ?? 'Failed to initialize inspection',
          };
        }
      } else {
        return {
          'success': false,
          'message': _handleError(response),
        };
      }
    } catch (e) {
      log('Error initializing inspection: $e');
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

  static Future<void> handleUnauthorizedResponse(
    BuildContext context, {
    VoidCallback? onStateReset,
  }) async {
    await _storage.deleteAll();
    onStateReset?.call();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
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
          if (newToken == null) {
            await _storage.deleteAll();
            throw UnauthorizedException('Token missing after refresh');
          }
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
      try {
        final user = json.decode(userData);
        return user['id']?.toString();
      } catch (e) {
        log('getUserId: malformed user_data in storage — $e');
      }
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
      ).timeout(_requestTimeout);

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
      ).timeout(_requestTimeout);

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

      // Build headers manually — do NOT call _getHeaders(requiresAuth: true) here.
      // _getHeaders checks expiry and calls refreshToken() again, causing infinite recursion.
      // The refresh endpoint needs the current (possibly expired) token to identify the session.
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $currentToken',
      };

      final response = await http.post(
        Uri.parse('$baseUrl$refreshTokenEndpoint'),
        headers: headers,
      ).timeout(_requestTimeout);

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
      ).timeout(_requestTimeout);

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

  static Future<Map<String, dynamic>> getProfile(
    BuildContext context, {
    VoidCallback? onStateReset,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$profileEndPoint'),
        headers: await _getHeaders(requiresAuth: true),
      ).timeout(_requestTimeout);

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
        await handleUnauthorizedResponse(context, onStateReset: onStateReset);
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
      await handleUnauthorizedResponse(context, onStateReset: onStateReset);
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
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        final rawData = responseData['data'];
        if (responseData['status'] == 'success' && rawData is List) {
          List<Inspector> inspectors = rawData
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
      ).timeout(_requestTimeout);

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
      if (kDebugMode) log('Inspection data: $inspectionData');

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode(inspectionData),
      ).timeout(_requestTimeout);

      log('Inspection submission response status: ${response.statusCode}');
      if (kDebugMode) log('Inspection submission response body: ${response.body}');

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
        if (kDebugMode) log('Error response: ${response.body}');
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
    String fieldName = 'image',
  }) async {
    try {
      log('Uploading media ($fieldName) to: $baseUrl$uploadImageEndPoint');
      log('Section: $section, ItemId: $itemId');

      final file = File(imagePath);
      if (!await file.exists()) {
        log('File does not exist: $imagePath');
        return {
          'success': false,
          'message': 'File not found',
        };
      }

      final bytes = await file.readAsBytes();
      final fileName = imagePath.split('/').last;

      log('File name: $fileName, size: ${bytes.length} bytes');

      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required',
        };
      }

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

      final newToken = await _storage.read(key: 'jwt_token');
      if (newToken == null) {
        return {'success': false, 'message': 'Session expired. Please login again.'};
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$uploadImageEndPoint'),
      );

      request.headers['Authorization'] = 'Bearer $newToken';
      request.headers['Accept'] = 'application/json';

      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: fileName,
        ),
      );

      request.fields['section'] = section;
      request.fields['itemId'] = itemId;

      if (inspectionId != null) {
        request.fields['inspection_id'] = inspectionId.toString();
        log('Adding inspection_id to request: ${inspectionId.toString()}');
      }

      log('Upload request fields: section=$section, itemId=$itemId, inspectionId=$inspectionId');

      final response = await request.send();

      final responseBody = await response.stream.bytesToString();
      log('Upload response status: ${response.statusCode}');
      log('Upload response body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(responseBody);

        // Server returns imagePath for all media types on this endpoint
        final mediaPath = responseData['imagePath'] ??
            responseData['videoPath'] ??
            responseData['audioPath'] ??
            responseData['filePath'];

        if (responseData['status'] == 'success' && mediaPath != null) {
          final String? url = mediaPath is Map
              ? mediaPath['url']?.toString()
              : mediaPath?.toString();
          final String? path = mediaPath is Map
              ? mediaPath['path']?.toString()
              : null;
          log('Upload successful. URL: $url');
          return {
            'success': true,
            'url': url,
            'path': path,
            'message': responseData['message'] ?? 'Uploaded successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to upload',
          };
        }
      } else if (response.statusCode == 401) {
        final refreshResult = await refreshToken();
        if (!refreshResult['success']) {
          await _storage.deleteAll();
          return {'success': false, 'message': 'Session expired. Please login again.'};
        }
        return {'success': false, 'message': 'Authentication refreshed — please retry upload.'};
      } else {
        log('Error response: $responseBody');
        return {
          'success': false,
          'message': _handleErrorFromString(responseBody, response.statusCode),
        };
      }
    } catch (e) {
      log('Error uploading media: $e');
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
      ).timeout(_requestTimeout);

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
        Uri.parse('$baseUrl$getHistoryEndPoint?page=$page'),
        headers: await _getHeaders(requiresAuth: true),
      ).timeout(_requestTimeout);
      log('getInspectionHistory status: ${response.statusCode}');
      log('getInspectionHistory body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final data = responseData['data'];
          final rawList = data['inspections'] ?? data['data'] ?? [];
          if (rawList is! List) {
            return {'success': false, 'message': 'Unexpected response shape'};
          }
          final inspections = rawList
              .map((item) => InspectionHistory.fromJson(item))
              .toList();
          final pagination = data['pagination'] != null
              ? PaginationData.fromJson(data['pagination'])
              : PaginationData(
                  currentPage: data['current_page'] ?? 1,
                  lastPage: data['last_page'] ?? 1,
                  perPage: data['per_page'] ?? 10,
                  total: data['total'] ?? 0,
                );

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
    } on UnauthorizedException {
      await handleUnauthorizedResponse(context);
      return {
        'success': false,
        'message': 'Session expired. Please login again.',
      };
    } catch (e) {
      log('getInspectionHistory error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getDynamicInspectionMyHistory(
      BuildContext context,
      {int page = 1}) async {
    final url = '$baseUrl$getDynamicMyHistoryEndPoint?page=$page';
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: await _getHeaders(requiresAuth: true),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          final data = responseData['data'];
          final rawList = data['inspections'] ?? data['data'] ?? [];
          if (rawList is! List) {
            return {'success': false, 'message': 'Unexpected response shape'};
          }
          final inspections = rawList
              .map((item) => InspectionHistory.fromJson(item))
              .toList();
          final pagination = data['pagination'] != null
              ? PaginationData.fromJson(data['pagination'])
              : PaginationData(
                  currentPage: data['current_page'] ?? 1,
                  lastPage: data['last_page'] ?? 1,
                  perPage: data['per_page'] ?? 10,
                  total: data['total'] ?? 0,
                );

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
    } on UnauthorizedException {
      await handleUnauthorizedResponse(context);
      return {
        'success': false,
        'message': 'Session expired. Please login again.',
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
      ).timeout(_requestTimeout);

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

  static Future<Map<String, dynamic>> submitInspection(
      Map<String, dynamic> body) async {
    try {
      log('Submitting dynamic inspection to: $baseUrl$submitDynamicInspectionEndPoint');
      if (kDebugMode) log('Submission body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl$submitDynamicInspectionEndPoint'),
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode(body),
      ).timeout(_requestTimeout);

      log('Submit inspection response status: ${response.statusCode}');
      if (kDebugMode) log('Submit inspection response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> responseData;
        try {
          responseData = Map<String, dynamic>.from(
              json.decode(response.body) as Map<dynamic, dynamic>);
        } catch (parseError) {
          log('Error parsing submit response JSON: $parseError');
          return {
            'success': false,
            'message':
                'Invalid response from server (${response.statusCode}). Check logs.',
          };
        }

        // Accept multiple response shapes from backend
        Map<String, dynamic>? data =
            responseData['data'] as Map<String, dynamic>?;
        final bool hasWrappedData = (responseData['status'] == 'success' ||
                responseData['success'] == true) &&
            data != null;
        final bool hasRootData = data == null &&
            (responseData['inspection_id'] != null ||
                responseData['redirect_url'] != null);
        if (hasRootData) {
          data = {
            'inspection_id': responseData['inspection_id'],
            'redirect_url': responseData['redirect_url'] ?? '',
            'uuid': responseData['uuid'] ?? '',
          };
        }

        if (hasWrappedData || hasRootData) {
          return {
            'success': true,
            'data': data ?? responseData,
            'message':
                responseData['message'] ?? 'Inspection created successfully',
          };
        }

        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to submit inspection',
        };
      } else {
        return {
          'success': false,
          'message': _handleError(response),
        };
      }
    } on UnauthorizedException {
      rethrow;
    } catch (e) {
      log('Error submitting inspection: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getModels() async {
    try {
      log('Fetching vehicle models from: $baseUrl$getModelsEndpoint');

      final response = await http.get(
        Uri.parse('$baseUrl$getModelsEndpoint'),
        headers: await _getHeaders(requiresAuth: true),
      ).timeout(_requestTimeout);

      log('Get models response status: ${response.statusCode}');
      log('Get models response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        dynamic responseData;

        // Try to parse the response
        try {
          responseData = json.decode(responseBody);
        } catch (e) {
          log('Error parsing JSON: $e');
          return {
            'success': false,
            'message': 'Invalid response format',
          };
        }

        // Handle both wrapped and unwrapped responses
        List<dynamic> dataList;
        if (responseData is List) {
          // Direct array response
          dataList = responseData;
        } else if (responseData is Map<String, dynamic>) {
          // Wrapped response with status/data
          if (responseData['status'] == 'success' &&
              responseData['data'] != null) {
            dataList = responseData['data'] as List;
          } else {
            return {
              'success': false,
              'message': responseData['message'] ?? 'Failed to fetch models',
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Unexpected response format',
          };
        }

        // Parse models
        List<VehicleModel> models = [];
        for (var item in dataList) {
          try {
            if (item is Map<String, dynamic> || item is Map<dynamic, dynamic>) {
              models.add(VehicleModel.fromJson(item));
            }
          } catch (e) {
            log('Error parsing model item: $e');
            // Continue with other items
          }
        }

        if (models.isEmpty) {
          return {
            'success': false,
            'message': 'No models found',
          };
        }

        // Extract unique brands from the models
        List<VehicleBrand> brands = [];
        final brandMap = <int, VehicleBrand>{};

        for (var model in models) {
          if (!brandMap.containsKey(model.brand.id)) {
            brandMap[model.brand.id] = model.brand;
            brands.add(model.brand);
          }
        }

        // Sort brands alphabetically
        brands.sort((a, b) => a.name.compareTo(b.name));

        log('Fetched ${models.length} models and ${brands.length} brands');

        return {
          'success': true,
          'data': models,
          'brands': brands,
          'message': 'Models retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'message': _handleError(response),
        };
      }
    } catch (e) {
      log('Error fetching models: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Public metadata for filter UIs (`type`: `new` | `old`).
  static Future<Map<String, dynamic>> getCarFilters({String? type}) async {
    try {
      final params = <String, String>{};
      if (type != null && type.isNotEmpty) {
        params['type'] = type;
      }
      final uri = Uri.parse('$baseUrl$carFiltersEndpoint')
          .replace(queryParameters: params.isEmpty ? null : params);

      log('GET car filters: $uri');

      final response = await http.get(
        uri,
        headers: await _getHeaders(requiresAuth: false),
      ).timeout(_requestTimeout);

      log('Car filters status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        final data = CarFiltersData.fromJson(responseData);
        return {
          'success': true,
          'data': data,
          'message': 'OK',
        };
      }

      return {
        'success': false,
        'message': _handleError(response),
      };
    } catch (e) {
      log('Error fetching car filters: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Paginated published new car listings (`GET /api/cars/new`).
  static Future<Map<String, dynamic>> getNewCars({
    int page = 1,
    int perPage = 15,
    String sort = 'newest',
    int? brandId,
    int? vehicleModelId,
    int? categoryId,
    String? priceMin,
    String? priceMax,
    int? yearMin,
    int? yearMax,
    String? transmission,
    String? fuelType,
    String? bodyType,
    int? seatingCapacity,
    int? engineCapacityMin,
    int? engineCapacityMax,
    String? search,
  }) async {
    try {
      final q = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
        'sort': sort,
      };

      void add(String key, Object? value) {
        if (value == null) return;
        final s = value.toString();
        if (s.isEmpty) return;
        q[key] = s;
      }

      add('brand_id', brandId);
      add('vehicle_model_id', vehicleModelId);
      add('category_id', categoryId);
      add('price_min', priceMin);
      add('price_max', priceMax);
      add('year_min', yearMin);
      add('year_max', yearMax);
      add('transmission', transmission);
      add('fuel_type', fuelType);
      add('body_type', bodyType);
      add('seating_capacity', seatingCapacity);
      add('engine_capacity_min', engineCapacityMin);
      add('engine_capacity_max', engineCapacityMax);
      add('search', search);

      final uri =
          Uri.parse('$baseUrl$newCarsEndPoint').replace(queryParameters: q);

      log('GET new cars: $uri');

      final response = await http.get(
        uri,
        headers: await _getHeaders(requiresAuth: false),
      ).timeout(_requestTimeout);

      log('New cars status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        final result = NewCarsResult.fromJson(responseData);
        return {
          'success': true,
          'cars': result.cars,
          'meta': result.meta,
          'message': 'OK',
        };
      }

      return {
        'success': false,
        'message': _handleError(response),
      };
    } catch (e) {
      log('Error fetching new cars: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Paginated published used car listings (`GET /api/cars/old`).
  /// Same query contract as [getNewCars].
  static Future<Map<String, dynamic>> getUsedCars({
    int page = 1,
    int perPage = 15,
    String sort = 'newest',
    int? brandId,
    int? vehicleModelId,
    int? categoryId,
    String? priceMin,
    String? priceMax,
    int? yearMin,
    int? yearMax,
    String? transmission,
    String? fuelType,
    String? bodyType,
    int? seatingCapacity,
    int? engineCapacityMin,
    int? engineCapacityMax,
    String? search,
  }) async {
    try {
      final q = <String, String>{
        'page': '$page',
        'per_page': '$perPage',
        'sort': sort,
      };

      void add(String key, Object? value) {
        if (value == null) return;
        final s = value.toString();
        if (s.isEmpty) return;
        q[key] = s;
      }

      add('brand_id', brandId);
      add('vehicle_model_id', vehicleModelId);
      add('category_id', categoryId);
      add('price_min', priceMin);
      add('price_max', priceMax);
      add('year_min', yearMin);
      add('year_max', yearMax);
      add('transmission', transmission);
      add('fuel_type', fuelType);
      add('body_type', bodyType);
      add('seating_capacity', seatingCapacity);
      add('engine_capacity_min', engineCapacityMin);
      add('engine_capacity_max', engineCapacityMax);
      add('search', search);

      final uri =
          Uri.parse('$baseUrl$userCarsEndPoint').replace(queryParameters: q);

      log('GET used cars: $uri');

      final response = await http.get(
        uri,
        headers: await _getHeaders(requiresAuth: false),
      ).timeout(_requestTimeout);

      log('Used cars status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        final result = NewCarsResult.fromJson(responseData);
        return {
          'success': true,
          'cars': result.cars,
          'meta': result.meta,
          'message': 'OK',
        };
      }

      return {
        'success': false,
        'message': _handleError(response),
      };
    } catch (e) {
      log('Error fetching used cars: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getInspectionStats({
    String period = 'daily',
    String? from,
    String? to,
    String? status,
    int? userId,
  }) async {
    try {
      final params = <String, String>{'period': period};
      if (from != null) params['from'] = from;
      if (to != null) params['to'] = to;
      if (status != null) params['status'] = status;
      if (userId != null) params['user_id'] = userId.toString();

      final uri = Uri.parse('$baseUrl$inspectionStatsEndPoint')
          .replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: await _getHeaders(requiresAuth: true),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final responseData =
            json.decode(response.body) as Map<String, dynamic>;
        if (responseData['status'] == 'success') {
          return {
            'success': true,
            'data': InspectionStats.fromJson(responseData),
          };
        }
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'Unauthorized'};
      }

      return {'success': false, 'message': _handleError(response)};
    } catch (e) {
      log('getInspectionStats error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getVehicleDetails({
    required String vehicleNumber,
  }) async {
    try {
      log('Fetching vehicle details for: $vehicleNumber');

      final response = await http.post(
        Uri.parse('$baseUrl$vehicleDetailsEndPoint'),
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode({
          'vehiclenumber': vehicleNumber,
        }),
      ).timeout(_requestTimeout);

      log('Vehicle details response status: ${response.statusCode}');
      log('Vehicle details response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          log('Vehicle details fetched successfully for: $vehicleNumber');

          return {
            'success': true,
            'data': responseData['data'],
            'message': responseData['message'] ??
                'Vehicle details fetched successfully',
          };
        } else {
          return {
            'success': false,
            'message':
                responseData['message'] ?? 'Failed to fetch vehicle details',
          };
        }
      } else {
        return {
          'success': false,
          'message': _handleError(response),
        };
      }
    } catch (e) {
      log('Error fetching vehicle details: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
