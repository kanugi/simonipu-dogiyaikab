import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyNip = 'user_nip';
  static const String _keyName = 'user_name';
  static const String _keyJabatan = 'user_jabatan';

  Future<void> saveSession({
    required String nip,
    required String name,
    required String jabatan,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyNip, nip);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyJabatan, jabatan);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<Map<String, String>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'nip': prefs.getString(_keyNip) ?? '19880412 201201 1 002',
      'name': prefs.getString(_keyName) ?? 'Yohanes Dogomo, S.T.',
      'jabatan': prefs.getString(_keyJabatan) ?? 'Inspektur Lapangan PUPR Dogiyai',
    };
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
