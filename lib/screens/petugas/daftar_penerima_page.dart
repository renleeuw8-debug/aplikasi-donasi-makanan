import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class DaftarPenerimaPage extends StatefulWidget {
  const DaftarPenerimaPage({super.key});

  @override
  State<DaftarPenerimaPage> createState() => _DaftarPenerimaPageState();
}

class _DaftarPenerimaPageState extends State<DaftarPenerimaPage> {
  late Future<List<dynamic>> _penerimaList;
  String _selectedKebutuhan = 'Semua';
  final List<String> _kebutuhanFilter = [
    'Semua',
    'Makanan',
    'Pakaian',
    'Alat Rumah Tangga',
    'Peralatan Sekolah',
    'Obat-obatan',
    'Peralatan Kerja',
  ];

  @override
  void initState() {
    super.initState();
    _loadPenerima();
  }

  void _loadPenerima() {
    _penerimaList = _fetchPenerima();
  }

  Future<List<dynamic>> _fetchPenerima() async {
    try {
      // Fetch semua donasi untuk melihat kebutuhan
      final donasi = await ApiService.getAllDonasi();

      // Extract unique penerima dari donasi
      Map<int, Map<String, dynamic>> penerimaMap = {};

      for (var d in donasi) {
        if (d['penerima_id'] != null) {
          penerimaMap.putIfAbsent(
            d['penerima_id'],
            () => {
              'id': d['penerima_id'],
              'nama': d['penerima_nama'] ?? 'Penerima',
              'alamat': d['penerima_alamat'] ?? '-',
              'kontak': d['penerima_kontak'] ?? '-',
              'kebutuhan': [],
            },
          );

          // Add kebutuhan jika ada
          if (d['penerima_kebutuhan'] != null &&
              !(penerimaMap[d['penerima_id']]!['kebutuhan'] as List).contains(
                d['penerima_kebutuhan'],
              )) {
            (penerimaMap[d['penerima_id']]!['kebutuhan'] as List).add(
              d['penerima_kebutuhan'],
            );
          }
        }
      }

      return penerimaMap.values.toList();
    } catch (e) {
      debugPrint('Error loading penerima: $e');
      return [];
    }
  }

  List<dynamic> _filterPenerima(List<dynamic> penerima) {
    if (_selectedKebutuhan == 'Semua') {
      return penerima;
    }
    return penerima.where((p) {
      List kebutuhan = p['kebutuhan'] ?? [];
      return kebutuhan.contains(_selectedKebutuhan);
    }).toList();
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
          'Daftar Penerima',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter Kebutuhan
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Berdasarkan Kebutuhan',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _kebutuhanFilter.map((kebutuhan) {
                      final isSelected = kebutuhan == _selectedKebutuhan;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(kebutuhan),
                          selected: isSelected,
                          backgroundColor: Colors.grey[200],
                          selectedColor: color.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          onSelected: (selected) {
                            setState(() => _selectedKebutuhan = kebutuhan);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Daftar Penerima
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _penerimaList,
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
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
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
                          Icons.person_outline,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada penerima',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                final filteredPenerima = _filterPenerima(snapshot.data!);

                if (filteredPenerima.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada penerima dengan kebutuhan $_selectedKebutuhan',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filteredPenerima.length,
                  itemBuilder: (context, index) {
                    final penerima = filteredPenerima[index];
                    final kebutuhan =
                        (penerima['kebutuhan'] as List?)?.join(', ') ?? '-';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.primary,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          penerima['nama'] ?? 'Penerima',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '📍 ${penerima['alamat'] ?? "-"}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '🎁 Kebutuhan: $kebutuhan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: color.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '📞 ${penerima['kontak'] ?? "-"}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
