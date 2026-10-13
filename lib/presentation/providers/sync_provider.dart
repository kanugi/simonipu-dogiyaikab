import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/image_storage_helper.dart';
import '../../data/datasources/api_service.dart';
import '../../data/datasources/database_helper.dart';

class SyncProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ApiService _apiService = ApiService();

  bool _isSyncing = false;
  int _unsyncedCount = 0;
  String? _lastErrorMessage;
  String? _lastSyncTime;

  bool get isSyncing => _isSyncing;
  int get queueCount => _unsyncedCount;
  String? get lastErrorMessage => _lastErrorMessage;
  String? get lastSyncTime => _lastSyncTime;

  SyncProvider() {
    loadSyncQueue();
  }

  /// Memuat status antrian sync dari SQLite lokal
  Future<void> loadSyncQueue() async {
    _unsyncedCount = await _dbHelper.getUnsyncedCount();
    final prefs = await SharedPreferences.getInstance();
    _lastSyncTime = prefs.getString('last_sync_at');
    notifyListeners();
  }

  /// Menyimpan entri lembar kendali baru secara OFFLINE (Local-First)
  Future<String> saveKendaliOffline({
    required int proyekid,
    required double majufreal,
    required double majukeuangan,
    required String keterangan,
    required String info1,
    required String info2,
    String? foto1Path,
    String? foto2Path,
  }) async {
    final clientUuid = const Uuid().v4();

    // 1. Simpan file foto dari temp/picker ke direktori permanen aplikasi
    final savedFoto1 = foto1Path != null && foto1Path.isNotEmpty
        ? await ImageStorageHelper.saveImageToAppStorage(foto1Path, prefix: 'k1_$proyekid')
        : '';
    final savedFoto2 = foto2Path != null && foto2Path.isNotEmpty
        ? await ImageStorageHelper.saveImageToAppStorage(foto2Path, prefix: 'k2_$proyekid')
        : '';

    // 2. Insert ke SQLite Lokal
    await _dbHelper.insertKendali({
      'client_uuid': clientUuid,
      'kendaliid': null,
      'proyekid': proyekid,
      'majufreal': majufreal,
      'majukeuangan': majukeuangan,
      'keterangan': keterangan,
      'info1': info1,
      'info2': info2,
      'foto1_local_path': savedFoto1,
      'foto2_local_path': savedFoto2,
      'sync_status': 'pending_sync',
      'status_bisnis': 'pending',
    });

    await loadSyncQueue();

    // 3. Otomatis pemicu sinkronisasi di background jika ada koneksi
    performBiDirectionalSync();

    return clientUuid;
  }

  /// Eksekusi Sinkronisasi 2-Arah (PUSH & PULL) ke Backend PHP
  Future<bool> performBiDirectionalSync() async {
    if (_isSyncing) return false;

    _isSyncing = true;
    _lastErrorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? lastSyncAt = prefs.getString('last_sync_at');

      // A. Ambil item lokal yang belum di-sync
      final pendingRows = await _dbHelper.getUnsyncedProgres();

      List<Map<String, dynamic>> changes = [];
      for (final row in pendingRows) {
        final f1Local = row['foto1_local_path']?.toString() ?? '';
        final f2Local = row['foto2_local_path']?.toString() ?? '';

        final f1Base64 = await ImageStorageHelper.fileToDataUriBase64(f1Local);
        final f2Base64 = await ImageStorageHelper.fileToDataUriBase64(f2Local);

        changes.add({
          'action': 'INSERT',
          'client_uuid': row['client_uuid'],
          'proyekid': row['proyekid'],
          'majufreal': row['majufreal'],
          'majukeuangan': row['majukeuangan'],
          'keterangan': row['keterangan'],
          'info1': row['info1'],
          'info2': row['info2'],
          'foto1_base64': f1Base64,
          'foto2_base64': f2Base64,
        });
      }

      // B. Panggil API Sync Backend
      final syncData = await _apiService.syncBiDirectional(
        lastSyncAt: lastSyncAt,
        changes: changes,
      );

      // C. Olah Hasil PUSH (sync_results)
      final List syncResults = syncData['sync_results'] ?? [];
      for (final res in syncResults) {
        final String clientUuid = res['client_uuid']?.toString() ?? '';
        final String statusSync = res['status_sync']?.toString() ?? '';
        final int kendaliId = res['kendaliid'] is num ? (res['kendaliid'] as num).toInt() : 0;
        final String statusBisnis = res['status_bisnis']?.toString() ?? 'pending';

        if (statusSync == 'SUCCESS' || statusSync == 'SKIPPED_DUPLICATE') {
          await _dbHelper.markAsSynced(
            clientUuid: clientUuid,
            kendaliId: kendaliId,
            statusBisnis: statusBisnis,
          );
        } else if (statusSync == 'FAILED_VALIDATION') {
          final String errorMsg = res['error']?.toString() ?? 'Gagal validasi server';
          await _dbHelper.markAsFailed(
            clientUuid: clientUuid,
            errorMsg: errorMsg,
          );
        }
      }

      // D. Olah Hasil PULL (server_changes)
      final Map<String, dynamic> serverChanges = syncData['server_changes'] ?? {};
      final List updatedItems = serverChanges['updated'] ?? [];
      for (final item in updatedItems) {
        if (item is Map<String, dynamic>) {
          await _dbHelper.upsertFromServer(item);
        }
      }

      final List deletedIds = serverChanges['deleted_ids'] ?? [];
      for (final id in deletedIds) {
        if (id is num) {
          await _dbHelper.deleteByKendaliId(id.toInt());
        }
      }

      // E. Simpan server_time baru sebagai last_sync_at
      final String? serverTime = syncData['server_time']?.toString();
      if (serverTime != null && serverTime.isNotEmpty) {
        await prefs.setString('last_sync_at', serverTime);
        _lastSyncTime = serverTime;
      }

      await loadSyncQueue();
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('SyncProvider error: $e');
      _lastErrorMessage = e.toString();
      _isSyncing = false;
      await loadSyncQueue();
      notifyListeners();
      return false;
    }
  }

  /// Alias untuk compatibility UI lama
  Future<int> simulateSyncData() async {
    final success = await performBiDirectionalSync();
    return success ? 1 : 0;
  }
}

