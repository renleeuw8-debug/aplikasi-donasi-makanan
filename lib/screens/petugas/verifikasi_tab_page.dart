import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'verifikasi_donasi_page.dart';

class VerifikasiTabPage extends StatefulWidget {
  const VerifikasiTabPage({super.key});

  @override
  State<VerifikasiTabPage> createState() => _VerifikasiTabPageState();
}

class _VerifikasiTabPageState extends State<VerifikasiTabPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<dynamic>> _donasiMenunggu;
  late Future<List<dynamic>> _donasiDiverifikasi;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    debugPrint('=== Loading data ===');
    debugPrint('Token: ${ApiService.token}');
    _donasiMenunggu = ApiService.getDonasiMenungguVerifikasi();
    _donasiDiverifikasi = ApiService.getDonasiSudahDiverifikasi();
  }

  void _refreshData() {
    setState(() {
      _loadData();
    });
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
          'Verifikasi Donasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.hourglass_empty), text: 'Menunggu'),
            Tab(icon: Icon(Icons.check_circle), text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Donasi Menunggu Verifikasi
          FutureBuilder<List<dynamic>>(
            future: _donasiMenunggu,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: color.primary),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
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
                        Icons.card_giftcard,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada donasi menunggu verifikasi',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final donasiList = snapshot.data!;

              return RefreshIndicator(
                onRefresh: () async {
                  _refreshData();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: donasiList.length,
                  itemBuilder: (context, index) {
                    final donasi = donasiList[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 50,
                          height: 50,
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
                          donasi['nama_barang'] ?? 'Donasi',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Qty: ${donasi['jumlah'] ?? 0}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Donatur: ${(donasi['donatur'] as Map?)?.containsKey('nama') == true ? donasi['donatur']['nama'] : (donasi['donatur_nama'] ?? 'Unknown')}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        trailing: SizedBox(
                          width: 90,
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          VerifikasiDonasiPage(
                                            donasi: donasi
                                                .cast<String, dynamic>(),
                                          ),
                                    ),
                                  )
                                  .then((_) => _refreshData());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color.primary,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'Verifikasi',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Tab 2: Riwayat Donasi Sudah Diverifikasi
          FutureBuilder<List<dynamic>>(
            future: _donasiDiverifikasi,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: color.primary),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
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
                        Icons.history,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada riwayat verifikasi',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final donasiList = snapshot.data!;

              return RefreshIndicator(
                onRefresh: () async {
                  _refreshData();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: donasiList.length,
                  itemBuilder: (context, index) {
                    final donasi = donasiList[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        title: Text(
                          donasi['nama_barang'] ?? 'Donasi',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Qty: ${donasi['jumlah'] ?? 0}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Diverifikasi oleh: ${(donasi['petugas'] as Map?)?.containsKey('nama') == true ? donasi['petugas']['nama'] : 'Unknown'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.verified,
                          color: Colors.green.shade400,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
