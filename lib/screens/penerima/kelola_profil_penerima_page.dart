import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../models/penerima_model.dart';
import '../../services/penerima_service.dart';
import '../../services/api_service.dart';

// Simple GeoPoint class (replace Firestore GeoPoint)
class GeoPoint {
  final double latitude;
  final double longitude;

  GeoPoint(this.latitude, this.longitude);
}

class KelolaProfIlPenerimaPage extends StatefulWidget {
  final VoidCallback? onUploadSuccess;

  const KelolaProfIlPenerimaPage({super.key, this.onUploadSuccess});

  @override
  State<KelolaProfIlPenerimaPage> createState() =>
      _KelolaProfIlPenerimaPageState();
}

class _KelolaProfIlPenerimaPageState extends State<KelolaProfIlPenerimaPage> {
  final _formKey = GlobalKey<FormState>();
  final _penerimaService = PenerimaService();

  // Controllers
  late TextEditingController _namaCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _alamatCtrl;
  late TextEditingController _kontakCtrl;

  File? _selectedPhoto;
  String _serverPhotoUrl = ''; // Foto dari server
  PenerimaModel? _currentPenerima;
  GeoPoint? _selectedLocation;
  List<dynamic> _kebutuhanAktif = [];
  bool _loadingKebutuhan = false;
  bool _loading = true;
  bool _saving = false;
  bool _locationLoading = false;
  bool _uploadingPhoto = false;
  String _userId = ''; // ID untuk menyimpan foto dengan nama unik

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _alamatCtrl = TextEditingController();
    _kontakCtrl = TextEditingController();

    // Initialize with loading
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Get user profile dari API
      final userData = await ApiService.getUserProfile();
      if (userData != null && mounted) {
        final userId = userData['id'].toString();
        final fotoUrl = userData['foto_profil'] as String? ?? '';

        setState(() {
          _userId = userId;
          // Load foto dari server
          if (fotoUrl.isNotEmpty) {
            // Clear cache dan tambah timestamp untuk force reload
            imageCache.clear();
            imageCache.clearLiveImages();
            _serverPhotoUrl =
                'http://192.168.100.9:3000$fotoUrl?t=${DateTime.now().millisecondsSinceEpoch}';
            debugPrint('🖼️ Server photo loaded: $_serverPhotoUrl');
          }
        });

        // Load user data ke controllers
        _namaCtrl.text = userData['nama'] ?? '';
        _emailCtrl.text = userData['email'] ?? '';
        _alamatCtrl.text = userData['alamat'] ?? '';
        _kontakCtrl.text = userData['no_hp'] ?? '';

        // Load lokasi jika ada
        if (userData['latitude'] != null && userData['longitude'] != null) {
          setState(() {
            _selectedLocation = GeoPoint(
              double.parse(userData['latitude'].toString()),
              double.parse(userData['longitude'].toString()),
            );
          });
        }
      }

      _loadPenerimaData();
    } catch (e) {
      debugPrint('Failed to load initial data: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadPenerimaData() async {
    try {
      // Load kebutuhan aktif
      final kebutuhan = await ApiService.getAllKebutuhan(status: 'aktif');
      if (mounted) {
        setState(() {
          _kebutuhanAktif = kebutuhan;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading penerima data: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _uploadProfilePhoto() async {
    try {
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _uploadingPhoto = true);

      // Upload ke server
      try {
        debugPrint('🔄 Calling ApiService.uploadProfilePhoto...');
        final result = await ApiService.uploadProfilePhoto(
          File(pickedFile.path),
        );
        debugPrint('✅ Upload response: $result');

        if (mounted) {
          setState(() => _uploadingPhoto = false);
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Foto profil berhasil diupload'),
                backgroundColor: Colors.green,
              ),
            );

            // Reload foto dari server
            final userData = await ApiService.getUserProfile();
            if (userData != null && mounted) {
              final fotoUrl = userData['foto_profil'] as String? ?? '';
              if (fotoUrl.isNotEmpty) {
                imageCache.clear();
                imageCache.clearLiveImages();
                setState(() {
                  _serverPhotoUrl =
                      'http://192.168.100.9:3000$fotoUrl?t=${DateTime.now().millisecondsSinceEpoch}';
                  _selectedPhoto = null; // Clear preview
                  debugPrint(
                    '🖼️ Photo refreshed from server: $_serverPhotoUrl',
                  );
                });
              }
            }

            // Panggil callback untuk set tab ke Dashboard
            widget.onUploadSuccess?.call();

            // Delay sedikit untuk sync database, terus pop back
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${result['message']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (uploadError) {
        debugPrint('❌ Upload error detail: $uploadError');
        if (mounted) {
          setState(() => _uploadingPhoto = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload gagal: ${uploadError.toString()}')),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Outer error: $e');
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal upload foto: $e')));
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _locationLoading = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin lokasi ditolak')),
            );
          }
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = GeoPoint(position.latitude, position.longitude);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lokasi berhasil diperbarui')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _saveProfil() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih lokasi terlebih dahulu')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_currentPenerima != null) {
        try {
          final updated = _currentPenerima!.copyWith(
            nama: _namaCtrl.text.trim(),
            alamat: _alamatCtrl.text.trim(),
            kontak: _kontakCtrl.text.trim(),
          );
          await _penerimaService.updatePenerima(_currentPenerima!.id, updated);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profil berhasil diperbarui')),
            );
          }
        } catch (firebaseError) {
          debugPrint('Firebase error in saveProfil: $firebaseError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profil tidak dapat diperbarui di mode ini'),
              ),
            );
          }
        }
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

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _alamatCtrl.dispose();
    _kontakCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 Profil Penerima'),
        actions: [
          IconButton(
            onPressed: () {
              ApiService.clearToken();
              if (!context.mounted) return;
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo Avatar
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 3,
                              ),
                              color: Colors.white,
                            ),
                            child: ClipOval(
                              child:
                                  _selectedPhoto != null &&
                                      _selectedPhoto!.existsSync()
                                  ? Image.file(
                                      _selectedPhoto!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              size: 50,
                                              color: Theme.of(
                                                context,
                                              ).primaryColor,
                                            );
                                          },
                                    )
                                  : _serverPhotoUrl.isNotEmpty
                                  ? Image.network(
                                      _serverPhotoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              size: 50,
                                              color: Theme.of(
                                                context,
                                              ).primaryColor,
                                            );
                                          },
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Theme.of(context).primaryColor,
                                    ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _uploadingPhoto ? null : _uploadProfilePhoto,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.amber,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: _uploadingPhoto
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '📝 Edit Data Diri',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _namaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email (Tidak dapat diubah)',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _alamatCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Lengkap',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _kontakCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Kontak (WhatsApp)',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Location Section
                    Text(
                      '📍 Lokasi Penerima',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedLocation != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Lokasi dipilih'),
                                  Text(
                                    '📍 ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('Lokasi belum dipilih')),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _locationLoading ? null : _getCurrentLocation,
                      icon: _locationLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: const Text('Update Lokasi Saat Ini'),
                    ),
                    const SizedBox(height: 32),

                    // Kebutuhan Section - Display kebutuhan yang sudah diajukan
                    Text(
                      '🎁 Kebutuhan Anda',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_loadingKebutuhan)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_kebutuhanAktif.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Belum ada kebutuhan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Ajukan kebutuhan Anda untuk menerima donasi',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: _kebutuhanAktif.map((kebutuhan) {
                          final jenis = kebutuhan['jenis_kebutuhan'] ?? 'N/A';
                          final deskripsi = kebutuhan['deskripsi'] ?? '-';
                          final jumlah = kebutuhan['jumlah'] ?? 0;
                          final status = kebutuhan['status'] ?? 'aktif';

                          IconData getIcon(String j) {
                            switch (j.toLowerCase()) {
                              case 'makanan':
                                return Icons.local_dining;
                              case 'pakaian':
                                return Icons.checkroom;
                              case 'alat rumah tangga':
                                return Icons.home_repair_service;
                              case 'peralatan sekolah':
                                return Icons.school;
                              case 'obat-obatan':
                                return Icons.local_pharmacy;
                              case 'peralatan kerja':
                                return Icons.construction;
                              default:
                                return Icons.shopping_bag;
                            }
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Icon(
                                getIcon(jenis),
                                color: Colors.blue,
                                size: 28,
                              ),
                              title: Text(
                                jenis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(deskripsi),
                              trailing: Chip(
                                label: Text('$jumlah'),
                                backgroundColor: Colors.blue.shade100,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 32),

                    // Save Button
                    FilledButton(
                      onPressed: _saving ? null : _saveProfil,
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
                          : const Text('Simpan Perubahan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
