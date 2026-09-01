import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/foto_kendali.dart';
import '../models/paket_pekerjaan.dart';
import '../models/user_model.dart';
import 'session_manager.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  final SessionManager _sessionManager = SessionManager();

  Future<String> _getBaseUrl() async {
    return await _sessionManager.getBaseUrl();
  }

  Future<Map<String, String>> _getHeaders({bool isJson = true}) async {
    final token = await _sessionManager.getToken();
    final Map<String, String> headers = {};
    if (isJson) {
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
    }
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// a.) POST Login [/api/v1/login]
Future<Map<String, dynamic>> login(
  String username,
  String password,
) async {
  try {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl/api/v1/login');

    // print('========== LOGIN DEBUG ==========');
    // print('Base URL : $baseUrl');
    // print('URL      : $url');
    // print('Username : $username');
    // print('=================================');

    final stopwatch = Stopwatch()..start();

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'username': username,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));

    stopwatch.stop();

    // print('LOGIN RESPONSE');
    // print('Duration    : ${stopwatch.elapsedMilliseconds} ms');
    // print('Status Code : ${response.statusCode}');
    // print('Body        : ${response.body}');

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      final data = body['data'];

      final String token = data['token'];
      final UserModel user = UserModel.fromJson(data['user']);

      // print('LOGIN SUCCESS');
      // print('Token exists: ${token.isNotEmpty}');
      // print('User       : ${user.username}');

      await _sessionManager.saveSession(
        token: token,
        user: user,
      );

      return {
        'token': token,
        'user': user,
        'message': body['message'] ?? 'Login berhasil',
      };
    } else {
      final errorMsg = body['message'] ??
          body['errors'] ??
          'Gagal login. Periksa username dan password Anda.';

      // print('LOGIN FAILED');
      // print('Message: $errorMsg');

      throw ApiException(
        errorMsg.toString(),
        statusCode: response.statusCode,
      );
    }
  } on SocketException catch (e) {
    print('LOGIN SOCKET ERROR: $e');

    throw ApiException(
      'Tidak dapat terhubung ke server API. '
      'Periksa koneksi internet atau environment URL Anda.',
    );
  } on http.ClientException catch (e) {
    print('LOGIN CLIENT ERROR: $e');

    throw ApiException(
      'Gagal berkomunikasi dengan server API.',
    );
  }
}

  /// b.) GET All Paket [/api/v1/paket]
  Future<Map<String, dynamic>> getAllPaket({
    String? search,
    String? tahun,
    int page = 1,
    int limit = 5,
    int? idRekanan,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (tahun != null && tahun.trim().isNotEmpty) {
        queryParams['tahun'] = tahun.trim();
      }
      if (idRekanan != null) {
        queryParams['id_rekanan'] = idRekanan.toString();
      }

      final url = Uri.parse('$baseUrl/api/v1/paket').replace(queryParameters: queryParams);
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'];
        final List<dynamic> paketListRaw = data['paket'] as List<dynamic>? ?? [];
        final List<PaketPekerjaan> paketList = paketListRaw.map((e) => PaketPekerjaan.fromJson(e)).toList();

        return {
          'paket': paketList,
          'total': data['total'] ?? paketList.length,
          'page': data['page'] ?? page,
          'limit': data['limit'] ?? limit,
        };
      } else {
        final errorMsg = body['message'] ?? 'Gagal mengambil data paket pekerjaan.';
        throw ApiException(errorMsg.toString(), statusCode: response.statusCode);
      }
    } on SocketException {
      throw ApiException('Koneksi internet bermasalah saat mengambil data paket.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan saat memuat paket: $e');
    }
  }

  /// c.) GET by id paket / detail paket [/api/v1/paket/{id}]
  Future<PaketPekerjaan> getPaketDetail(int id) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse('$baseUrl/api/v1/paket/$id');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        return PaketPekerjaan.fromJson(body['data']);
      } else {
        final errorMsg = body['message'] ?? 'Gagal mengambil detail paket pekerjaan.';
        throw ApiException(errorMsg.toString(), statusCode: response.statusCode);
      }
    } on SocketException {
      throw ApiException('Koneksi ke server terputus saat mengambil detail paket.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan detail paket: $e');
    }
  }

  /// d.) GET History Photos kendali Paket [/api/v1/paket/{id}/foto]
  Future<List<FotoKendali>> getPaketFotoHistory(int id) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse('$baseUrl/api/v1/paket/$id/foto');
      final headers = await _getHeaders();

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>? ?? {};
        final List<dynamic> dataList = data['foto'] as List<dynamic>? ?? [];
        return dataList
            .map((item) => FotoKendali.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        final errorMsg = body['message'] ?? 'Gagal mengambil foto riwayat kendali.';
        throw ApiException(errorMsg.toString(), statusCode: response.statusCode);
      }
    } on SocketException {
      throw ApiException('Koneksi ke server terputus saat memuat foto riwayat.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan saat memuat foto riwayat: $e');
    }
  }

  /// e.) POST Input progress [/api/v1/kendali]
  Future<Map<String, dynamic>> postInputProgress({
    required int proyekId,
    required double majufreal,
    required double majukeuangan,
    String? keterangan,
    required String foto1Path,
    String? foto2Path,
  }) async {
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse('$baseUrl/api/v1/kendali');
      final token = await _sessionManager.getToken();

      final request = http.MultipartRequest('POST', url);

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['proyekid'] = proyekId.toString();
      request.fields['majufreal'] = majufreal.toString();
      request.fields['majukeuangan'] = majukeuangan.toString();
      if (keterangan != null && keterangan.isNotEmpty) {
        request.fields['keterangan'] = keterangan;
      }

      // Add foto1 (Required)
      if (foto1Path.isNotEmpty && File(foto1Path).existsSync()) {
        request.files.add(await http.MultipartFile.fromPath('foto1', foto1Path));
      } else {
        throw ApiException('Foto 1 (wajib) belum dipilih atau file tidak ditemukan.');
      }

      // Add foto2 (Optional)
      if (foto2Path != null && foto2Path.isNotEmpty && File(foto2Path).existsSync()) {
        request.files.add(await http.MultipartFile.fromPath('foto2', foto2Path));
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      final Map<String, dynamic> body = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && body['success'] == true) {
        return {
          'message': body['message'] ?? 'Lembar kendali berhasil dikirim',
          'data': body['data'],
        };
      } else {
        final errorMsg = body['message'] ?? body['errors'] ?? 'Gagal mengirim lembar kendali progres.';
        throw ApiException(errorMsg.toString(), statusCode: response.statusCode);
      }
    } on SocketException {
      throw ApiException('Gagal terhubung ke server saat mengunggah progres.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan saat kirim progres: $e');
    }
  }
}
