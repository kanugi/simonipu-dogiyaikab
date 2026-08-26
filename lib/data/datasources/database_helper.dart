import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/paket_pekerjaan.dart';
import '../models/progres_lapangan.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'simoni_pu_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create Table paket_pekerjaan
    await db.execute('''
      CREATE TABLE paket_pekerjaan (
        id TEXT PRIMARY KEY,
        packageId TEXT NOT NULL,
        packageName TEXT NOT NULL,
        bidang TEXT NOT NULL,
        nilaiKontrak REAL NOT NULL,
        lokasi TEXT NOT NULL,
        rekanan TEXT NOT NULL,
        progresFisikSaatIni REAL NOT NULL,
        isSynced INTEGER NOT NULL
      )
    ''');

    // Create Table progres_lapangan
    await db.execute('''
      CREATE TABLE progres_lapangan (
        idLocal TEXT PRIMARY KEY,
        packageId TEXT NOT NULL,
        packageName TEXT NOT NULL,
        bidang TEXT NOT NULL,
        progresFisik REAL NOT NULL,
        realisasiKeuangan REAL NOT NULL,
        catatan TEXT NOT NULL,
        photoPath TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        gpsAccuracy REAL NOT NULL,
        timestamp TEXT NOT NULL,
        isSynced INTEGER NOT NULL
      )
    ''');

    // Seed Initial Data (Kabupaten Dogiyai Projects)
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final dummyPackages = [
      PaketPekerjaan(
        id: '1',
        packageId: 'PKT-JLN-001',
        packageName: 'Peningkatan Jalan Kigamani - Mapia',
        bidang: 'Jalan',
        nilaiKontrak: 12500000000.0,
        lokasi: 'Distrik Kamu, Kab. Dogiyai',
        rekanan: 'PT Dogiyai Jaya Konstruksi',
        progresFisikSaatIni: 48.5,
        isSynced: true,
      ),
      PaketPekerjaan(
        id: '2',
        packageId: 'PKT-JMB-002',
        packageName: 'Pembangunan Jembatan Sungai Moanemani',
        bidang: 'Jembatan',
        nilaiKontrak: 4800000000.0,
        lokasi: 'Distrik Kamu Selatan, Kab. Dogiyai',
        rekanan: 'CV Papua Mandiri Sejahtera',
        progresFisikSaatIni: 65.0,
        isSynced: true,
      ),
      PaketPekerjaan(
        id: '3',
        packageId: 'PKT-IRG-003',
        packageName: 'Rehabilitasi Jaringan Irigasi Lembah Kamu',
        bidang: 'Irigasi',
        nilaiKontrak: 2350000000.0,
        lokasi: 'Distrik Kamu Utara, Kab. Dogiyai',
        rekanan: 'PT Tirta Dogiyai Utama',
        progresFisikSaatIni: 32.0,
        isSynced: true,
      ),
      PaketPekerjaan(
        id: '4',
        packageId: 'PKT-PRM-004',
        packageName: 'Penataan Kawasan Perumahan Rakyat Moanemani',
        bidang: 'Perumahan',
        nilaiKontrak: 3100000000.0,
        lokasi: 'Kota Moanemani, Kab. Dogiyai',
        rekanan: 'CV Dogiyai Permai',
        progresFisikSaatIni: 85.0,
        isSynced: true,
      ),
      PaketPekerjaan(
        id: '5',
        packageId: 'PKT-JLN-005',
        packageName: 'Preservasi Jalan Bukapa - Obano',
        bidang: 'Jalan',
        nilaiKontrak: 8750000000.0,
        lokasi: 'Distrik Mapia Barat, Kab. Dogiyai',
        rekanan: 'PT Cenderawasih Murni',
        progresFisikSaatIni: 15.0,
        isSynced: false,
      ),
    ];

    for (var pkg in dummyPackages) {
      await db.insert('paket_pekerjaan', pkg.toMap());
    }

    // Seed initial progress entry sample
    final now = DateTime.now();
    final sampleProgress = ProgresLapangan(
      idLocal: const Uuid().v4(),
      packageId: 'PKT-JLN-005',
      packageName: 'Preservasi Jalan Bukapa - Obano',
      bidang: 'Jalan',
      progresFisik: 15.0,
      realisasiKeuangan: 12.5,
      catatan: 'Pembersihan bahu jalan dan penyiapan sub-base di KM 4+200.',
      photoPath: null,
      latitude: -4.0152,
      longitude: 135.9521,
      gpsAccuracy: 3.8,
      timestamp: now.subtract(const Duration(hours: 2)),
      isSynced: false,
    );

    await db.insert('progres_lapangan', sampleProgress.toMap());
  }

  // --- CRUD Paket Pekerjaan ---
  Future<List<PaketPekerjaan>> getAllPaket() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('paket_pekerjaan');
    return List.generate(maps.length, (i) => PaketPekerjaan.fromMap(maps[i]));
  }

  Future<void> updatePaketProgres(String packageId, double newProgres, bool isSynced) async {
    final db = await database;
    await db.update(
      'paket_pekerjaan',
      {
        'progresFisikSaatIni': newProgres,
        'isSynced': isSynced ? 1 : 0,
      },
      where: 'packageId = ?',
      whereArgs: [packageId],
    );
  }

  // --- CRUD Progres Lapangan ---
  Future<void> insertProgresLapangan(ProgresLapangan progres) async {
    final db = await database;
    await db.insert('progres_lapangan', progres.toMap());

    // Auto update paket progres fisik saat ini
    await updatePaketProgres(progres.packageId, progres.progresFisik, false);
  }

  Future<List<ProgresLapangan>> getProgresByPackageId(String packageId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'progres_lapangan',
      where: 'packageId = ?',
      whereArgs: [packageId],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ProgresLapangan.fromMap(maps[i]));
  }

  Future<List<ProgresLapangan>> getUnsyncedProgres() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'progres_lapangan',
      where: 'isSynced = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ProgresLapangan.fromMap(maps[i]));
  }

  Future<int> markAllAsSynced() async {
    final db = await database;
    final count = await db.update(
      'progres_lapangan',
      {'isSynced': 1},
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    await db.update(
      'paket_pekerjaan',
      {'isSynced': 1},
    );
    return count;
  }

  Future<int> getUnsyncedCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM progres_lapangan WHERE isSynced = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalPhotoCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM progres_lapangan WHERE photoPath IS NOT NULL');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
