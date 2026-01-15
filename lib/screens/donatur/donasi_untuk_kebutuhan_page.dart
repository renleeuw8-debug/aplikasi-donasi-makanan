import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'upload_donasi_page.dart';

class DonasiUntukKebutuhanPage extends StatefulWidget {
  final Map<String, dynamic> kebutuhan;

  const DonasiUntukKebutuhanPage({Key? key, required this.kebutuhan})
    : super(key: key);

  @override
  State<DonasiUntukKebutuhanPage> createState() =>
      _DonasiUntukKebutuhanPageState();
}

class _DonasiUntukKebutuhanPageState extends State<DonasiUntukKebutuhanPage> {
  String _getDisplayJenis(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'makanan':
        return '🍚 Makanan';
      case 'pakaian':
        return '👕 Pakaian';
      case 'buku':
        return '📚 Buku';
      case 'kesehatan':
        return '🏥 Kesehatan/Obat';
      case 'barang':
        return '📦 Barang';
      case 'lainnya':
        return '❓ Lainnya';
      default:
        return '📦 Barang';
    }
  }

  Color _getColorForJenis(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'makanan':
        return Colors.orange;
      case 'pakaian':
        return Colors.pink;
      case 'buku':
        return Colors.purple;
      case 'kesehatan':
        return Colors.red;
      case 'barang':
        return Colors.blue;
      case 'lainnya':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: color.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Detail Kebutuhan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Penerima Info
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Penerima',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.kebutuhan['penerima_nama'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Jenis Kebutuhan
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jenis Kebutuhan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        _getDisplayJenis(widget.kebutuhan['jenis_kebutuhan']),
                        style: const TextStyle(fontSize: 14),
                      ),
                      backgroundColor: _getColorForJenis(
                        widget.kebutuhan['jenis_kebutuhan'],
                      ).withOpacity(0.2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Deskripsi
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deskripsi Kebutuhan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.kebutuhan['deskripsi'] ?? '-',
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Jumlah Dibutuhkan
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jumlah Dibutuhkan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.kebutuhan['jumlah'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Call To Action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💝 Anda Ingin Membantu?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Anda bisa mendonasikan makanan atau barang yang sesuai dengan kebutuhan ini.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Donate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UploadDonasiPage(kebutuhan: widget.kebutuhan),
                    ),
                  ).then((result) {
                    if (result == true) {
                      Navigator.pop(context, true);
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.favorite, color: Colors.white),
                label: const Text(
                  'Donasikan Sekarang',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
