import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

import '../../services/api_service.dart';

class UploadDonasiScreen extends StatefulWidget {
  final Map<String, dynamic>? kebutuhan;

  const UploadDonasiScreen({super.key, this.kebutuhan});

  @override
  State<UploadDonasiScreen> createState() => _UploadDonasiScreenState();
}

// Alias untuk backward compatibility
class UploadDonasiPage extends UploadDonasiScreen {
  const UploadDonasiPage({super.key, super.kebutuhan});
}

class _UploadDonasiScreenState extends State<UploadDonasiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final _jumlahCtrl = TextEditingController(text: '1');
  final _noTelpCtrl = TextEditingController();

  String? _selectedKategori;
  String? _selectedSatuan;

  final List<String> _kategoriList = [
    'Makanan',
    'Pakaian',
    'Barang Bekas',
    'Buku',
    'Lainnya',
  ];
  final List<String> _satuanList = [
    'pcs',
    'kg',
    'liter',
    'box',
    'dus',
    'paket',
    'rim',
  ];

  Position? _selectedPosition;
  String _locationStatus = 'Ambil Lokasi';
  bool _loadingLocation = false;

  File? _fotoFile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Jika ada kebutuhan, populate form dengan data kebutuhan
    if (widget.kebutuhan != null) {
      _namaCtrl.text = widget.kebutuhan!['deskripsi'] ?? '';
      _jumlahCtrl.text = widget.kebutuhan!['jumlah']?.toString() ?? '1';
      // Set kategori sesuai jenis kebutuhan
      final jenis = widget.kebutuhan!['jenis_kebutuhan']
          ?.toString()
          .toLowerCase();
      switch (jenis) {
        case 'makanan':
          _selectedKategori = 'Makanan';
          break;
        case 'pakaian':
          _selectedKategori = 'Pakaian';
          break;
        case 'buku':
          _selectedKategori = 'Buku';
          break;
        case 'kesehatan':
          _selectedKategori = 'Lainnya';
          break;
        case 'barang':
        case 'lainnya':
        default:
          _selectedKategori = 'Barang Bekas';
      }
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _deskripsiCtrl.dispose();
    _jumlahCtrl.dispose();
    _noTelpCtrl.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationStatus = 'Mengambil lokasi...';
    });

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _loadingLocation = false;
              _locationStatus = 'Izin ditolak';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _loadingLocation = false;
            _locationStatus = 'Izin ditolak permanen';
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _selectedPosition = position;
          _locationStatus =
              '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _loadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
          _locationStatus = 'Error: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _selectPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _fotoFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error memilih foto: $e')));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan ambil lokasi terlebih dahulu')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final apiToken = ApiService.token;

      if (apiToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Silakan login terlebih dahulu.')),
          );
        }
        return;
      }

      // Buat donasi normal - tunggu petugas verifikasi dan pilih penerima
      final result = await ApiService.createDonasi(
        nama: _namaCtrl.text.trim(),
        kategori: _selectedKategori ?? 'Lainnya',
        deskripsi: _deskripsiCtrl.text.trim().isEmpty
            ? null
            : _deskripsiCtrl.text.trim(),
        jumlah: int.tryParse(_jumlahCtrl.text.trim()),
        satuan: _selectedSatuan,
        fotoFile: _fotoFile,
        latitude: _selectedPosition?.latitude,
        longitude: _selectedPosition?.longitude,
        alamat: _locationStatus,
      );

      if (!mounted) return;

      if (result['success']) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Donasi berhasil dibuat! Tunggu petugas untuk memverifikasi dan memilih penerima.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah donasi: ${result['message']}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengunggah donasi: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unggah Donasi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _namaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nama Donasi',
                    hintText: 'Misal: Nasi Goreng, Pakaian Layak Pakai',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? 'Nama donasi wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedKategori,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: _kategoriList
                      .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedKategori = v),
                  validator: (v) =>
                      (v == null) ? 'Kategori wajib dipilih' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _deskripsiCtrl,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi (Opsional)',
                    hintText: 'Tambahkan informasi lebih lanjut',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noTelpCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nomor Telpon',
                    hintText: '08xxxxxxxxxx',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? 'Nomor telpon wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _jumlahCtrl,
                        decoration: InputDecoration(
                          labelText: 'Jumlah',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Jumlah wajib diisi';
                          if (int.tryParse(v!) == null)
                            return 'Harus berupa angka';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSatuan,
                        decoration: InputDecoration(
                          labelText: 'Satuan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _satuanList
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedSatuan = v),
                        validator: (v) =>
                            (v == null) ? 'Satuan wajib dipilih' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lokasi Donasi',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(_locationStatus),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _loadingLocation
                              ? null
                              : _getCurrentLocation,
                          icon: const Icon(Icons.location_on),
                          label: const Text('Ambil Lokasi'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Foto Donasi (Opsional)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        if (_fotoFile != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _fotoFile!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        ElevatedButton.icon(
                          onPressed: _selectPhoto,
                          icon: const Icon(Icons.image),
                          label: const Text('Pilih Foto'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Unggah Donasi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
