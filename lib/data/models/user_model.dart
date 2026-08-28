class UserModel {
  final int id;
  final String nama;
  final String username;
  final int status;
  final String source;
  final int idRekanan;
  final bool canWrite;
  final bool canVerify;

  UserModel({
    required this.id,
    required this.nama,
    required this.username,
    required this.status,
    required this.source,
    required this.idRekanan,
    required this.canWrite,
    required this.canVerify,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      nama: json['nama'] as String? ?? '',
      username: json['username'] as String? ?? '',
      status: json['status'] as int? ?? 0,
      source: json['source'] as String? ?? 'user',
      idRekanan: json['id_rekanan'] as int? ?? 0,
      canWrite: json['can_write'] as bool? ?? false,
      canVerify: json['can_verify'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'username': username,
      'status': status,
      'source': source,
      'id_rekanan': idRekanan,
      'can_write': canWrite,
      'can_verify': canVerify,
    };
  }
}
