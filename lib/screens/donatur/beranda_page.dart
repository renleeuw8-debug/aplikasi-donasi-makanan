import 'package:flutter/material.dart';
import 'dart:io';

import '../../models/donasi_model.dart';
import '../../services/api_service.dart';
import '../../services/profile_photo_service.dart';
import 'upload_donasi_page.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  List<DonasiModel> _donasiList = [];
  bool _isLoading = true;
  String _userName = 'User';
  File? _userPhoto;
  String? _userFotoUrl; // Foto profil dari API
  int _totalDonasi = 0;

  @override
  void initState() {
    super.initState();
    _loadBerandaData();
  }

  Future<void> _loadBerandaData() async {
    setState(() => _isLoading = true);
    try {
      // Only proceed if token is available
      if (ApiService.token == null) {
        print('No token available - user not logged in yet');
        setState(() => _isLoading = false);
        return;
      }

      // Get user profile
      final userData = await ApiService.getUserProfile();
      if (userData != null) {
        setState(() {
          _userName = userData['nama'] ?? 'User';
          // Ambil foto profil dari API
          _userFotoUrl = userData['foto_profil'];
        });
        // Load user photo
        try {
          final photoFile = await ProfilePhotoService.loadProfilePhoto(
            ActorType.donor,
            userData['id'].toString(),
          );
          if (photoFile != null) {
            // Clear cache for fresh load
            imageCache.clear();
            imageCache.clearLiveImages();
            setState(() => _userPhoto = photoFile);
          }
        } catch (e) {
          print('Error loading user photo: $e');
        }
      }

      // Get total donasi dari backend
      final myDonasiResponse = await ApiService.getMyDonasi();
      if (myDonasiResponse['success'] == true) {
        final myDonasiList = myDonasiResponse['data'] as List;
        setState(() => _totalDonasi = myDonasiList.length);
      }

      // Get donasi list dari backend
      final donasiResponse = await ApiService.getDonasi();
      if (donasiResponse['success'] == true) {
        final dataList = donasiResponse['data'] as List;
        // Filter hanya yang menunggu verifikasi
        final filtered = dataList
            .map((d) => DonasiModel.fromJson(d))
            .where((d) => (d.status ?? 'menunggu') == 'menunggu')
            .take(3)
            .toList();

        setState(() => _donasiList = filtered);
      }
    } catch (e) {
      print('Error loading beranda: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: color.background,
      appBar: AppBar(
        backgroundColor: color.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Donasi Makanan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting card with user info
                      _buildGreetingCard(color),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Donasi Aktif',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'Lihat Semua',
                              style: TextStyle(
                                color: color.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _donasiList.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: color.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: color.outline.withOpacity(0.2),
                                ),
                              ),
                              child: const Text(
                                'Belum ada donasi aktif. Yuk mulai berbagi!',
                              ),
                            )
                          : Column(
                              children: _donasiList
                                  .map((d) => _buildDonasiCard(d, color))
                                  .toList(),
                            ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24, right: 24),
                    child: FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UploadDonasiScreen(),
                          ),
                        ).then((_) => _loadBerandaData());
                      },
                      backgroundColor: Colors.green,
                      shape: const CircleBorder(),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGreetingCard(ColorScheme color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.primary, color.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (_userFotoUrl != null && _userFotoUrl!.isNotEmpty)
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(
                    'http://192.168.100.9:3000$_userFotoUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                  ),
                  onBackgroundImageError: (_, __) {},
                )
              else if (_userPhoto != null)
                CircleAvatar(
                  radius: 30,
                  backgroundImage: FileImage(_userPhoto!),
                )
              else
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $_userName 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'Mari berbagi kebaikan hari ini',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row showing total donations
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Donasi',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalDonasi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.favorite,
                  color: Colors.white.withOpacity(0.7),
                  size: 32,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDonasiCard(DonasiModel donasi, ColorScheme color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto donasi
          if (donasi.fotoUrl != null && donasi.fotoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.network(
                'http://192.168.100.9:3000${donasi.fotoUrl}',
                width: 120,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, st) {
                  return Container(
                    width: 120,
                    height: 140,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 40),
                    ),
                  );
                },
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: 120,
                    height: 140,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          // Info donasi
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              donasi.nama ?? 'Donasi',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              donasi.kategori ?? 'Umum',
                              style: TextStyle(
                                color: color.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: const Text('Menunggu'),
                        backgroundColor: Colors.orange.shade100,
                        labelStyle: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    donasi.deskripsi ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  if (donasi.alamat != null && donasi.alamat!.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            donasi.alamat ?? 'Lokasi tidak diketahui',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
