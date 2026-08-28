import 'package:flutter/material.dart';
import '../../data/models/progres_lapangan.dart';

class SyncProvider extends ChangeNotifier {
  final List<ProgresLapangan> _unsyncedList = [];
  bool _isSyncing = false;
  final int _dbSizeKb = 0;
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
    _photoCount = 0;
    notifyListeners();
  }

  Future<int> simulateSyncData() async {
    _isSyncing = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _isSyncing = false;
    notifyListeners();
    return 0;
  }

  Future<void> clearPhotoCache() async {
    _photoCount = 0;
    notifyListeners();
  }
}
