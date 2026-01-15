class LokasiDonasiModel {
  final String idLokasi;
  final String namaLokasi;
  final String deskripsi;
  final (double, double) koordinat; // (latitude, longitude)
  final String alamat;
  final String nohp;
  final String? fotolokasi;
  final String status; // 'aktif' | 'nonaktif'
  final DateTime tanggalBuat;

  LokasiDonasiModel({
    required this.idLokasi,
    required this.namaLokasi,
    required this.deskripsi,
    required this.koordinat,
    required this.alamat,
    required this.nohp,
    this.fotolokasi,
    this.status = 'aktif',
    DateTime? tanggalBuat,
  }) : tanggalBuat = tanggalBuat ?? DateTime.now();

  factory LokasiDonasiModel.fromJson(Map<String, dynamic> json) {
    return LokasiDonasiModel(
      idLokasi: json['id']?.toString() ?? '',
      namaLokasi: json['namaLokasi'] ?? json['alamat_detail'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      koordinat: (
        (json['lokasi_latitude'] as num?)?.toDouble() ?? 0.0,
        (json['lokasi_longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      alamat: json['alamat'] ?? json['alamat_detail'] ?? '',
      nohp: json['nohp'] ?? '',
      fotolokasi: json['fotolokasi'],
      status: json['status'] ?? 'aktif',
      tanggalBuat: json['tanggalBuat'] is String
          ? DateTime.tryParse(json['tanggalBuat'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'idLokasi': idLokasi,
    'namaLokasi': namaLokasi,
    'deskripsi': deskripsi,
    'koordinat': {'latitude': koordinat.$1, 'longitude': koordinat.$2},
    'alamat': alamat,
    'nohp': nohp,
    'fotolokasi': fotolokasi,
    'status': status,
    'tanggalBuat': tanggalBuat.toIso8601String(),
  };
}
