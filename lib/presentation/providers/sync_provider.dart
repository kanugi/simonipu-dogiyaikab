import 'package:flutter/material.dart';
import '../../data/models/progres_lapangan.dart';
import '../../data/repositories/simoni_repository.dart';

class SyncProvider extends ChangeNotifier {
  final SimoniRepository _repository = SimoniRepository();

  List<ProgresLapangan> _unsyncedList = [];
  bool _isSyncing = false;
  final int _dbSizeKb = 142; // Simulated DB Size
  int _photoCount = 0;

  List<ProgresLapangan> get unsyncedList => _unsyncedList;
  bool get isSyncing => _isSyncing;
  int get dbSizeKb => _dbSizeKb;
  int get photoCount => _photoCount;
  int get queueCount => _unsyncedList.length;

  SyncProvider() {
    loadSyncQueue();
  }

  Future<void> loadSyncQueue() async {
    _unsyncedList = await _repository.getUnsyncedQueue();
    _photoCount = await _repository.getPhotoCount();
    notifyListeners();
  }

  Future<int> simulateSyncData() async {
    _isSyncing = true;
    notifyListeners();

    // Simulate network delay for server sync
    await Future.delayed(const Duration(milliseconds: 1800));

    final count = await _repository.syncAllData();
    await loadSyncQueue();

    _isSyncing = false;
    notifyListeners();
    return count;
  }

  Future<void> clearPhotoCache() async {
    _photoCount = 0;
    notifyListeners();
  }
}
