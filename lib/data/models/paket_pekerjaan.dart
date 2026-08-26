class PaketPekerjaan {
  final String id;
  final String packageId;
  final String packageName;
  final String bidang; // e.g. Jalan, Jembatan, Irigasi, Perumahan
  final double nilaiKontrak;
  final String lokasi;
  final String rekanan;
  final double progresFisikSaatIni;
  final bool isSynced;

  PaketPekerjaan({
    required this.id,
    required this.packageId,
    required this.packageName,
    required this.bidang,
    required this.nilaiKontrak,
    required this.lokasi,
    required this.rekanan,
    required this.progresFisikSaatIni,
    this.isSynced = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageId': packageId,
      'packageName': packageName,
      'bidang': bidang,
      'nilaiKontrak': nilaiKontrak,
      'lokasi': lokasi,
      'rekanan': rekanan,
      'progresFisikSaatIni': progresFisikSaatIni,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory PaketPekerjaan.fromMap(Map<String, dynamic> map) {
    return PaketPekerjaan(
      id: map['id'] as String,
      packageId: map['packageId'] as String,
      packageName: map['packageName'] as String,
      bidang: map['bidang'] as String,
      nilaiKontrak: (map['nilaiKontrak'] as num).toDouble(),
      lokasi: map['lokasi'] as String,
      rekanan: map['rekanan'] as String,
      progresFisikSaatIni: (map['progresFisikSaatIni'] as num).toDouble(),
      isSynced: (map['isSynced'] as int) == 1,
    );
  }

  PaketPekerjaan copyWith({
    String? id,
    String? packageId,
    String? packageName,
    String? bidang,
    double? nilaiKontrak,
    String? lokasi,
    String? rekanan,
    double? progresFisikSaatIni,
    bool? isSynced,
  }) {
    return PaketPekerjaan(
      id: id ?? this.id,
      packageId: packageId ?? this.packageId,
      packageName: packageName ?? this.packageName,
      bidang: bidang ?? this.bidang,
      nilaiKontrak: nilaiKontrak ?? this.nilaiKontrak,
      lokasi: lokasi ?? this.lokasi,
      rekanan: rekanan ?? this.rekanan,
      progresFisikSaatIni: progresFisikSaatIni ?? this.progresFisikSaatIni,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
