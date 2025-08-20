import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import '../constants/hive_constants.dart';
import '../data/inspection_storage_model.dart';
import 'dart:convert';
import '../services/api_services.dart';

class UserProvider extends ChangeNotifier {
  static const String USER_DATA_KEY = 'user_data';
  static const String TOKEN_KEY = 'jwt_token';

  final _storage = FlutterSecureStorage();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;
  String? _token;

  // Getters
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _userData != null && _token != null;

  Future<void> initializeAuth(BuildContext context) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      _token = await _storage.read(key: TOKEN_KEY);

      if (_token != null) {
        if (await isTokenExpired()) {
          final refreshResult = await ApiService.refreshToken();
          if (!refreshResult['success']) {
            await clearUserData();
            _error = 'Session expired';
            notifyListeners();
            return;
          }
        }

        final result = await ApiService.getProfile(context);
        if (result['success']) {
          _userData = result['data']['user'];
          await _storage.write(
            key: USER_DATA_KEY,
            value: json.encode(_userData),
          );
        } else {
          _error = result['message'];
        }
      }
    } catch (e) {
      _error = 'Failed to initialize: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserData() async {
    try {
      final storedData = await _storage.read(key: USER_DATA_KEY);
      if (storedData != null) {
        _userData = json.decode(storedData);
      }
      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> clearUserData() async {
    try {
      await _storage.deleteAll();

      final inspectionBox = await Hive.openBox<InspectionStorageModel>(
          HiveConstants.INSPECTION_BOX);
      final historyBox = await Hive.openBox<InspectionStorageModel>(
          HiveConstants.INSPECTION_HISTORY_BOX);
      await inspectionBox.clear();
      await historyBox.clear();

      _userData = null;
      _token = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    _token = await _storage.read(key: TOKEN_KEY);
    return _token;
  }

  Future<bool> isTokenExpired() async {
    try {
      final token = await getToken();
      if (token == null) return true;

      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = json.decode(
        utf8.decode(
          base64Url.decode(
            base64Url.normalize(parts[1]),
          ),
        ),
      );

      final exp = payload['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      return exp < now;
    } catch (e) {
      print('Error checking token expiration: $e');
      return true;
    }
  }

  Future<void> setUserData(Map<String, dynamic> data, String token) async {
    if (data != null && token != null) {
      _userData = data;
      _token = token;
      await _storage.write(
        key: USER_DATA_KEY,
        value: json.encode(_userData),
      );
      await _storage.write(
        key: TOKEN_KEY,
        value: token,
      );
      notifyListeners();
    } else {
      print('Error: Invalid user data or token');
    }
  }

  bool isAdmin() {
    final roles = _userData?['roles'] as List?;
    return roles?.any((role) => role['name'] == 'admin') ?? false;
  }

  bool hasRole(String roleName) {
    final roles = _userData?['roles'] as List?;
    return roles?.any((role) => role['name'] == roleName) ?? false;
  }
}
