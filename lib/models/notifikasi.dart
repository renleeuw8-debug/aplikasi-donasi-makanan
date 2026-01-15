import 'package:cloud_firestore/cloud_firestore.dart';

class NotifikasiModel {
  final String idNotif;
  final String idUserTujuan;
  final String pesan;
  final String status; // 'baru' | 'dibaca'
  final Timestamp waktu;

  NotifikasiModel({
    required this.idNotif,
    required this.idUserTujuan,
    required this.pesan,
    this.status = 'baru',
    Timestamp? waktu,
  }) : waktu = waktu ?? Timestamp.now();

  factory NotifikasiModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return NotifikasiModel(
      idNotif: d['idNotif'] ?? doc.id,
      idUserTujuan: d['idUserTujuan'] ?? '',
      pesan: d['pesan'] ?? '',
      status: d['status'] ?? 'baru',
      waktu: d['waktu'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'idNotif': idNotif,
        'idUserTujuan': idUserTujuan,
        'pesan': pesan,
        'status': status,
        'waktu': waktu,
      };
}
