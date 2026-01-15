import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/donasi_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _donasiCol =>
      _db.collection('donasi');

  // NOTE: File ini hanya untuk mobile app compatibility
  // Web sudah migrate ke REST API (web_donasi_service.dart)

  Stream<List<DonasiModel>> streamDonasiTersedia({String? kategori}) {
    return _donasiCol.snapshots().map((snapshot) {
      var donasi = snapshot.docs
          .map((d) {
            try {
              final data = d.data();
              return DonasiModel.fromJson(data);
            } catch (e) {
              return null;
            }
          })
          .whereType<DonasiModel>()
          .where((d) => (d.status ?? 'pending') == 'tersedia')
          .toList();

      if (kategori != null &&
          kategori.trim().isNotEmpty &&
          kategori.toLowerCase() != 'semua') {
        donasi = donasi.where((d) => d.kategori == kategori).toList();
      }
      return donasi;
    });
  }

  Stream<List<DonasiModel>> streamDonasiByUser(String uid) {
    return _donasiCol.snapshots().map((snap) {
      final donasi = snap.docs
          .map((d) {
            try {
              return DonasiModel.fromJson(d.data());
            } catch (e) {
              return null;
            }
          })
          .whereType<DonasiModel>()
          .where((d) => d.idDonatur == uid)
          .toList();

      // Sort by tanggalUpload descending
      donasi.sort((a, b) {
        final aDate = (a.tanggalUpload ?? DateTime(2000)) as DateTime;
        final bDate = (b.tanggalUpload ?? DateTime(2000)) as DateTime;
        return bDate.compareTo(aDate);
      });
      return donasi;
    });
  }

  Future<void> updateDonasiStatus(String idDonasi, String status) async {
    try {
      await _donasiCol.doc(idDonasi).update({'status': status});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> tambahDonasi(DonasiModel donasi) async {
    try {
      final docRef = await _donasiCol.add(donasi.toJson());
      // Update dengan ID yang baru dibuat
      await docRef.update({'idDonasi': docRef.id});
    } catch (e) {
      rethrow;
    }
  }

  Future<DonasiModel?> getDonasiById(String idDonasi) async {
    try {
      final doc = await _donasiCol.doc(idDonasi).get();
      if (doc.exists) {
        return DonasiModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<DonasiModel>> getAllDonasi() async {
    try {
      final snapshot = await _donasiCol.get();
      return snapshot.docs
          .map((d) {
            try {
              return DonasiModel.fromJson(d.data());
            } catch (e) {
              return null;
            }
          })
          .whereType<DonasiModel>()
          .toList();
    } catch (e) {
      return [];
    }
  }
}
