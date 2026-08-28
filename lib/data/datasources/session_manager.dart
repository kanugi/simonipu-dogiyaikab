import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class SessionManager {
  static const String defaultBaseUrl = 'https://simoni-pu.dogiyaikab.go.id';
  static const String localBaseUrl = 'https://simoni-pu.khel.my.id';

  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyToken = 'bearer_token';
  static const String _keyUser = 'user_json';
  static const String _keyBaseUrl = 'environment_base_url';

  Future<void> saveSession({
    required String token,
    required UserModel user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    final token = prefs.getString(_keyToken);
    return loggedIn && token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_keyUser);
    if (userStr != null && userStr.isNotEmpty) {
      try {
        final Map<String, dynamic> json = jsonDecode(userStr);
        return UserModel.fromJson(json);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl) ?? defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, url);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
