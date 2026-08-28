import '../datasources/api_service.dart';
import '../datasources/session_manager.dart';
import '../models/foto_kendali.dart';
import '../models/paket_pekerjaan.dart';
import '../models/user_model.dart';

class SimoniRepository {
  final ApiService _apiService = ApiService();
  final SessionManager _sessionManager = SessionManager();

  Future<Map<String, dynamic>> login(String username, String password) async {
    return await _apiService.login(username, password);
  }

  Future<Map<String, dynamic>> getAllPaket({
    String? search,
    String? tahun,
    int page = 1,
    int limit = 5,
    int? idRekanan,
  }) async {
    return await _apiService.getAllPaket(
      search: search,
      tahun: tahun,
      page: page,
      limit: limit,
      idRekanan: idRekanan,
    );
  }

  Future<PaketPekerjaan> getPaketDetail(int id) async {
    return await _apiService.getPaketDetail(id);
  }

  Future<List<FotoKendali>> getPaketFotoHistory(int id) async {
    return await _apiService.getPaketFotoHistory(id);
  }

  Future<Map<String, dynamic>> postInputProgress({
    required int proyekId,
    required double majufreal,
    required double majukeuangan,
    String? keterangan,
    required String foto1Path,
    String? foto2Path,
  }) async {
    return await _apiService.postInputProgress(
      proyekId: proyekId,
      majufreal: majufreal,
      majukeuangan: majukeuangan,
      keterangan: keterangan,
      foto1Path: foto1Path,
      foto2Path: foto2Path,
    );
  }

  Future<bool> isLoggedIn() async {
    return await _sessionManager.isLoggedIn();
  }

  Future<UserModel?> getUser() async {
    return await _sessionManager.getUser();
  }

  Future<String> getBaseUrl() async {
    return await _sessionManager.getBaseUrl();
  }

  Future<void> setBaseUrl(String url) async {
    await _sessionManager.setBaseUrl(url);
  }

  Future<void> logout() async {
    await _sessionManager.clearSession();
  }
}
