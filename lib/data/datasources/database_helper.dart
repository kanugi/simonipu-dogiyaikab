import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/foto_kendali.dart';

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
    final path = join(dbPath, 'simonipu_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE paketkendali_local (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_uuid TEXT UNIQUE NOT NULL,
        kendaliid INTEGER NULL,
        proyekid INTEGER NOT NULL,
        majufreal REAL NOT NULL,
        majukeuangan REAL NOT NULL,
        keterangan TEXT,
        info1 TEXT,
        info2 TEXT,
        foto1_local_path TEXT,
        foto2_local_path TEXT,
        sync_status TEXT DEFAULT 'pending_sync',
        sync_error TEXT NULL,
        status_bisnis TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  /// Insert entri lembar kendali baru ke SQLite lokal
  Future<int> insertKendali(Map<String, dynamic> row) async {
    final db = await database;
    row['created_at'] = DateTime.now().toIso8601String();
    row['updated_at'] = DateTime.now().toIso8601String();
    return await db.insert(
      'paketkendali_local',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Ambil semua entri kendali berdasarkan ID paket (proyekid)
  Future<List<FotoKendali>> getKendaliByPackageId(int proyekid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'paketkendali_local',
      where: 'proyekid = ?',
      whereArgs: [proyekid],
      orderBy: 'local_id DESC',
    );

    return maps.map((map) => FotoKendali.fromLocalMap(map)).toList();
  }

  /// Ambil semua antrian data yang belum di-sync (status = 'pending_sync')
  Future<List<Map<String, dynamic>>> getUnsyncedProgres() async {
    final db = await database;
    return await db.query(
      'paketkendali_local',
      where: 'sync_status = ? OR sync_status = ?',
      whereArgs: ['pending_sync', 'failed_validation'],
      orderBy: 'local_id ASC',
    );
  }

  /// Hitung jumlah antrian yang belum synced
  Future<int> getUnsyncedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as total FROM paketkendali_local WHERE sync_status IN ('pending_sync', 'failed_validation')"
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Mark item sebagai SYNCED setelah sukses dikirim ke server
  Future<int> markAsSynced({
    required String clientUuid,
    required int kendaliId,
    required String statusBisnis,
  }) async {
    final db = await database;
    return await db.update(
      'paketkendali_local',
      {
        'kendaliid': kendaliId,
        'sync_status': 'synced',
        'status_bisnis': statusBisnis,
        'sync_error': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'client_uuid = ?',
      whereArgs: [clientUuid],
    );
  }

  /// Mark item sebagai FAILED_VALIDATION bila ditolak server
  Future<int> markAsFailed({
    required String clientUuid,
    required String errorMsg,
  }) async {
    final db = await database;
    return await db.update(
      'paketkendali_local',
      {
        'sync_status': 'failed_validation',
        'sync_error': errorMsg,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'client_uuid = ?',
      whereArgs: [clientUuid],
    );
  }

  /// Upsert data dari server (PULL sync)
  Future<void> upsertFromServer(Map<String, dynamic> item) async {
    final db = await database;
    final String clientUuid = item['client_uuid']?.toString() ?? '';
    final int kendaliId = item['kendaliid'] is num ? (item['kendaliid'] as num).toInt() : 0;
    final int proyekId = item['proyekid'] is num ? (item['proyekid'] as num).toInt() : 0;

    // Cek apakah item sudah ada di SQLite lokal
    List<Map<String, dynamic>> existing = [];
    if (clientUuid.isNotEmpty) {
      existing = await db.query('paketkendali_local', where: 'client_uuid = ?', whereArgs: [clientUuid]);
    } else if (kendaliId > 0) {
      existing = await db.query('paketkendali_local', where: 'kendaliid = ?', whereArgs: [kendaliId]);
    }

    final Map<String, dynamic> row = {
      'client_uuid': clientUuid.isNotEmpty ? clientUuid : 'server_$kendaliId',
      'kendaliid': kendaliId,
      'proyekid': proyekId,
      'majufreal': (item['majufreal'] is num) ? (item['majufreal'] as num).toDouble() : 0.0,
      'majukeuangan': (item['majukeuangan'] is num) ? (item['majukeuangan'] as num).toDouble() : 0.0,
      'keterangan': item['keterangan']?.toString() ?? '',
      'info1': item['info1']?.toString() ?? '',
      'info2': item['info2']?.toString() ?? '',
      'foto1_local_path': item['gambar1']?.toString() ?? '',
      'foto2_local_path': item['gambar2']?.toString() ?? '',
      'sync_status': 'synced',
      'status_bisnis': item['status']?.toString() ?? 'pending',
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (existing.isNotEmpty) {
      await db.update('paketkendali_local', row, where: 'local_id = ?', whereArgs: [existing.first['local_id']]);
    } else {
      row['created_at'] = DateTime.now().toIso8601String();
      await db.insert('paketkendali_local', row);
    }
  }

  /// Hapus data berdasarkan kendaliid (soft delete sync)
  Future<int> deleteByKendaliId(int kendaliid) async {
    final db = await database;
    return await db.delete(
      'paketkendali_local',
      where: 'kendaliid = ?',
      whereArgs: [kendaliid],
    );
  }
}

