import 'package:cloud_firestore/cloud_firestore.dart';

class DonasiModel {
  final int? id;
  final int? userId;
  final String? nama;
  final String? kategori;
  final String? deskripsi;
  final String? fotoUrl; // URL relatif dari backend
  final int? jumlah;
  final String? satuan;
  final double? latitude;
  final double? longitude;
  final String? alamat;
  final String? status; // 'pending' | 'tersedia' | 'diambil' | 'selesai'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Legacy Firebase fields
  final String? idDonasi;
  final String? idDonatur;
  final String? namaDonasi;
  final GeoPoint? lokasi;
  final DateTime? tanggalKadaluarsa;
  final Timestamp? tanggalUpload;
  final String? idPenerima;
  final String? namaPenerima;
  final String? nohpPenerima;
  final int? ratingPenerima;

  DonasiModel({
    this.id,
    this.userId,
    this.nama,
    this.kategori,
    this.deskripsi,
    this.fotoUrl,
    this.jumlah,
    this.satuan,
    this.latitude,
    this.longitude,
    this.alamat,
    this.status,
    this.createdAt,
    this.updatedAt,
    // Legacy
    this.idDonasi,
    this.idDonatur,
    this.namaDonasi,
    this.lokasi,
    this.tanggalKadaluarsa,
    this.tanggalUpload,
    this.idPenerima,
    this.namaPenerima,
    this.nohpPenerima,
    this.ratingPenerima,
  });

  // Factory constructor untuk JSON dari backend MySQL
  factory DonasiModel.fromJson(Map<String, dynamic> json) {
    return DonasiModel(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      nama: json['nama'] as String?,
      kategori: json['kategori'] as String?,
      deskripsi: json['deskripsi'] as String?,
      fotoUrl: json['foto_donasi'] as String?,
      jumlah: json['jumlah'] as int?,
      satuan: json['satuan'] as String?,
      latitude: (json['lokasi_latitude'] as num?)?.toDouble(),
      longitude: (json['lokasi_longitude'] as num?)?.toDouble(),
      alamat: json['lokasi_alamat'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Factory untuk Firebase Firestore (legacy)
  factory DonasiModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    Timestamp? tanggalUpload;
    final tglVal = d['tanggalUpload'];
    if (tglVal is Timestamp) {
      tanggalUpload = tglVal;
    } else if (tglVal is String) {
      tanggalUpload = Timestamp.now();
    } else {
      tanggalUpload = Timestamp.now();
    }

    return DonasiModel(
      idDonasi: d['idDonasi'] ?? doc.id,
      idDonatur: d['idDonatur'] ?? '',
      namaDonasi: d['namaDonasi'] ?? '',
      kategori: d['kategori'] ?? '',
      deskripsi: d['deskripsi'],
      jumlah: (d['jumlah'] ?? 0) as int,
      lokasi: d['lokasi'] as GeoPoint?,
      status: d['status'] ?? 'pending',
      tanggalUpload: tanggalUpload,
      idPenerima: d['idPenerima'],
      namaPenerima: d['namaPenerima'],
      nohpPenerima: d['nohpPenerima'],
      ratingPenerima: (d['ratingPenerima'] as int?),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'nama': nama,
    'kategori': kategori,
    'deskripsi': deskripsi,
    'foto_donasi': fotoUrl,
    'jumlah': jumlah,
    'satuan': satuan,
    'lokasi_latitude': latitude,
    'lokasi_longitude': longitude,
    'lokasi_alamat': alamat,
    'status': status,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
