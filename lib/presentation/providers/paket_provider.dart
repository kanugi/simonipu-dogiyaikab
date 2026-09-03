import 'package:flutter/material.dart';
import '../../data/datasources/api_service.dart';
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
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Gagal memuat daftar paket: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
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
    try {
      return await _repository.getPaketDetail(id);
    } catch (e) {
      return null;
    }
  }

  Future<List<FotoKendali>> getPaketFotoHistory(int id) async {
    try {
      final history = await _repository.getPaketFotoHistory(id);
      _photoHistoryMap[id] = history;
      return history;
    } catch (e) {
      return _photoHistoryMap[id] ?? [];
    }
  }

  Future<bool> postKendaliProgress({
    required int proyekId,
    required double majufreal,
    required double majukeuangan,
    String? keterangan,
    required String foto1Path,
    String? foto2Path,
    String? info1,
    String? info2,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.postInputProgress(
        proyekId: proyekId,
        majufreal: majufreal,
        majukeuangan: majukeuangan,
        keterangan: keterangan,
        foto1Path: foto1Path,
        foto2Path: foto2Path,
        info1: info1,
        info2: info2,
      );
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
      _errorMessage = 'Gagal mengirim laporan kendali: $e';
      _isLoading = false;
      notifyListeners();
      return false;
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
