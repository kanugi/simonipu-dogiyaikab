import 'package:flutter/material.dart';
import '../../data/models/paket_pekerjaan.dart';
import '../../data/models/progres_lapangan.dart';
import '../../data/repositories/simoni_repository.dart';

class PaketProvider extends ChangeNotifier {
  final SimoniRepository _repository = SimoniRepository();

  List<PaketPekerjaan> _allPackages = [];
  List<PaketPekerjaan> _filteredPackages = [];
  final Map<String, List<ProgresLapangan>> _historyMap = {};

  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  List<PaketPekerjaan> get packages => _filteredPackages;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  // Summary Metrics
  int get totalPackages => _allPackages.length;
  int get unsyncedCount => _allPackages.where((p) => !p.isSynced).length;
  double get averageProgress {
    if (_allPackages.isEmpty) return 0.0;
    final total = _allPackages.fold<double>(0.0, (sum, item) => sum + item.progresFisikSaatIni);
    return total / _allPackages.length;
  }

  PaketProvider() {
    loadPackages();
  }

  Future<void> loadPackages() async {
    _isLoading = true;
    notifyListeners();

    _allPackages = await _repository.getPaketList();
    _applyFilter();

    _isLoading = false;
    notifyListeners();
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
          p.bidang.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesQuery = _searchQuery.isEmpty ||
          p.packageName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.packageId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.lokasi.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Future<List<ProgresLapangan>> getHistory(String packageId) async {
    final history = await _repository.getProgresHistory(packageId);
    _historyMap[packageId] = history;
    return history;
  }

  Future<bool> addProgres(ProgresLapangan progres) async {
    _isLoading = true;
    notifyListeners();

    await _repository.addProgresLapangan(progres);
    await loadPackages(); // Refresh packages & status

    _isLoading = false;
    notifyListeners();
    return true;
  }
}
