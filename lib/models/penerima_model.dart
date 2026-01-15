import 'package:cloud_firestore/cloud_firestore.dart';

class PenerimaModel {
  final String id; // Document ID dari Firestore
  final String userId; // UID dari Firebase Auth
  final String nama;
  final String email;
  final String alamat;
  final GeoPoint lokasi; // Latitude & Longitude
  final List<String> kebutuhan; // Kategori kebutuhan: 'makanan', 'pakaian', 'alat_rumah', dll
  final DateTime tanggalDaftar;
  final String? foto; // URL foto profil (optional)
  final String kontak; // Nomor telepon/WhatsApp
  final String status; // 'aktif', 'tidak_aktif', 'terverifikasi'
  final int totalDonasiDiterima; // Counter total donasi
  final DateTime? tanggalVerifikasi; // Kapan di-verify oleh admin

  PenerimaModel({
    required this.id,
    required this.userId,
    required this.nama,
    required this.email,
    required this.alamat,
    required this.lokasi,
    required this.kebutuhan,
    required this.tanggalDaftar,
    this.foto,
    required this.kontak,
    this.status = 'aktif',
    this.totalDonasiDiterima = 0,
    this.tanggalVerifikasi,
  });

  /// Convert PenerimaModel to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nama': nama,
      'email': email,
      'alamat': alamat,
      'lokasi': lokasi,
      'kebutuhan': kebutuhan,
      'tanggal_daftar': Timestamp.fromDate(tanggalDaftar),
      'foto': foto,
      'kontak': kontak,
      'status': status,
      'total_donasi_diterima': totalDonasiDiterima,
      'tanggal_verifikasi': tanggalVerifikasi != null 
          ? Timestamp.fromDate(tanggalVerifikasi!) 
          : null,
    };
  }

  /// Create PenerimaModel from Firestore document
  factory PenerimaModel.fromJson(Map<String, dynamic> json, String docId) {
    return PenerimaModel(
      id: docId,
      userId: json['userId'] ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      alamat: json['alamat'] ?? '',
      lokasi: json['lokasi'] as GeoPoint? ?? const GeoPoint(0, 0),
      kebutuhan: List<String>.from(json['kebutuhan'] as List? ?? []),
      tanggalDaftar: (json['tanggal_daftar'] as Timestamp?)?.toDate() ?? DateTime.now(),
      foto: json['foto'],
      kontak: json['kontak'] ?? '',
      status: json['status'] ?? 'aktif',
      totalDonasiDiterima: json['total_donasi_diterima'] ?? 0,
      tanggalVerifikasi: (json['tanggal_verifikasi'] as Timestamp?)?.toDate(),
    );
  }

  /// Create from Firestore DocumentSnapshot
  factory PenerimaModel.fromSnapshot(DocumentSnapshot snapshot) {
    return PenerimaModel.fromJson(
      snapshot.data() as Map<String, dynamic>,
      snapshot.id,
    );
  }

  /// Copy with modified fields
  PenerimaModel copyWith({
    String? id,
    String? userId,
    String? nama,
    String? email,
    String? alamat,
    GeoPoint? lokasi,
    List<String>? kebutuhan,
    DateTime? tanggalDaftar,
    String? foto,
    String? kontak,
    String? status,
    int? totalDonasiDiterima,
    DateTime? tanggalVerifikasi,
  }) {
    return PenerimaModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      alamat: alamat ?? this.alamat,
      lokasi: lokasi ?? this.lokasi,
      kebutuhan: kebutuhan ?? this.kebutuhan,
      tanggalDaftar: tanggalDaftar ?? this.tanggalDaftar,
      foto: foto ?? this.foto,
      kontak: kontak ?? this.kontak,
      status: status ?? this.status,
      totalDonasiDiterima: totalDonasiDiterima ?? this.totalDonasiDiterima,
      tanggalVerifikasi: tanggalVerifikasi ?? this.tanggalVerifikasi,
    );
  }

  @override
  String toString() {
    return 'PenerimaModel(id: $id, nama: $nama, status: $status, lokasi: ${lokasi.latitude}, ${lokasi.longitude})';
  }
}
