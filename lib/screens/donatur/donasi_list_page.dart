import 'package:flutter/material.dart';

import '../../models/donasi_model.dart';
import '../../services/api_service.dart';
import 'upload_donasi_page.dart';

class DonasiListScreen extends StatefulWidget {
  const DonasiListScreen({super.key});

  @override
  State<DonasiListScreen> createState() => _DonasiListScreenState();
}

class _DonasiListScreenState extends State<DonasiListScreen> {
  String _selectedKategori = 'Semua';
  List<DonasiModel> _donasiList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDonasiData();
  }

  Future<void> _loadDonasiData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getDonasi();
      if (response['success'] == true) {
        final dataList = response['data'] as List;
        final donasi = dataList
            .map((d) => DonasiModel.fromJson(d))
            .where((d) => (d.status ?? 'pending') != 'completed')
            .toList();

        if (mounted) {
          setState(() {
            _donasiList = donasi;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading donasi: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<DonasiModel> _getFilteredDonasi() {
    if (_selectedKategori == 'Semua') {
      return _donasiList;
    }
    return _donasiList
        .where(
          (d) => d.kategori?.toLowerCase() == _selectedKategori.toLowerCase(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donasi'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _selectedKategori = v),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'Semua', child: Text('Semua')),
              PopupMenuItem(value: 'Makanan', child: Text('Makanan')),
              PopupMenuItem(value: 'Pakaian', child: Text('Pakaian')),
              PopupMenuItem(value: 'Barang Bekas', child: Text('Barang Bekas')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _getFilteredDonasi().isEmpty
          ? const Center(child: Text('Belum ada donasi tersedia'))
          : RefreshIndicator(
              onRefresh: _loadDonasiData,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: _getFilteredDonasi().length,
                itemBuilder: (context, i) {
                  final d = _getFilteredDonasi()[i];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        child: const Icon(Icons.volunteer_activism),
                      ),
                      title: Text(d.namaDonasi ?? 'Unknown'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: -8,
                            children: [
                              Chip(
                                label: Text(
                                  d.kategori ?? 'Umum',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor: Colors.grey[400],
                                visualDensity: VisualDensity.compact,
                              ),
                              const Chip(
                                label: Text('0.5 km'),
                                avatar: Icon(Icons.place, size: 16),
                                visualDensity: VisualDensity.compact,
                              ),
                              const Chip(
                                label: Text('2 jam lalu'),
                                avatar: Icon(Icons.schedule, size: 16),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showDetail(d),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const UploadDonasiScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Upload Donasi'),
      ),
    );
  }

  void _showDetail(DonasiModel d) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.namaDonasi ?? 'Unknown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Kategori: ${d.kategori}'),
            const SizedBox(height: 4),
            Text('Status: ${d.status}'),
            if (d.deskripsi != null) ...[
              const SizedBox(height: 8),
              Text(d.deskripsi!),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Lihat di peta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
