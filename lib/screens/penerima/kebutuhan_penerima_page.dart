import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'kebutuhan_form_page.dart';
import 'kebutuhan_detail_page.dart';

class KebutuhanPenerimaPage extends StatefulWidget {
  const KebutuhanPenerimaPage({super.key});

  @override
  State<KebutuhanPenerimaPage> createState() => _KebutuhanPenerimaPageState();
}

class _KebutuhanPenerimaPageState extends State<KebutuhanPenerimaPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<dynamic>> _kebutuhanAktif;
  late Future<List<dynamic>> _kebutuhanTerpenuhi;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    _kebutuhanAktif = ApiService.getAllKebutuhan(status: 'aktif');
    _kebutuhanTerpenuhi = ApiService.getAllKebutuhan(status: 'terpenuhi');
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

  IconData _getIconForJenis(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'makanan':
        return Icons.local_dining;
      case 'pakaian':
        return Icons.checkroom;
      case 'buku':
        return Icons.auto_stories;
      case 'kesehatan':
        return Icons.local_pharmacy;
      case 'barang':
        return Icons.shopping_bag;
      case 'lainnya':
        return Icons.help_outline;
      default:
        return Icons.shopping_bag;
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
          'Kebutuhan Saya',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Aktif'),
            Tab(icon: Icon(Icons.check_circle), text: 'Terpenuhi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Kebutuhan Aktif
          FutureBuilder<List<dynamic>>(
            future: _kebutuhanAktif,
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
                        Icons.inbox_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada kebutuhan aktif',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final kebutuhanList = snapshot.data!;

              return RefreshIndicator(
                onRefresh: () async {
                  _refreshData();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: kebutuhanList.length,
                  itemBuilder: (context, index) {
                    final kebutuhan = kebutuhanList[index];

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
                              _getIconForJenis(kebutuhan['jenis_kebutuhan']),
                              color: color.primary,
                            ),
                          ),
                        ),
                        title: Text(
                          kebutuhan['deskripsi'] ?? 'Kebutuhan',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Jumlah: ${kebutuhan['jumlah'] ?? 0}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Chip(
                              label: Text(
                                kebutuhan['jenis_kebutuhan'] ?? 'Unknown',
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: color.primary.withOpacity(0.2),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    KebutuhanDetailPage(kebutuhan: kebutuhan),
                              ),
                            ).then((_) => _refreshData());
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  KebutuhanDetailPage(kebutuhan: kebutuhan),
                            ),
                          ).then((_) => _refreshData());
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Tab 2: Kebutuhan Terpenuhi
          FutureBuilder<List<dynamic>>(
            future: _kebutuhanTerpenuhi,
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
                        Icons.inbox_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada kebutuhan terpenuhi',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final kebutuhanList = snapshot.data!;

              return RefreshIndicator(
                onRefresh: () async {
                  _refreshData();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: kebutuhanList.length,
                  itemBuilder: (context, index) {
                    final kebutuhan = kebutuhanList[index];

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
                          child: Center(
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        title: Text(
                          kebutuhan['deskripsi'] ?? 'Kebutuhan',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Jumlah: ${kebutuhan['jumlah'] ?? 0}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Chip(
                              label: Text(
                                'Terpenuhi',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const KebutuhanFormPage()),
          ).then((_) => _refreshData());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
