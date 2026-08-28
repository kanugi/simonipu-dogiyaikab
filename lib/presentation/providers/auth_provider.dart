import 'package:flutter/material.dart';
import '../../data/datasources/api_service.dart';
import '../../data/datasources/session_manager.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/simoni_repository.dart';

class AuthProvider extends ChangeNotifier {
  final SimoniRepository _repository = SimoniRepository();

  bool _isLoggedIn = false;
  bool _isLoading = true;
  UserModel? _user;
  String _baseUrl = SessionManager.defaultBaseUrl;
  String? _errorMessage;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  UserModel? get user => _user;
  String get baseUrl => _baseUrl;
  String? get errorMessage => _errorMessage;

  String get name => _user?.nama ?? 'Pengguna';
  String get username => _user?.username ?? '';
  int get status => _user?.status ?? 0;
  String get jabatan => _user?.source ?? '';
  // String get jabatan => _user?.source == 'user' ? 'Petugas Lapangan PUPR' : 'Admin PUPR';

  bool get isProductionEnv => _baseUrl == SessionManager.defaultBaseUrl;

  String get roleName {
    switch (status) {
      case 1: return 'Super Admin';
      case 2: return 'Admin Bidang';
      case 3: return 'User Bidang';
      case 4: return 'Surveyor';
      case 5: return 'Rekanan';
      case 6: return 'Auditor';
      default: return 'User';
    }
  }

  AuthProvider() {
    checkSession();
  }

  Future<void> checkSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      _baseUrl = await _repository.getBaseUrl();
      _isLoggedIn = await _repository.isLoggedIn();
      if (_isLoggedIn) {
        _user = await _repository.getUser();
      }
    } catch (_) {
      _isLoggedIn = false;
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.login(username, password);
      _user = result['user'] as UserModel?;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoggedIn = false;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan sistem saat login: $e';
      _isLoggedIn = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _repository.logout();
    _isLoggedIn = false;
    _user = null;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> switchEnvironment(String newBaseUrl) async {
    _isLoading = true;
    notifyListeners();

    await _repository.setBaseUrl(newBaseUrl);
    _baseUrl = newBaseUrl;
    await logout(); // Switching environment clears token & logs out
  }
}
