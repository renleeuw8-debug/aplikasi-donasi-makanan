class UserModel {
  final String id;
  final String uid;
  final String nama;
  final String email;
  final String peran; // 'donatur' | 'petugas' | 'admin'
  final String? fotoProfil;
  final String? badge;
  final String? no_hp;
  final String? alamat;
  final DateTime? tanggalDaftar;
  final String status; // 'aktif' | 'nonaktif'

  UserModel({
    required this.id,
    required this.uid,
    required this.nama,
    required this.email,
    required this.peran,
    this.fotoProfil,
    this.badge,
    this.no_hp,
    this.alamat,
    this.tanggalDaftar,
    this.status = 'aktif',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      uid: json['uid'] ?? json['id']?.toString() ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      peran: json['peran'] ?? json['role'] ?? 'donatur',
      fotoProfil: json['fotoProfil'] ?? json['foto_profil'],
      badge: json['badge'],
      no_hp: json['no_hp'] ?? json['nohp'],
      alamat: json['alamat'],
      tanggalDaftar: json['tanggalDaftar'] is String
          ? DateTime.tryParse(json['tanggalDaftar'])
          : (json['tanggalDaftar'] as DateTime?),
      status: json['status'] ?? 'aktif',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'nama': nama,
    'email': email,
    'peran': peran,
    'fotoProfil': fotoProfil,
    'badge': badge,
    'no_hp': no_hp,
    'alamat': alamat,
    'tanggalDaftar': tanggalDaftar?.toIso8601String(),
    'status': status,
  };
}
