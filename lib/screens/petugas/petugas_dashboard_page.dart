import 'package:flutter/material.dart';
import 'dart:io';
import '../../services/api_service.dart';
import '../../services/profile_photo_service.dart';

class PetugasDashboardPage extends StatefulWidget {
  final String? namaPetugas;

  const PetugasDashboardPage({super.key, this.namaPetugas});

  @override
  State<PetugasDashboardPage> createState() => _PetugasDashboardPageState();
}

class _PetugasDashboardPageState extends State<PetugasDashboardPage> {
  late Future<List<dynamic>> _donasiList;
  late Future<Map<String, dynamic>> _statistics;
  String? _userFotoUrl;
  File? _userPhoto;

  @override
  void initState() {
    super.initState();
    _loadDonasi();
    _loadStatistics();
    _loadUserProfile();
  }

  void _loadDonasi() {
    _donasiList = ApiService.getAllDonasi();
  }

  void _loadStatistics() {
    _statistics = ApiService.getStatistics();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userData = await ApiService.getUserProfile();
      debugPrint('=== Petugas Profile Data ===');
      debugPrint('Data: $userData');
      debugPrint('foto_profil: ${userData?['foto_profil']}');

      if (userData != null) {
        setState(() {
          _userFotoUrl = userData['foto_profil'];
        });
        debugPrint('Set _userFotoUrl: $_userFotoUrl');

        final photoFile = await ProfilePhotoService.loadProfilePhoto(
          ActorType.officer,
          userData['id'].toString(),
        );
        if (photoFile != null) {
          imageCache.clear();
          imageCache.clearLiveImages();
          setState(() => _userPhoto = photoFile);
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final displayName = widget.namaPetugas ?? 'Petugas';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: color.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Dashboard Petugas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.primary, color.primary.withOpacity(0.65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_userFotoUrl != null && _userFotoUrl!.isNotEmpty)
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(
                            'http://192.168.100.9:3000$_userFotoUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                          ),
                          onBackgroundImageError: (exception, stackTrace) {
                            debugPrint(
                              'CircleAvatar NetworkImage error: $exception',
                            );
                          },
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
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat datang, $displayName!',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Kelola donasi dan verifikasi dengan efisien',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Statistik Header
            Text(
              'Statistik Verifikasi',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),

            // User Statistics
            FutureBuilder<Map<String, dynamic>>(
              future: _statistics,
              builder: (context, snapshot) {
                int totalDonatur = 0;
                int totalPenerima = 0;

                if (snapshot.hasData && snapshot.data!['success'] == true) {
                  final data = snapshot.data!['data'];
                  totalDonatur = data['total_donatur'] ?? 0;
                  totalPenerima = data['total_penerima'] ?? 0;
                }

                return Column(
                  children: [
                    _StatCard(
                      icon: Icons.person,
                      title: 'Total Donatur',
                      value: totalDonatur.toString(),
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      icon: Icons.people,
                      title: 'Total Penerima',
                      value: totalPenerima.toString(),
                      color: Colors.teal,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Donasi Stats
            FutureBuilder<List<dynamic>>(
              future: _donasiList,
              builder: (context, snapshot) {
                int total = 0;
                int pending = 0;
                int verified = 0;

                if (snapshot.hasData) {
                  total = snapshot.data!.length;
                  pending = snapshot.data!
                      .where((d) => d['status'] == 'menunggu')
                      .length;
                  verified = snapshot.data!
                      .where((d) => d['status'] == 'diverifikasi')
                      .length;
                }

                return Column(
                  children: [
                    _StatCard(
                      icon: Icons.assignment,
                      title: 'Total Donasi',
                      value: total.toString(),
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      icon: Icons.hourglass_empty,
                      title: 'Menunggu Verifikasi',
                      value: pending.toString(),
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      icon: Icons.check_circle,
                      title: 'Diverifikasi',
                      value: verified.toString(),
                      color: Colors.green,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Donasi Terbaru
            Text(
              'Donasi Terbaru',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),

            FutureBuilder<List<dynamic>>(
              future: _donasiList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(color: color.primary),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada donasi',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final donasi = snapshot.data!.take(8).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: donasi.length,
                  itemBuilder: (context, index) {
                    final item = donasi[index];
                    final statusColor = _getStatusColor(item['status']);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.local_dining,
                              color: color.primary,
                            ),
                          ),
                        ),
                        title: Text(
                          item['nama_barang'] ?? 'Donasi',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Qty: ${item['jumlah'] ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Chip(
                          label: Text(
                            item['status'] ?? 'unknown',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: statusColor,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'menunggu':
        return Colors.orange;
      case 'diverifikasi':
        return Colors.green;
      case 'diterima':
        return Colors.blue;
      case 'selesai':
        return Colors.teal;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
