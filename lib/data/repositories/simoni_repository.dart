import '../datasources/database_helper.dart';
import '../models/paket_pekerjaan.dart';
import '../models/progres_lapangan.dart';

class SimoniRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<PaketPekerjaan>> getPaketList() async {
    return await _dbHelper.getAllPaket();
  }

  Future<void> addProgresLapangan(ProgresLapangan progres) async {
    await _dbHelper.insertProgresLapangan(progres);
  }

  Future<List<ProgresLapangan>> getProgresHistory(String packageId) async {
    return await _dbHelper.getProgresByPackageId(packageId);
  }

  Future<List<ProgresLapangan>> getUnsyncedQueue() async {
    return await _dbHelper.getUnsyncedProgres();
  }

  Future<int> syncAllData() async {
    return await _dbHelper.markAllAsSynced();
  }

  Future<int> getUnsyncedCount() async {
    return await _dbHelper.getUnsyncedCount();
  }

  Future<int> getPhotoCount() async {
    return await _dbHelper.getTotalPhotoCount();
  }
}
