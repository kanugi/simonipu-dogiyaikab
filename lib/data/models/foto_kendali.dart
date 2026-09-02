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
    final fotoMap = json['foto'] as Map<String, dynamic>? ?? {};

    // Parse secara dinamis semua key fotoN yang tersedia (foto1, foto2, dst)
    final List<FotoItem> items = [];
    // Urutkan key agar foto1 selalu sebelum foto2, dsb.
    final sortedKeys = fotoMap.keys.toList()..sort();
    for (final key in sortedKeys) {
      final fotoData = fotoMap[key];
      if (fotoData is Map<String, dynamic>) {
        final item = FotoItem.fromJson(fotoData);
        if (item.url.isNotEmpty) {
          items.add(item);
        }
      }
    }

    return FotoKendali(
      kendaliId: json['kendaliid'] as int? ?? json['id'] as int? ?? 0,
      keterangan: json['keterangan'] as String? ?? '',
      status: json['status'] as String? ?? '',
      majufreal: (json['majufreal'] as num?)?.toDouble() ??
          (json['progres_fisik'] as num?)?.toDouble() ??
          0.0,
      majukeuangan: (json['majukeuangan'] as num?)?.toDouble() ??
          (json['nilai_keuangan'] as num?)?.toDouble() ??
          0.0,
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