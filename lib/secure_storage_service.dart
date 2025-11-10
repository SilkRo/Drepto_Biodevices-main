import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';

  /// Save the authentication token and user ID.
  static Future<void> saveToken(String token, String userId) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId);
  }

  /// Retrieve the authentication token.
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Retrieve the user ID.
  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Delete the authentication token and user ID (for logout).
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
  }

  /// Delete all stored data (for logout).
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Save user data to SharedPreferences.
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    // The user data is a map, so we'll encode it to a JSON string.
    final String userJson = jsonEncode(userData);
    await prefs.setString('user_data', userJson);
  }

  /// Retrieve user data from SharedPreferences.
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString('user_data');
    if (userJson != null) {
      return jsonDecode(userJson) as Map<String, dynamic>;
    }
    return null;
  }
}