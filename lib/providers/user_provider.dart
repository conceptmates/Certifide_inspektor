import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/hive_constants.dart';
import '../data/inspection_storage_model.dart';
import '../models/user_state.dart';
import '../services/api_services.dart';

part 'user_provider.g.dart';

@Riverpod(keepAlive: true)
class UserNotifier extends _$UserNotifier {
  static const String _userDataKey = 'user_data';
  static const String _tokenKey = 'jwt_token';

  final _storage = const FlutterSecureStorage();

  @override
  UserState build() => const UserState(isLoading: true);

  Future<void> initializeAuth(BuildContext context) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final token = await _storage.read(key: _tokenKey);

      if (token != null) {
        state = state.copyWith(token: token);

        if (await _isTokenExpired(token)) {
          final refreshResult = await ApiService.refreshToken();
          if (!refreshResult['success']) {
            await clearUserData();
            state = state.copyWith(
              isLoading: false,
              error: 'Session expired',
            );
            return;
          }
        }

        if (!context.mounted) return;
        final result = await ApiService.getProfile(
          context,
          onStateReset: clearUserData,
        );
        if (result['success']) {
          final userData = result['data']['user'] as Map<String, dynamic>;
          await _storage.write(
            key: _userDataKey,
            value: json.encode(userData),
          );
          state = state.copyWith(userData: userData);
        } else {
          state = state.copyWith(error: result['message'] as String?);
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to initialize: ${e.toString()}');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadUserData() async {
    try {
      final storedData = await _storage.read(key: _userDataKey);
      if (storedData != null) {
        state = state.copyWith(
          userData: json.decode(storedData) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      // Silent failure — user data simply stays null
    }
  }

  Future<void> clearUserData() async {
    try {
      await _storage.deleteAll();

      final inspectionBox = Hive.isBoxOpen(HiveConstants.INSPECTION_BOX)
          ? Hive.box<InspectionStorageModel>(HiveConstants.INSPECTION_BOX)
          : await Hive.openBox<InspectionStorageModel>(HiveConstants.INSPECTION_BOX);
      final historyBox = Hive.isBoxOpen(HiveConstants.INSPECTION_HISTORY_BOX)
          ? Hive.box<InspectionStorageModel>(HiveConstants.INSPECTION_HISTORY_BOX)
          : await Hive.openBox<InspectionStorageModel>(HiveConstants.INSPECTION_HISTORY_BOX);
      await inspectionBox.clear();
      await historyBox.clear();
    } catch (e) {
      log('logout: failed to clear Hive boxes — $e');
    }

    state = const UserState(isLoading: false);
  }

  Future<String?> getToken() async {
    if (state.token != null) return state.token;
    final token = await _storage.read(key: _tokenKey);
    if (token != null) state = state.copyWith(token: token);
    return token;
  }

  Future<void> setUserData(
    Map<String, dynamic> data,
    String token,
  ) async {
    await _storage.write(key: _userDataKey, value: json.encode(data));
    await _storage.write(key: _tokenKey, value: token);
    state = state.copyWith(userData: data, token: token, isLoading: false);
  }

  Future<bool> _isTokenExpired(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final exp = payload['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp < now;
    } catch (_) {
      return true;
    }
  }
}
