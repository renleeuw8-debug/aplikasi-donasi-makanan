import 'package:flutter/material.dart';
import '../../models/donasi_model.dart';
import '../../services/api_service.dart';

class DashboardPenerimaPage extends StatefulWidget {
  const DashboardPenerimaPage({super.key});

  @override
  State<DashboardPenerimaPage> createState() => _DashboardPenerimaPageState();
}

class _DashboardPenerimaPageState extends State<DashboardPenerimaPage> {
  List<DonasiModel> _donasiMasuk = [];
  List<DonasiModel> _donasiDiterima = [];
  bool _isLoading = true;
  String _selectedTab = 'masuk';
  String _userFotoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadDonasi();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload profile foto saat back dari profil page
    _loadUserProfile();
  }

  // Manual refresh untuk force reload data
  Future<void> _refreshData() async {
    await _loadUserProfile();
    await _loadDonasi();
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await ApiService.getUserProfile();
      debugPrint('📱 Profile Response: $response');

      if (response != null) {
        // Handle dua format response:
        // 1. Direct user object: {id, nama, email, foto_profil, ...}
        // 2. Wrapped object: {success: true, data: {...}}

        Map<String, dynamic> userData;

        if (response.containsKey('data') && response['success'] == true) {
          // Format wrapped
          userData = response['data'] as Map<String, dynamic>;
        } else {
          // Format direct
          userData = response as Map<String, dynamic>;
        }

        final fotoUrl = userData['foto_profil'] as String? ?? '';
        debugPrint('🖼️ Foto URL dari API: $fotoUrl');

        if (mounted) {
          // Clear image cache untuk memastikan foto baru di-load
          imageCache.clear();
          imageCache.clearLiveImages();

          final fullUrl = fotoUrl.isNotEmpty
              ? 'http://192.168.100.9:3000$fotoUrl?t=${DateTime.now().millisecondsSinceEpoch}'
              : '';

          debugPrint('✅ Full URL yang akan diload: $fullUrl');

          setState(() => _userFotoUrl = fullUrl);
        }
      } else {
        debugPrint('❌ Response null');
      }
    } catch (e) {
      debugPrint('❌ Error loading user profile: $e');
    }
  }

  Future<void> _loadDonasi() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getDonasi();
      if (response['success'] == true) {
        final dataList = response['data'] as List;
        final donasiList = dataList
            .map((d) => DonasiModel.fromJson(d))
            .toList();

        if (mounted) {
          setState(() {
            _donasiMasuk = donasiList
                .where((d) => (d.status ?? 'pending') == 'diverifikasi')
                .toList();
            _donasiDiterima = donasiList
                .where((d) => (d.status ?? 'pending') == 'diterima')
                .toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading donasi: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptDonasi(int donasiId) async {
    final keterangan = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final reasonCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Terima Donasi'),
          content: TextField(
            controller: reasonCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Tulis catatan penerimaan... (wajib)',
              labelText: 'Catatan',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (reasonCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Catatan wajib diisi!')),
                  );
                  return;
                }
                Navigator.pop(ctx, reasonCtrl.text.trim());
              },
              child: const Text('Terima'),
            ),
          ],
        );
      },
    );

    if (keterangan != null && keterangan.isNotEmpty) {
      try {
        final result = await ApiService.acceptDirectDonation(
          donasiId: donasiId,
          keterangan: keterangan,
        );

        if (mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Donasi berhasil diterima'),
                backgroundColor: Colors.green,
              ),
            );
            _loadDonasi();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${result['message']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _rejectDonasi(int donasiId) async {
    final keterangan = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final reasonCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Tolak Donasi'),
          content: TextField(
            controller: reasonCtrl,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Alasan penolakan...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()),
              child: const Text('Tolak'),
            ),
          ],
        );
      },
    );

    if (keterangan != null && keterangan.isNotEmpty) {
      try {
        final result = await ApiService.rejectDirectDonation(
          donasiId: donasiId,
          keterangan: keterangan,
        );

        if (mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✗ Donasi berhasil ditolak'),
                backgroundColor: Colors.red,
              ),
            );
            _loadDonasi();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${result['message']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
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
          'Dashboard Penerima',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.primary, color.primary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_userFotoUrl.isNotEmpty)
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white,
                            backgroundImage: NetworkImage(_userFotoUrl),
                            onBackgroundImageError: (exception, stackTrace) {
                              debugPrint(
                                'Error loading profile photo: $exception',
                              );
                            },
                          )
                        else
                          const CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, size: 40),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat Datang',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Kelola donasi yang Anda terima',
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

              // Stats Section
              Text(
                'Statistik Penerimaan',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Donasi Masuk',
                      value: _donasiMasuk.length.toString(),
                      icon: Icons.mail_outline,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Sudah Diterima',
                      value: _donasiDiterima.length.toString(),
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Tabs
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 'masuk'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTab == 'masuk'
                                  ? color.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          'Donasi Masuk (${_donasiMasuk.length})',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedTab == 'masuk'
                                ? color.primary
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 'diterima'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTab == 'diterima'
                                  ? color.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          'Diterima (${_donasiDiterima.length})',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedTab == 'diterima'
                                ? color.primary
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Donasi List
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedTab == 'masuk'
                  ? _buildDonasiMasukList()
                  : _buildDonasiDiterimaList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonasiMasukList() {
    if (_donasiMasuk.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(Icons.mail_outline, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Tidak ada donasi masuk',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _donasiMasuk.length,
      itemBuilder: (ctx, idx) {
        final donasi = _donasiMasuk[idx];
        return _DonasiCardWithAction(
          donasi: donasi,
          onAccept: () => _acceptDonasi(donasi.id ?? 0),
          onReject: () => _rejectDonasi(donasi.id ?? 0),
        );
      },
    );
  }

  Widget _buildDonasiDiterimaList() {
    if (_donasiDiterima.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada donasi yang diterima',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _donasiDiterima.length,
      itemBuilder: (ctx, idx) {
        final donasi = _donasiDiterima[idx];
        return _DonasiCard(donasi: donasi);
      },
    );
  }
}

// Card dengan tombol action
class _DonasiCardWithAction extends StatelessWidget {
  final DonasiModel donasi;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _DonasiCardWithAction({
    required this.donasi,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto Donasi
          if (donasi.fotoUrl != null && donasi.fotoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                'http://192.168.100.9:3000${donasi.fotoUrl}',
                height: 500,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 500,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donasi.nama ?? 'Donasi',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${donasi.jumlah} ${donasi.satuan ?? 'pcs'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: const Text('Masuk'),
                      backgroundColor: Colors.orange.shade100,
                      labelStyle: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (donasi.deskripsi != null &&
                    donasi.deskripsi!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    donasi.deskripsi!,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onAccept,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Terima'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                        ),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Tolak'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Card read-only
class _DonasiCard extends StatelessWidget {
  final DonasiModel donasi;

  const _DonasiCard({required this.donasi});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto Donasi
          if (donasi.fotoUrl != null && donasi.fotoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                'http://192.168.100.9:3000${donasi.fotoUrl}',
                height: 500,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 500,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donasi.nama ?? 'Donasi',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${donasi.jumlah} ${donasi.satuan ?? 'pcs'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: const Text('Diterima'),
                      backgroundColor: Colors.green.shade100,
                      labelStyle: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (donasi.deskripsi != null &&
                    donasi.deskripsi!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    donasi.deskripsi!,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
