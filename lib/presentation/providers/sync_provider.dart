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
  List<Map<String, dynamic>> _unsyncedItems = [];
  String? _lastErrorMessage;
  String? _lastSyncTime;

  bool get isSyncing => _isSyncing;
  int get queueCount => _unsyncedCount;
  List<Map<String, dynamic>> get unsyncedItems => _unsyncedItems;
  String? get lastErrorMessage => _lastErrorMessage;
  String? get lastSyncTime => _lastSyncTime;

  SyncProvider() {
    loadSyncQueue();
  }

  /// Memuat status antrian sync dari SQLite lokal
  Future<void> loadSyncQueue() async {
    _unsyncedItems = await _dbHelper.getUnsyncedProgres();
    _unsyncedCount = _unsyncedItems.length;
    final prefs = await SharedPreferences.getInstance();
    _lastSyncTime = prefs.getString('last_sync_at');
    notifyListeners();
  }

  /// Menyimpan entri lembar kendali baru secara OFFLINE (Local-First)
  Future<String> saveKendaliOffline({
    required int proyekid,
    String? namaPaket,
    required double majufreal,
    required double majukeuangan,
    required String keterangan,
    required String info1,
    required String info2,
    String? foto1Path,
    String? foto2Path,
    String? clientUuid,
  }) async {
    final uuid = (clientUuid != null && clientUuid.isNotEmpty) ? clientUuid : const Uuid().v4();

    // 1. Simpan file foto dari temp/picker ke direktori permanen aplikasi
    final savedFoto1 = foto1Path != null && foto1Path.isNotEmpty
        ? await ImageStorageHelper.saveImageToAppStorage(foto1Path, prefix: 'k1_$proyekid')
        : '';
    final savedFoto2 = foto2Path != null && foto2Path.isNotEmpty
        ? await ImageStorageHelper.saveImageToAppStorage(foto2Path, prefix: 'k2_$proyekid')
        : '';

    // 2. Insert ke SQLite Lokal
    await _dbHelper.insertKendali({
      'client_uuid': uuid,
      'kendaliid': null,
      'proyekid': proyekid,
      'nama_paket': namaPaket ?? 'Paket #$proyekid',
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
    return uuid;
  }

  /// Hapus satu antrean draf offline
  Future<bool> deleteQueueItem(String clientUuid) async {
    try {
      await _dbHelper.deleteQueueItem(clientUuid);
      await loadSyncQueue();
      return true;
    } catch (e) {
      debugPrint('Error deleteQueueItem: $e');
      return false;
    }
  }

  /// Retry pengiriman satu item antrean spesifik
  Future<bool> retrySingleItem(String clientUuid) async {
    if (_isSyncing) return false;

    _isSyncing = true;
    _lastErrorMessage = null;
    notifyListeners();

    try {
      final rows = _unsyncedItems.where((r) => r['client_uuid'] == clientUuid).toList();
      if (rows.isEmpty) {
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      final row = rows.first;
      final f1Local = row['foto1_local_path']?.toString() ?? '';
      final f2Local = row['foto2_local_path']?.toString() ?? '';

      final f1Base64 = await ImageStorageHelper.fileToDataUriBase64(f1Local);
      final f2Base64 = await ImageStorageHelper.fileToDataUriBase64(f2Local);

      final change = {
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
      };

      final prefs = await SharedPreferences.getInstance();
      final String? lastSyncAt = prefs.getString('last_sync_at');

      final syncData = await _apiService.syncBiDirectional(
        lastSyncAt: lastSyncAt,
        changes: [change],
      );

      await _processSyncResults(syncData['sync_results'] ?? []);
      await _processServerChanges(syncData['server_changes'] ?? {});

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
      debugPrint('Error retrySingleItem ($clientUuid): $e');
      _lastErrorMessage = e.toString();
      _isSyncing = false;
      await loadSyncQueue();
      notifyListeners();
      return false;
    }
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

      // Ambil HANYA item pending_sync (item failed_validation tidak dikirim ulang otomatis)
      final pendingRows = await _dbHelper.getPendingSyncOnlyProgres();

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

      // Backend membatasi maks 10 item per sync request (safeguard chunking)
      const int batchSize = 10;
      if (changes.isNotEmpty) {
        for (int i = 0; i < changes.length; i += batchSize) {
          final end = (i + batchSize < changes.length) ? i + batchSize : changes.length;
          final batch = changes.sublist(i, end);

          final syncData = await _apiService.syncBiDirectional(
            lastSyncAt: lastSyncAt,
            changes: batch,
          );

          await _processSyncResults(syncData['sync_results'] ?? []);
          await _processServerChanges(syncData['server_changes'] ?? {});

          final String? serverTime = syncData['server_time']?.toString();
          if (serverTime != null && serverTime.isNotEmpty) {
            await prefs.setString('last_sync_at', serverTime);
            _lastSyncTime = serverTime;
          }
        }
      } else {
        // Jika tidak ada antrian PUSH, tetap lakukan PULL delta updates
        final syncData = await _apiService.syncBiDirectional(
          lastSyncAt: lastSyncAt,
          changes: [],
        );
        await _processServerChanges(syncData['server_changes'] ?? {});
        final String? serverTime = syncData['server_time']?.toString();
        if (serverTime != null && serverTime.isNotEmpty) {
          await prefs.setString('last_sync_at', serverTime);
          _lastSyncTime = serverTime;
        }
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

  Future<void> _processSyncResults(List syncResults) async {
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
  }

  Future<void> _processServerChanges(Map<String, dynamic> serverChanges) async {
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
  }

  /// Alias untuk compatibility UI lama
  Future<int> simulateSyncData() async {
    final success = await performBiDirectionalSync();
    return success ? 1 : 0;
  }
}
