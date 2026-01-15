import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/api_service.dart';

class ProfilPetugasPage extends StatefulWidget {
  const ProfilPetugasPage({super.key});

  @override
  State<ProfilPetugasPage> createState() => _ProfilPetugasPageState();
}

class _ProfilPetugasPageState extends State<ProfilPetugasPage> {
  late String _userId = 'P001';
  Map<String, dynamic>? _userData;
  bool _loading = true;
  bool _isEditing = false;
  bool _uploadingPhoto = false;
  String _serverPhotoUrl = ''; // Foto profil dari server

  late TextEditingController _namaCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _nohpCtrl;
  late TextEditingController _alamatCtrl;
  File? _selectedPhoto;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _nohpCtrl = TextEditingController();
    _alamatCtrl = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _nohpCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePhotoToFile(File sourcePhoto) async {
    try {
      setState(() => _selectedPhoto = sourcePhoto);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan foto: $e')));
      }
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _loading = true);
    try {
      // Load user data dari API
      final userData = await ApiService.getUserProfile();
      if (userData != null) {
        final fotoUrl = userData['foto_profil'] as String? ?? '';

        setState(() {
          _userData = userData;
          _userId = userData['id'].toString();
          _namaCtrl.text = userData['nama'] ?? '';
          _emailCtrl.text = userData['email'] ?? '';
          _nohpCtrl.text = userData['no_hp'] ?? '';
          _alamatCtrl.text = userData['alamat'] ?? '';

          // Load foto dari server
          if (fotoUrl.isNotEmpty) {
            imageCache.clear();
            imageCache.clearLiveImages();
            _serverPhotoUrl =
                'http://192.168.100.9:3000$fotoUrl?t=${DateTime.now().millisecondsSinceEpoch}';
            debugPrint('🖼️ Server photo loaded: $_serverPhotoUrl');
          }
        });
      }

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
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

  Future<void> _updateProfile() async {
    try {
      // Update profile data locally (could add API call here if needed)
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    }
  }

  Future<void> _logout() async {
    try {
      // Clear token and navigate to login
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logout: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Petugas'),
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Profil',
            ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header dengan Avatar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          color: Colors.white,
                        ),
                        child: ClipOval(
                          child:
                              _selectedPhoto != null &&
                                  _selectedPhoto!.existsSync()
                              ? Image.file(
                                  _selectedPhoto!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Theme.of(context).primaryColor,
                                    );
                                  },
                                )
                              : _serverPhotoUrl.isNotEmpty
                              ? Image.network(
                                  _serverPhotoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Theme.of(context).primaryColor,
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
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: _uploadingPhoto
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      border: Border.all(color: Colors.green[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Petugas Verifikasi Donasi',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _namaCtrl.text.isNotEmpty ? _namaCtrl.text : 'Petugas',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama
                  _buildTextField(
                    controller: _namaCtrl,
                    label: 'Nama Lengkap',
                    icon: Icons.person,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 16),

                  // Email (Read-only)
                  _buildTextField(
                    controller: _emailCtrl,
                    label: 'Email',
                    icon: Icons.email,
                    enabled: false,
                  ),
                  const SizedBox(height: 16),

                  // No HP
                  _buildTextField(
                    controller: _nohpCtrl,
                    label: 'Nomor HP',
                    icon: Icons.phone,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Alamat
                  _buildTextField(
                    controller: _alamatCtrl,
                    label: 'Alamat',
                    icon: Icons.location_on,
                    enabled: _isEditing,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Informasi Petugas',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ID: $_userId\n\n'
                          'Peran: Petugas Verifikasi Donasi\n\n'
                          'Status: Aktif',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _isEditing = false);
                              _loadUserData(); // Reset
                            },
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _updateProfile,
                            child: const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: !enabled,
        fillColor: !enabled ? Colors.grey[100] : null,
      ),
    );
  }
}
