class PaketPekerjaan {
  final int id;
  final String kodePaket;
  final String namaPaket;
  final String tahunAnggaran;
  final double nilaiKontrak;
  final String rekanan;
  final String kegiatan;
  final String bidang;

  // Detail fields
  final String? tglKontrak;
  final String? batasKontrak;
  final double? biaya;
  final int? idRekanan;
  final String? namaRekanan;
  final double? long;
  final double? lat;
  final String? lokasi;
  final double? targetEfektif;
  final double? targetFungsi;
  final double realisasiFisik;
  final double realisasiKeuangan;
  final double sisaKeuangan;

  PaketPekerjaan({
    required this.id,
    required this.kodePaket,
    required this.namaPaket,
    required this.tahunAnggaran,
    required this.nilaiKontrak,
    required this.rekanan,
    required this.kegiatan,
    required this.bidang,
    this.tglKontrak,
    this.batasKontrak,
    this.biaya,
    this.idRekanan,
    this.namaRekanan,
    this.long,
    this.lat,
    this.lokasi,
    this.targetEfektif,
    this.targetFungsi,
    this.realisasiFisik = 0.0,
    this.realisasiKeuangan = 0.0,
    this.sisaKeuangan = 0.0,
  });

  // Backward compatibility getters for UI screens
  String get packageId => kodePaket.isNotEmpty ? kodePaket : 'PKT-$id';
  String get packageName => namaPaket;
  double get progresFisikSaatIni => realisasiFisik;
  bool get isSynced => true;

  factory PaketPekerjaan.fromJson(Map<String, dynamic> json) {
    return PaketPekerjaan(
      id: json['id'] as int? ?? 0,
      kodePaket: json['kode_paket'] as String? ?? '',
      namaPaket: json['nama_paket'] as String? ?? '',
      tahunAnggaran: json['tahun_anggaran']?.toString() ?? '',
      nilaiKontrak: (json['nilai_kontrak'] as num?)?.toDouble() ?? 0.0,
      rekanan: (json['rekanan'] as String?) ?? (json['nama_rekanan'] as String?) ?? '',
      kegiatan: json['kegiatan'] as String? ?? '',
      bidang: json['bidang'] as String? ?? '',
      tglKontrak: json['tgl_kontrak'] as String?,
      batasKontrak: json['batas_kontrak'] as String?,
      biaya: (json['biaya'] as num?)?.toDouble(),
      idRekanan: json['id_rekanan'] as int?,
      namaRekanan: json['nama_rekanan'] as String?,
      long: (json['long'] as num?)?.toDouble(),
      lat: (json['lat'] as num?)?.toDouble(),
      lokasi: json['lokasi'] as String? ?? 'Kab. Dogiyai',
      targetEfektif: (json['target_efektif'] as num?)?.toDouble(),
      targetFungsi: (json['target_fungsi'] as num?)?.toDouble(),
      realisasiFisik: (json['realisasi_fisik'] as num?)?.toDouble() ?? 0.0,
      realisasiKeuangan: (json['realisasi_keuangan'] as num?)?.toDouble() ?? 0.0,
      sisaKeuangan: (json['sisa_keuangan'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kode_paket': kodePaket,
      'nama_paket': namaPaket,
      'tahun_anggaran': tahunAnggaran,
      'nilai_kontrak': nilaiKontrak,
      'rekanan': rekanan,
      'kegiatan': kegiatan,
      'bidang': bidang,
      'tgl_kontrak': tglKontrak,
      'batas_kontrak': batasKontrak,
      'biaya': biaya,
      'id_rekanan': idRekanan,
      'nama_rekanan': namaRekanan,
      'long': long,
      'lat': lat,
      'lokasi': lokasi,
      'target_efektif': targetEfektif,
      'target_fungsi': targetFungsi,
      'realisasi_fisik': realisasiFisik,
      'realisasi_keuangan': realisasiKeuangan,
      'sisa_keuangan': sisaKeuangan,
    };
  }
}
