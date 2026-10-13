/// Model untuk satu item foto (url + info caption)
class FotoItem {
  final String url;
  final String info;

  FotoItem({required this.url, required this.info});

  factory FotoItem.fromJson(Map<String, dynamic> json) {
    return FotoItem(
      url: FotoKendali.sanitizeUrl(json['url'] as String? ?? ''),
      info: json['info'] as String? ?? '',
    );
  }
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? (double.tryParse(value)?.toInt() ?? 0);
  return 0;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Model untuk satu entri riwayat kendali beserta daftar fotonya
class FotoKendali {
  final int kendaliId;
  final String clientUuid;
  final int proyekid;
  final String keterangan;
  final String status;
  final double majufreal;
  final double majukeuangan;
  final String syncStatus; // pending_sync, syncing, synced, failed_validation
  final String? syncError;
  final String? foto1LocalPath;
  final String? foto2LocalPath;

  /// Daftar foto dinamis (foto1, foto2, ...) yang diparse dari map `foto` di JSON
  final List<FotoItem> fotoItems;

  FotoKendali({
    required this.kendaliId,
    this.clientUuid = '',
    this.proyekid = 0,
    required this.keterangan,
    required this.status,
    this.majufreal = 0.0,
    this.majukeuangan = 0.0,
    this.syncStatus = 'synced',
    this.syncError,
    this.foto1LocalPath,
    this.foto2LocalPath,
    required this.fotoItems,
  });

  factory FotoKendali.fromJson(Map<String, dynamic> json) {
    final List<FotoItem> items = [];

    final rawFoto = json['foto'];
    if (rawFoto is Map<String, dynamic>) {
      // Parse secara dinamis semua key fotoN yang tersedia (foto1, foto2, dst)
      final sortedKeys = rawFoto.keys.toList()..sort();
      for (final key in sortedKeys) {
        final fotoData = rawFoto[key];
        if (fotoData is Map<String, dynamic>) {
          final item = FotoItem.fromJson(fotoData);
          if (item.url.isNotEmpty) {
            items.add(item);
          }
        }
      }
    } else if (rawFoto is List) {
      for (final fotoData in rawFoto) {
        if (fotoData is Map<String, dynamic>) {
          final item = FotoItem.fromJson(fotoData);
          if (item.url.isNotEmpty) {
            items.add(item);
          }
        }
      }
    }

    // Fallback jika foto1/foto2 atau gambar1/gambar2 berada langsung di top-level object
    if (items.isEmpty) {
      if (json['foto1'] != null || json['gambar1'] != null) {
        final raw1 = json['foto1'] ?? json['gambar1'];
        String url1 = '';
        String info1 = json['info1']?.toString() ?? '';
        if (raw1 is Map<String, dynamic>) {
          url1 = raw1['url']?.toString() ?? '';
          if (info1.isEmpty) info1 = raw1['info']?.toString() ?? '';
        } else if (raw1 != null) {
          url1 = raw1.toString();
        }
        if (url1.isNotEmpty) {
          items.add(FotoItem(url: FotoKendali.sanitizeUrl(url1), info: info1));
        }
      }

      if (json['foto2'] != null || json['gambar2'] != null) {
        final raw2 = json['foto2'] ?? json['gambar2'];
        String url2 = '';
        String info2 = json['info2']?.toString() ?? '';
        if (raw2 is Map<String, dynamic>) {
          url2 = raw2['url']?.toString() ?? '';
          if (info2.isEmpty) info2 = raw2['info']?.toString() ?? '';
        } else if (raw2 != null) {
          url2 = raw2.toString();
        }
        if (url2.isNotEmpty) {
          items.add(FotoItem(url: FotoKendali.sanitizeUrl(url2), info: info2));
        }
      }
    }

    final rawStatus = (json['status'] ?? json['status_kendali'] ?? json['st'] ?? 'pending').toString();

    return FotoKendali(
      kendaliId: _parseInt(json['kendaliid'] ?? json['id']),
      clientUuid: json['client_uuid']?.toString() ?? '',
      proyekid: _parseInt(json['proyekid']),
      keterangan: json['keterangan']?.toString() ?? '',
      status: rawStatus,
      majufreal: _parseDouble(json['majufreal'] ?? json['progres_fisik']),
      majukeuangan: _parseDouble(json['majukeuangan'] ?? json['nilai_keuangan']),
      syncStatus: json['sync_status']?.toString() ?? 'synced',
      syncError: json['sync_error']?.toString(),
      fotoItems: items,
    );
  }

  factory FotoKendali.fromLocalMap(Map<String, dynamic> map) {
    final List<FotoItem> items = [];
    final String p1 = map['foto1_local_path']?.toString() ?? '';
    final String p2 = map['foto2_local_path']?.toString() ?? '';
    final String i1 = map['info1']?.toString() ?? '';
    final String i2 = map['info2']?.toString() ?? '';

    if (p1.isNotEmpty) {
      items.add(FotoItem(url: p1, info: i1));
    }
    if (p2.isNotEmpty) {
      items.add(FotoItem(url: p2, info: i2));
    }

    return FotoKendali(
      kendaliId: _parseInt(map['kendaliid']),
      clientUuid: map['client_uuid']?.toString() ?? '',
      proyekid: _parseInt(map['proyekid']),
      keterangan: map['keterangan']?.toString() ?? '',
      status: map['status_bisnis']?.toString() ?? map['status']?.toString() ?? 'pending',
      majufreal: _parseDouble(map['majufreal']),
      majukeuangan: _parseDouble(map['majukeuangan']),
      syncStatus: map['sync_status']?.toString() ?? 'pending_sync',
      syncError: map['sync_error']?.toString(),
      foto1LocalPath: p1,
      foto2LocalPath: p2,
      fotoItems: items,
    );
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'client_uuid': clientUuid,
      'kendaliid': kendaliId > 0 ? kendaliId : null,
      'proyekid': proyekid,
      'majufreal': majufreal,
      'majukeuangan': majukeuangan,
      'keterangan': keterangan,
      'info1': info1,
      'info2': info2,
      'foto1_local_path': foto1LocalPath ?? foto1Url,
      'foto2_local_path': foto2LocalPath ?? foto2Url,
      'sync_status': syncStatus,
      'sync_error': syncError,
      'status_bisnis': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // ── Backward-compat getters (supaya tidak perlu ubah UI untuk kasus 2 foto) ──

  /// URL foto pertama, atau string kosong jika tidak ada
  String get foto1Url => fotoItems.isNotEmpty ? fotoItems[0].url : '';

  /// Caption/info foto pertama
  String get info1 => fotoItems.isNotEmpty ? fotoItems[0].info : '';

  /// URL foto kedua, atau string kosong jika tidak ada
  String get foto2Url => fotoItems.length > 1 ? fotoItems[1].url : '';

  /// Caption/info foto kedua
  String get info2 => fotoItems.length > 1 ? fotoItems[1].info : '';

  static String sanitizeUrl(String url) {
    if (url.startsWith('//')) {
      return 'https:$url';
    } else if (url.isNotEmpty &&
        !url.startsWith('http://') &&
        !url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }
}