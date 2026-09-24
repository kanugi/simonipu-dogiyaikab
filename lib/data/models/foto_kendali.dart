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
  final String keterangan;
  final String status;
  final double majufreal;
  final double majukeuangan;

  /// Daftar foto dinamis (foto1, foto2, ...) yang diparse dari map `foto` di JSON
  final List<FotoItem> fotoItems;

  FotoKendali({
    required this.kendaliId,
    required this.keterangan,
    required this.status,
    this.majufreal = 0.0,
    this.majukeuangan = 0.0,
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

    final rawStatus = (json['status'] ?? json['status_kendali'] ?? json['st'] ?? '').toString();

    return FotoKendali(
      kendaliId: _parseInt(json['kendaliid'] ?? json['id']),
      keterangan: json['keterangan']?.toString() ?? '',
      status: rawStatus,
      majufreal: _parseDouble(json['majufreal'] ?? json['progres_fisik']),
      majukeuangan: _parseDouble(json['majukeuangan'] ?? json['nilai_keuangan']),
      fotoItems: items,
    );
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