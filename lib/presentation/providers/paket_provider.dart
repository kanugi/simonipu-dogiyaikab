import 'package:flutter/material.dart';
import '../../data/datasources/api_service.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/models/foto_kendali.dart';
import '../../data/models/paket_pekerjaan.dart';
import '../../data/repositories/simoni_repository.dart';

class PaketProvider extends ChangeNotifier {
  final SimoniRepository _repository = SimoniRepository();

  List<PaketPekerjaan> _allPackages = [];
  List<PaketPekerjaan> _filteredPackages = [];
  final Map<int, List<FotoKendali>> _photoHistoryMap = {};

  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  String? _errorMessage;
  int _totalPackages = 0;
  int _limit = 10;
  final List<int> _limitOptions = [5, 10, 20, 50, 100];

  List<PaketPekerjaan> get packages => _filteredPackages;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  int get limit => _limit;
  List<int> get limitOptions => _limitOptions;

  // Summary Metrics
  int get totalPackages => _totalPackages > 0 ? _totalPackages : _allPackages.length;
  double get averageProgress {
    if (_allPackages.isEmpty) return 0.0;
    final total = _allPackages.fold<double>(0.0, (sum, item) => sum + item.progresFisikSaatIni);
    return total / _allPackages.length;
  }

  void clearPackages() {
    _allPackages = [];
    _filteredPackages = [];
    _totalPackages = 0;
    _errorMessage = null;
    _photoHistoryMap.clear();
    notifyListeners();
  }

  Future<void> setLimit(int newLimit) async {
    if (_limit == newLimit) return;
    _limit = newLimit;
    notifyListeners();
    await loadPackages();
  }

  Future<void> loadPackages({String? search, String? tahun, int? limit}) async {
    _isLoading = true;
    _errorMessage = null;
    if (limit != null) {
      _limit = limit;
    }
    notifyListeners();

    try {
      final isLoggedIn = await _repository.isLoggedIn();
      if (!isLoggedIn) {
        _allPackages = [];
        _filteredPackages = [];
        _totalPackages = 0;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final res = await _repository.getAllPaket(
        search: search ?? (_searchQuery.isNotEmpty ? _searchQuery : null),
        tahun: tahun,
        limit: _limit,
      );
      _allPackages = res['paket'] as List<PaketPekerjaan>;
      if (res['total'] != null) {
        _totalPackages = (res['total'] as num).toInt();
      } else {
        _totalPackages = _allPackages.length;
      }
      _applyFilter();

      // Simpan ke SQLite lokal sebagai offline cache
      if (_searchQuery.isEmpty && (tahun == null || tahun.isEmpty)) {
        DatabaseHelper().upsertPaketList(_allPackages).catchError((_) {});
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      await _loadFromLocalCache();
    } catch (e) {
      _errorMessage = 'Gagal memuat daftar paket: $e';
      await _loadFromLocalCache();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromLocalCache() async {
    try {
      final localPaket = await DatabaseHelper().getAllPaketLocal();
      if (localPaket.isNotEmpty) {
        _allPackages = localPaket;
        _totalPackages = localPaket.length;
        _applyFilter();
        debugPrint('[PaketProvider] Berhasil memuat ${localPaket.length} paket dari cache SQLite lokal.');
      }
    } catch (err) {
      debugPrint('[PaketProvider] Gagal memuat dari local cache: $err');
    }
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilter();
    notifyListeners();
  }

  void searchPackages(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filteredPackages = _allPackages.where((p) {
      final matchesCategory = _selectedCategory == 'Semua' ||
          p.bidang.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
          (_selectedCategory.toLowerCase() == 'jalan' && p.bidang.toLowerCase().contains('bina marga')) ||
          (_selectedCategory.toLowerCase() == 'jembatan' && p.bidang.toLowerCase().contains('bina marga'));

      final matchesQuery = _searchQuery.isEmpty ||
          p.namaPaket.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.packageId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.rekanan.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.lokasi ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Future<PaketPekerjaan?> getPaketDetail(int id) async {
    // 1. Cek in-memory
    final inMemory = _allPackages.where((p) => p.id == id).toList();
    PaketPekerjaan? fallbackPaket = inMemory.isNotEmpty ? inMemory.first : null;

    // 2. Cek cache SQLite lokal
    fallbackPaket ??= await DatabaseHelper().getPaketDetailLocal(id);

    try {
      final detail = await _repository.getPaketDetail(id);
      DatabaseHelper().upsertPaket(detail).catchError((_) {});
      return detail;
    } catch (e) {
      debugPrint('[PaketProvider] Offline getPaketDetail($id), fallback ke SQLite lokal: $e');
      return fallbackPaket;
    }
  }

  Future<List<FotoKendali>> getPaketFotoHistory(int id) async {
    _photoHistoryMap.remove(id);
    List<FotoKendali> serverHistory = [];
    bool isServerSuccess = false;

    try {
      serverHistory = await _repository.getPaketFotoHistory(id);
      isServerSuccess = true;
      debugPrint('[PaketProvider] Foto history server paket $id → ${serverHistory.length} item(s)');
    } catch (e) {
      debugPrint('[PaketProvider] Offline / Gagal fetch server history paket $id: $e');
    }

    // Ambil data lokal dari SQLite
    final localItems = await DatabaseHelper().getKendaliByPackageId(id);
    debugPrint('[PaketProvider] Foto history SQLite lokal paket $id → ${localItems.length} item(s)');

    if (!isServerSuccess) {
      // Jika server offline/gagal, tampilkan riwayat lokal SQLite sepenuhnya
      _photoHistoryMap[id] = localItems;
      return localItems;
    }

    final Map<String, FotoKendali> mergedMap = {};

    // 1. Masukkan data server resmi
    for (final s in serverHistory) {
      final key = s.kendaliId > 0
          ? 'kendali_${s.kendaliId}'
          : (s.clientUuid.isNotEmpty ? s.clientUuid : 'server_${s.hashCode}');
      mergedMap[key] = s;
    }

    // 2. Tambahkan HANYA data lokal yang berstatus pending atau gagal (draft antrean)
    for (final l in localItems) {
      final isDraft = l.syncStatus == 'pending_sync' || l.syncStatus == 'failed_validation';
      if (isDraft) {
        final key = l.clientUuid.isNotEmpty ? l.clientUuid : 'local_${l.hashCode}';
        mergedMap[key] = l;
      }
    }

    final mergedList = mergedMap.values.toList();

    // Urutkan: item draft pending_sync/failed_validation di paling atas, lalu kendaliId terbaru
    mergedList.sort((a, b) {
      final aPending = a.syncStatus == 'pending_sync' || a.syncStatus == 'failed_validation';
      final bPending = b.syncStatus == 'pending_sync' || b.syncStatus == 'failed_validation';
      if (aPending && !bPending) return -1;
      if (!aPending && bPending) return 1;
      return b.kendaliId.compareTo(a.kendaliId);
    });

    _photoHistoryMap[id] = mergedList;
    return mergedList;
  }

  Future<Map<String, dynamic>> postKendaliProgress({
    required int proyekId,
    required double majufreal,
    required double majukeuangan,
    String? keterangan,
    required String foto1Path,
    String? foto2Path,
    String? info1,
    String? info2,
    String? clientUuid,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.postInputProgress(
        proyekId: proyekId,
        majufreal: majufreal,
        majukeuangan: majukeuangan,
        keterangan: keterangan,
        foto1Path: foto1Path,
        foto2Path: foto2Path,
        info1: info1,
        info2: info2,
        clientUuid: clientUuid,
      );
      _photoHistoryMap.remove(proyekId);
      await loadPackages(); // Refresh packages list
      _isLoading = false;
      notifyListeners();
      return res;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = 'Gagal mengirim laporan kendali: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> putEditKendali({
    required int kendaliId,
    required double majufreal,
    required double majukeuangan,
    String? keterangan,
    String? foto1Path,
    String? foto2Path,
    String? info1,
    String? info2,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.putEditKendali(
        kendaliId: kendaliId,
        majufreal: majufreal,
        majukeuangan: majukeuangan,
        keterangan: keterangan,
        foto1Path: foto1Path,
        foto2Path: foto2Path,
        info1: info1,
        info2: info2,
      );
      _photoHistoryMap.clear();
      await loadPackages(); // Refresh packages list
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal mengedit laporan kendali: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteKendali(int kendaliId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteKendali(kendaliId);
      _photoHistoryMap.clear();
      await loadPackages(); // Refresh packages list
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal menghapus laporan kendali: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
