import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class KebutuhanDetailPage extends StatefulWidget {
  final Map<String, dynamic> kebutuhan;

  const KebutuhanDetailPage({Key? key, required this.kebutuhan})
    : super(key: key);

  @override
  State<KebutuhanDetailPage> createState() => _KebutuhanDetailPageState();
}

class _KebutuhanDetailPageState extends State<KebutuhanDetailPage> {
  late TextEditingController _deskripsiCtrl;
  late TextEditingController _jumlahCtrl;
  late String _selectedStatus;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _deskripsiCtrl = TextEditingController(
      text: widget.kebutuhan['deskripsi'] ?? '',
    );
    _jumlahCtrl = TextEditingController(
      text: widget.kebutuhan['jumlah']?.toString() ?? '',
    );
    _selectedStatus = widget.kebutuhan['status'] ?? 'aktif';
  }

  @override
  void dispose() {
    _deskripsiCtrl.dispose();
    _jumlahCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _updateKebutuhan() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.updateKebutuhan(
        id: widget.kebutuhan['id'],
        deskripsi: _deskripsiCtrl.text.trim(),
        jumlah: int.parse(_jumlahCtrl.text.trim()),
        status: _selectedStatus,
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kebutuhan berhasil diupdate ✓'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteKebutuhan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kebutuhan?'),
        content: const Text('Anda yakin ingin menghapus kebutuhan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.deleteKebutuhan(widget.kebutuhan['id']);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kebutuhan berhasil dihapus ✓'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        actions: [
          if (!_isEditing)
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Edit'),
                  onTap: () => setState(() => _isEditing = true),
                ),
                PopupMenuItem(
                  child: const Text(
                    'Hapus',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: _deleteKebutuhan,
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      backgroundColor: color.primary.withOpacity(0.2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status
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
                      'Status',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'aktif',
                            child: Text('Aktif'),
                          ),
                          DropdownMenuItem(
                            value: 'terpenuhi',
                            child: Text('Terpenuhi'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedStatus = value);
                          }
                        },
                      )
                    else
                      Chip(
                        label: Text(
                          _selectedStatus == 'aktif' ? 'Aktif' : 'Terpenuhi',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: _selectedStatus == 'aktif'
                            ? Colors.orange
                            : Colors.green,
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
                      'Deskripsi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      TextFormField(
                        controller: _deskripsiCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Masukkan deskripsi kebutuhan...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      )
                    else
                      Text(
                        _deskripsiCtrl.text,
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Jumlah
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
                    if (_isEditing)
                      TextFormField(
                        controller: _jumlahCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Masukkan jumlah...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      )
                    else
                      Text(
                        _jumlahCtrl.text,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            if (_isEditing) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateKebutuhan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => setState(() => _isEditing = false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
