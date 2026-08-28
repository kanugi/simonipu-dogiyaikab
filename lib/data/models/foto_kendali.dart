class FotoKendali {
  final int kendaliId;
  final String keterangan;
  final String info1;
  final String info2;
  final List<String> foto;

  FotoKendali({
    required this.kendaliId,
    required this.keterangan,
    required this.info1,
    required this.info2,
    required this.foto,
  });

  factory FotoKendali.fromJson(Map<String, dynamic> json) {
    var fotoListRaw = json['foto'] as List<dynamic>? ?? [];
    List<String> parsedFoto = fotoListRaw.map((e) => e.toString()).toList();

    return FotoKendali(
      kendaliId: json['kendaliid'] as int? ?? 0,
      keterangan: json['keterangan'] as String? ?? '',
      info1: json['info1'] as String? ?? '',
      info2: json['info2'] as String? ?? '',
      foto: parsedFoto,
    );
  }

  static String sanitizeUrl(String url) {
    if (url.startsWith('//')) {
      return 'https:$url';
    } else if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }
}
