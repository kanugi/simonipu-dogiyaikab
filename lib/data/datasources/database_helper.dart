import '../models/paket_pekerjaan.dart';
import '../models/progres_lapangan.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<List<PaketPekerjaan>> getAllPaket() async {
    return [];
  }

  Future<void> updatePaketProgres(String packageId, double newProgres, bool isSynced) async {}

  Future<void> insertProgresLapangan(ProgresLapangan progres) async {}

  Future<List<ProgresLapangan>> getProgresByPackageId(String packageId) async {
    return [];
  }

  Future<List<ProgresLapangan>> getUnsyncedProgres() async {
    return [];
  }

  Future<int> markAllAsSynced() async {
    return 0;
  }

  Future<int> getUnsyncedCount() async {
    return 0;
  }

  Future<int> getTotalPhotoCount() async {
    return 0;
  }
}
