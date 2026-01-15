import 'package:flutter/material.dart';
import '../../models/donasi_model.dart';
import '../../services/api_service.dart';
import '../../widgets/accept_donation_with_photo_dialog.dart';

class KonfirmasiPenerimaanPage extends StatefulWidget {
  final DonasiModel donasi;

  const KonfirmasiPenerimaanPage({super.key, required this.donasi});

  @override
  State<KonfirmasiPenerimaanPage> createState() =>
      _KonfirmasiPenerimaanPageState();
}

class _KonfirmasiPenerimaanPageState extends State<KonfirmasiPenerimaanPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _confirmReceipt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final result = await ApiService.acceptDirectDonation(
        donasiId: widget.donasi.id ?? 0,
        keterangan: _notesCtrl.text.trim(),
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penerimaan donasi berhasil dikonfirmasi'),
          ),
        );
        Navigator.of(context).pop();
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
      if (mounted) setState(() => _saving = false);
    }
  }

  // Fitur 1: Show photo dialog for donation receipt proof
  void _showPhotoDialog() {
    showDialog(
      context: context,
      builder: (context) => AcceptDonationWithPhotoDialog(
        donasiId: widget.donasi.id ?? 0,
        namaBarang: widget.donasi.namaDonasi ?? 'Donasi',
        donaturName: widget.donasi.namaPenerima ?? 'Donatur',
        onSuccess: () {
          // Refresh or navigate back
          if (mounted) {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Close confirmation page
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('✅ Konfirmasi Penerimaan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detail Donasi',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Donasi Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.donasi.namaDonasi ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Dari',
                      value: widget.donasi.namaPenerima ?? 'Unknown',
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      label: 'Kategori',
                      value: widget.donasi.kategori ?? 'umum',
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      label: 'Jumlah',
                      value: '${widget.donasi.jumlah} item',
                    ),
                    if (widget.donasi.deskripsi != null &&
                        widget.donasi.deskripsi!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Deskripsi:',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.donasi.deskripsi!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Confirmation Section
              Text(
                'Konfirmasi Penerimaan',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Notes Field
              TextFormField(
                controller: _notesCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  hintText: 'Tulis kondisi barang, keterangan lainnya...',
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Confirmation Checklist
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pastikan Anda telah menerima donasi ini sebelum mengkonfirmasi',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _showPhotoDialog,
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Terima Donasi + Foto'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detail Row Widget
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}
