class ProgresLapangan {
  final String idLocal;
  final String packageId;
  final String packageName;
  final String bidang;
  final double progresFisik;
  final double realisasiKeuangan;
  final String catatan;
  final String? photoPath;
  final double latitude;
  final double longitude;
  final double gpsAccuracy;
  final DateTime timestamp;
  final bool isSynced;

  ProgresLapangan({
    required this.idLocal,
    required this.packageId,
    required this.packageName,
    required this.bidang,
    required this.progresFisik,
    required this.realisasiKeuangan,
    required this.catatan,
    this.photoPath,
    required this.latitude,
    required this.longitude,
    this.gpsAccuracy = 4.5,
    required this.timestamp,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'idLocal': idLocal,
      'packageId': packageId,
      'packageName': packageName,
      'bidang': bidang,
      'progresFisik': progresFisik,
      'realisasiKeuangan': realisasiKeuangan,
      'catatan': catatan,
      'photoPath': photoPath,
      'latitude': latitude,
      'longitude': longitude,
      'gpsAccuracy': gpsAccuracy,
      'timestamp': timestamp.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory ProgresLapangan.fromMap(Map<String, dynamic> map) {
    return ProgresLapangan(
      idLocal: map['idLocal'] as String,
      packageId: map['packageId'] as String,
      packageName: map['packageName'] as String,
      bidang: map['bidang'] as String,
      progresFisik: (map['progresFisik'] as num).toDouble(),
      realisasiKeuangan: (map['realisasiKeuangan'] as num).toDouble(),
      catatan: map['catatan'] as String? ?? '',
      photoPath: map['photoPath'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      gpsAccuracy: (map['gpsAccuracy'] as num?)?.toDouble() ?? 5.0,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isSynced: (map['isSynced'] as int) == 1,
    );
  }

  ProgresLapangan copyWith({
    String? idLocal,
    String? packageId,
    String? packageName,
    String? bidang,
    double? progresFisik,
    double? realisasiKeuangan,
    String? catatan,
    String? photoPath,
    double? latitude,
    double? longitude,
    double? gpsAccuracy,
    DateTime? timestamp,
    bool? isSynced,
  }) {
    return ProgresLapangan(
      idLocal: idLocal ?? this.idLocal,
      packageId: packageId ?? this.packageId,
      packageName: packageName ?? this.packageName,
      bidang: bidang ?? this.bidang,
      progresFisik: progresFisik ?? this.progresFisik,
      realisasiKeuangan: realisasiKeuangan ?? this.realisasiKeuangan,
      catatan: catatan ?? this.catatan,
      photoPath: photoPath ?? this.photoPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
