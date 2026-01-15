import 'package:cloud_firestore/cloud_firestore.dart';

class RiwayatDonasi {
  final String idRiwayat;
  final String idDonasi;
  final String idUser;
  final String tipeAksi; // 'donasi' | 'penerimaan'
  final Timestamp waktu;

  RiwayatDonasi({
    required this.idRiwayat,
    required this.idDonasi,
    required this.idUser,
    required this.tipeAksi,
    Timestamp? waktu,
  }) : waktu = waktu ?? Timestamp.now();

  factory RiwayatDonasi.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return RiwayatDonasi(
      idRiwayat: d['idRiwayat'] ?? doc.id,
      idDonasi: d['idDonasi'] ?? '',
      idUser: d['idUser'] ?? '',
      tipeAksi: d['tipeAksi'] ?? 'donasi',
      waktu: d['waktu'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'idRiwayat': idRiwayat,
        'idDonasi': idDonasi,
        'idUser': idUser,
        'tipeAksi': tipeAksi,
        'waktu': waktu,
      };
}
