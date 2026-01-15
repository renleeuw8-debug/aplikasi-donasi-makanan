import '../models/donasi_model.dart';
import 'firestore_service.dart' as internal;

class DonasiService {
  DonasiService._();
  static final instance = DonasiService._();

  Stream<List<DonasiModel>> streamDonasiTersedia({String? kategori}) {
    return internal.FirestoreService.instance
        .streamDonasiTersedia(kategori: kategori);
  }

  Future<void> tambahDonasi(DonasiModel donasi) {
    return internal.FirestoreService.instance.tambahDonasi(donasi);
  }
}
