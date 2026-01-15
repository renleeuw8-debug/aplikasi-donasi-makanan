import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LaporanPenangananPage extends StatefulWidget {
  const LaporanPenangananPage({super.key});

  @override
  State<LaporanPenangananPage> createState() => _LaporanPenangananPageState();
}

class _LaporanPenangananPageState extends State<LaporanPenangananPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<dynamic>> _donasiSemua;
  late Future<List<dynamic>> _donasiMenunggu;
  late Future<List<dynamic>> _donasiDiverifikasi;
  late Future<List<dynamic>> _donasiSelesai;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  void _loadData() {
    _donasiSemua = ApiService.getAllDonasi();
    _donasiMenunggu = ApiService.getDonasiMenungguVerifikasi();
    _donasiDiverifikasi = ApiService.getDonasiSudahDiverifikasi();
    _donasiSelesai = _fetchDonasiSelesai();
  }

  Future<List<dynamic>> _fetchDonasiSelesai() async {
    try {
      final response = await ApiService.get('/donasi?status=selesai');
      if (response != null && response['success'] == true) {
        return response['data'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching donasi selesai: $e');
      return [];
    }
  }

  Widget _buildDonasiCard(dynamic donasi, BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final namaBarang = donasi['nama_barang'] ?? 'Donasi';
    final kategori = donasi['jenis_donasi'] ?? '-';
    final jumlah = donasi['jumlah'] ?? '-';
    final satuan = donasi['satuan'] ?? 'item';
    final status = donasi['status'] ?? 'Menunggu';
    final penerimanama = donasi['penerima_nama'] ?? 'Belum ada penerima';
    final tanggal = donasi['created_at'] ?? '-';

    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'menunggu':
        case 'menunggu verifikasi':
          return Colors.orange;
        case 'diverifikasi':
        case 'terverifikasi':
          return Colors.blue;
        case 'ditolak':
        case 'rejected':
          return Colors.red;
        case 'selesai':
        case 'completed':
          return Colors.green;
        default:
          return Colors.grey;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    namaBarang,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Detail donasi
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kategori',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        kategori,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jumlah',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        '$jumlah $satuan',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Penerima
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Penerima',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          penerimanama,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Tanggal
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  tanggal.toString().split('T')[0],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(Future<List<dynamic>> future) {
    final color = Theme.of(context).colorScheme;

    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: color.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada data',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        final donasi = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: donasi.length,
          itemBuilder: (context, index) {
            return _buildDonasiCard(donasi[index], context);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          'Laporan Penanganan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Menunggu'),
            Tab(text: 'Diverifikasi'),
            Tab(text: 'Selesai'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent(_donasiSemua),
          _buildTabContent(_donasiMenunggu),
          _buildTabContent(_donasiDiverifikasi),
          _buildTabContent(_donasiSelesai),
        ],
      ),
    );
  }
}
