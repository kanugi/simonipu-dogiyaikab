import 'package:flutter/material.dart';
import '../../data/datasources/session_manager.dart';

class AuthProvider extends ChangeNotifier {
  final SessionManager _sessionManager = SessionManager();

  bool _isLoggedIn = false;
  bool _isLoading = true;
  String _nip = '';
  String _name = '';
  String _jabatan = '';

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String get nip => _nip;
  String get name => _name;
  String get jabatan => _jabatan;

  AuthProvider() {
    checkSession();
  }

  Future<void> checkSession() async {
    _isLoading = true;
    notifyListeners();

    _isLoggedIn = await _sessionManager.isLoggedIn();
    if (_isLoggedIn) {
      final profile = await _sessionManager.getUserProfile();
      _nip = profile['nip']!;
      _name = profile['name']!;
      _jabatan = profile['jabatan']!;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String nipOrUsername, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate login validation & local session caching
    await Future.delayed(const Duration(milliseconds: 600));

    String name = 'Yohanes Dogomo, S.T.';
    if (nipOrUsername.trim().isNotEmpty) {
      name = nipOrUsername.contains(' ') 
          ? nipOrUsername 
          : 'Petugas PUPR ($nipOrUsername)';
    }

    await _sessionManager.saveSession(
      nip: nipOrUsername.isEmpty ? '19880412 201201 1 002' : nipOrUsername,
      name: name,
      jabatan: 'Inspektur Lapangan PUPR Dogiyai',
    );

    _nip = nipOrUsername.isEmpty ? '19880412 201201 1 002' : nipOrUsername;
    _name = name;
    _jabatan = 'Inspektur Lapangan PUPR Dogiyai';
    _isLoggedIn = true;

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _sessionManager.clearSession();
    _isLoggedIn = false;
    notifyListeners();
  }
}
