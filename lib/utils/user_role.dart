import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserRole {
  static const String ADMIN = 'admin';
  static const String INSPECTOR = 'inspector';

  // Create a single instance of FlutterSecureStorage
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<bool> isAdmin() async {
    try {
      final userData = await _storage.read(key: 'user_data');
      if (userData != null) {
        final Map<String, dynamic> user = json.decode(userData);

        // Check if roles exists and is a List
        if (user.containsKey('roles') && user['roles'] is List) {
          final roles = List<Map<String, dynamic>>.from(user['roles']);
          return roles.any(
            (role) => role.containsKey('name') && role['name'] == ADMIN,
          );
        }
      }
      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  static Future<List<String>> getUserRoles() async {
    try {
      final userData = await _storage.read(key: 'user_data');
      if (userData != null) {
        final Map<String, dynamic> user = json.decode(userData);

        // Check if roles exists and is a List
        if (user.containsKey('roles') && user['roles'] is List) {
          final roles = List<Map<String, dynamic>>.from(user['roles']);
          return roles
              .where((role) => role.containsKey('name'))
              .map((role) => role['name'].toString())
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting user roles: $e');
      return [];
    }
  }

  // Add a method to check if user has a specific role
  static Future<bool> hasRole(String roleName) async {
    try {
      final roles = await getUserRoles();
      return roles.contains(roleName);
    } catch (e) {
      print('Error checking role $roleName: $e');
      return false;
    }
  }

  // Add a method to clear user roles (useful for logout)
  static Future<void> clearRoles() async {
    try {
      await _storage.delete(key: 'user_data');
    } catch (e) {
      print('Error clearing user roles: $e');
    }
  }
}
