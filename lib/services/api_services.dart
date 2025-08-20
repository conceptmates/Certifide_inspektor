// lib/services/api_service.dart

import 'dart:convert';
import 'dart:developer';
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
  static const String baseUrl = 'https://dev.certifide.in/api';

  static final _storage = FlutterSecureStorage();

  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = 'auth/refresh';
  static const String profileEndPoint = '/auth/me';
  static const String getInspectorEndPoint = '/tokens/inspectors';
  static const String allocateTokensEndPoint = '/tokens/allocate';
  static const String sendDataEndPoint = '/inspections';
  static const String getBalanceTokensEndPoint = '/tokens/balance';
  static const String getHistoryEndPoint = '/inspections';

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
      Map<String, dynamic> inspectionData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$sendDataEndPoint'),
        headers: await _getHeaders(requiresAuth: true),
        body: json.encode(inspectionData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'Inspection data sent successfully',
        };
      } else {
        log('Error response: ${response.body}'); // Add this for
        return {
          'success': false,
          'message': _handleError(response),
        };
      }
    } catch (e) {
      log('Error sending inspection data: $e'); // Add this for debugging
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
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
