import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/api_service.dart';
import 'lokasi_page.dart';
import 'riwayat_page.dart';

/// Widget MenuTile untuk menu di profil
class MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 7),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.13),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// ProfileScreen - Profil Donatur/User (MySQL Backend, NO FIREBASE)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  File? _selectedPhoto;
  String _serverPhotoUrl = ''; // Foto dari server
  String _userId = 'donatur_001'; // Initialize with default
  String _userName = 'User';
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeUser();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload foto ketika app resume dari background atau dari halaman lain
      if (ApiService.token != null) {
        _initializeUser();
      }
    }
  }

  Future<void> _initializeUser() async {
    try {
      // Only proceed if token is available
      if (ApiService.token == null) {
        print('No token available - user not logged in yet');
        return;
      }

      final userData = await ApiService.getUserProfile();
      if (userData != null && mounted) {
        final userId = userData['id'].toString();
        final fotoUrl = userData['foto_profil'] as String? ?? '';

        setState(() {
          _userId = userId;
          _userName = userData['nama'] ?? 'User';
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
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  void _showEditProfileDialog() {
    final namaCtrl = TextEditingController(text: _userName);
    final nohpCtrl = TextEditingController();
    final alamatCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nohpCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nomor HP',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: alamatCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (namaCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama tidak boleh kosong')),
                );
                return;
              }

              try {
                final result = await ApiService.updateProfile(
                  nama: namaCtrl.text,
                  no_hp: nohpCtrl.text.isNotEmpty ? nohpCtrl.text : null,
                  alamat: alamatCtrl.text.isNotEmpty ? alamatCtrl.text : null,
                );

                if (!mounted) return;
                Navigator.pop(ctx);

                if (result['success'] == true) {
                  setState(() => _userName = namaCtrl.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Profil berhasil diperbarui'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ ${result['message']}')),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
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
      body: Stack(
        children: [
          // Header background gradient
          Container(
            height: 340,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.primary, color.secondary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Avatar - Elegant Design
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Avatar circle dengan border putih
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 67,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            _selectedPhoto != null &&
                                _selectedPhoto!.existsSync()
                            ? FileImage(_selectedPhoto!)
                            : _serverPhotoUrl.isNotEmpty
                            ? NetworkImage(_serverPhotoUrl)
                            : null,
                        child:
                            ((_selectedPhoto == null ||
                                    !_selectedPhoto!.existsSync()) &&
                                _serverPhotoUrl.isEmpty)
                            ? Icon(Icons.person, size: 60, color: color.primary)
                            : null,
                      ),
                    ),
                    // Camera button
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _uploadingPhoto ? null : _uploadProfilePhoto,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // User Name
                Text(
                  _userName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Donatur',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),
                // Menu Items
                MenuTile(
                  icon: Icons.edit,
                  title: 'Edit Profil',
                  subtitle: 'Ubah informasi pribadi Anda',
                  onTap: _showEditProfileDialog,
                ),
                MenuTile(
                  icon: Icons.location_on,
                  title: 'Lokasi Saya',
                  subtitle: 'Manage lokasi donasi Anda',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LokasiPage()),
                    );
                  },
                ),
                MenuTile(
                  icon: Icons.history,
                  title: 'Riwayat Donasi',
                  subtitle: 'Lihat semua donasi Anda',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RiwayatPage()),
                    );
                  },
                ),
                MenuTile(
                  icon: Icons.settings,
                  title: 'Pengaturan',
                  subtitle: 'Pengaturan aplikasi',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Pengaturan'),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pengaturan Aplikasi:'),
                            SizedBox(height: 12),
                            Text('• Notifikasi'),
                            Text('• Privasi'),
                            Text('• Tentang Aplikasi'),
                          ],
                        ),
                        actions: [
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Tutup'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
