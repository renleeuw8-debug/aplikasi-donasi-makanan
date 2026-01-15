import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class VerifikasiDonasiPage extends StatefulWidget {
  final Map<String, dynamic> donasi;

  const VerifikasiDonasiPage({Key? key, required this.donasi})
    : super(key: key);

  @override
  State<VerifikasiDonasiPage> createState() => _VerifikasiDonasiPageState();
}

class _VerifikasiDonasiPageState extends State<VerifikasiDonasiPage> {
  final _catatanCtrl = TextEditingController();
  bool _verifying = false;
  bool _loadingPenerima = false;
  String _statusText = '';
  int? _selectedPenerimaId;
  List<Map<String, dynamic>> _penerimaList = [];

  @override
  void initState() {
    super.initState();
    _loadPenerimaList();
  }

  Future<void> _loadPenerimaList() async {
    setState(() => _loadingPenerima = true);
    try {
      final result = await ApiService.getPenerimaList();
      if (result['success'] == true) {
        setState(() {
          _penerimaList = List<Map<String, dynamic>>.from(result['data'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading penerima list: $e');
    } finally {
      setState(() => _loadingPenerima = false);
    }
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitVerification(String status) async {
    // Validasi: untuk status 'diverifikasi', penerima harus dipilih
    if (status == 'diverifikasi' && _selectedPenerimaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih penerima terlebih dahulu')),
      );
      return;
    }

    // Validasi: catatan WAJIB diisi
    if (_catatanCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan isi catatan verifikasi terlebih dahulu'),
        ),
      );
      return;
    }

    setState(() => _verifying = true);

    try {
      final result = await ApiService.updateDonasiStatus(
        donasiId: widget.donasi['id'],
        status: status,
        catatan: _catatanCtrl.text.trim(),
        penerimaId: status == 'diverifikasi' ? _selectedPenerimaId : null,
      );

      if (!mounted) return;

      if (result['success']) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'diverifikasi'
                  ? 'Donasi berhasil diverifikasi ✓'
                  : 'Donasi berhasil ditolak ✗',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${result['message']}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Donasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Donation Details Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto Donasi - Full Width, No Constraint
                  if (widget.donasi['foto_donasi'] != null &&
                      widget.donasi['foto_donasi'].toString().isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 450,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          'http://192.168.100.9:3000${widget.donasi['foto_donasi']}',
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint(
                              'Image error: $error, URL: ${widget.donasi['foto_donasi']}',
                            );
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 450,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Foto tidak tersedia',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Data: ${widget.donasi['foto_donasi'] ?? 'null'}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.donasi['nama_barang'] ?? 'Donasi',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              label: Text(widget.donasi['jenis_donasi'] ?? ''),
                              backgroundColor: Colors.blue[100],
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(
                                '${widget.donasi['jumlah']} ${widget.donasi['satuan'] ?? 'pcs'}',
                              ),
                              backgroundColor: Colors.green[100],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (widget.donasi['deskripsi'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Deskripsi:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(widget.donasi['deskripsi'] ?? '-'),
                            ],
                          ),
                        const SizedBox(height: 12),
                        const Text(
                          'Donatur:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${widget.donasi['donatur_nama'] ?? widget.donasi['donatur']?['nama'] ?? 'Unknown'}\n${widget.donasi['donatur_hp'] ?? widget.donasi['donatur']?['no_hp'] ?? '-'}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Catatan Petugas
            const Text(
              'Catatan Verifikasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _catatanCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tulis catatan verifikasi Anda...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Pilih Penerima (hanya saat verifikasi)
            const Text(
              'Pilih Penerima Donasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _loadingPenerima
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<int>(
                    value: _selectedPenerimaId,
                    decoration: InputDecoration(
                      labelText: 'Penerima',
                      hintText: 'Pilih penerima untuk donasi ini',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _penerimaList
                        .map(
                          (p) => DropdownMenuItem<int>(
                            value: p['id'],
                            child: Text(p['nama'] ?? 'Tidak diketahui'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedPenerimaId = v),
                  ),
            const SizedBox(height: 24),

            // Status Text
            if (_statusText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusText,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              ),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _verifying
                        ? null
                        : () => _submitVerification('ditolak'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _verifying
                        ? null
                        : () => _submitVerification('diverifikasi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Setujui'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
