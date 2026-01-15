import '../models/donasi_model.dart';

// Marker builder untuk menampilkan data donasi
// Fungsi ini bisa digunakan untuk mapping donasi ke marker data
Map<String, dynamic> buildDonasiMarkerData(DonasiModel d) {
  return {
    'id': d.idDonasi,
    'nama': d.namaDonasi,
    'kategori': d.kategori,
    'status': d.status,
    'latitude': d.lokasi?.latitude ?? 0,
    'longitude': d.lokasi?.longitude ?? 0,
    'jumlah': d.jumlah,
    'deskripsi': d.deskripsi,
  };
}
