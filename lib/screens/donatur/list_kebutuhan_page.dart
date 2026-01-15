import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'donasi_untuk_kebutuhan_page.dart';

class ListKebutuhanPage extends StatefulWidget {
  const ListKebutuhanPage({super.key});

  @override
  State<ListKebutuhanPage> createState() => _ListKebutuhanPageState();
}

class _ListKebutuhanPageState extends State<ListKebutuhanPage> {
  late Future<List<dynamic>> _kebutuhanList;
  String _selectedFilter = 'semua';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (_selectedFilter == 'semua') {
      _kebutuhanList = ApiService.getAllKebutuhan(status: 'aktif');
    } else {
      _kebutuhanList = ApiService.getAllKebutuhan(status: _selectedFilter);
    }
  }

  void _refreshData() {
    setState(() {
      _loadData();
    });
  }

  Color _getColorForJenis(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'makanan':
        return Colors.orange;
      case 'pakaian':
        return Colors.pink;
      case 'buku':
        return Colors.purple;
      case 'kesehatan':
        return Colors.red;
      case 'barang':
        return Colors.blue;
      case 'lainnya':
        return Colors.grey;
      default:
        return Colors.blue;
    }
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
          'Kebutuhan Penerima',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Filter
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Semua',
                    value: 'semua',
                    color: color.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: '🍚 Makanan',
                    value: 'makanan',
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: '📦 Barang',
                    value: 'barang',
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),

          // List Kebutuhan
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _kebutuhanList,
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
                          'Tidak ada kebutuhan aktif',
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
                              color: _getColorForJenis(
                                kebutuhan['jenis_kebutuhan'],
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                _getIconForJenis(kebutuhan['jenis_kebutuhan']),
                                color: _getColorForJenis(
                                  kebutuhan['jenis_kebutuhan'],
                                ),
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
                                'Penerima: ${kebutuhan['penerima_nama'] ?? 'Unknown'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dibutuhkan: ${kebutuhan['jumlah'] ?? 0}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color.primary,
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DonasiUntukKebutuhanPage(
                                  kebutuhan: kebutuhan,
                                ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required Color color,
  }) {
    final isSelected = _selectedFilter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _loadData();
        });
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: color.withOpacity(0.3),
      side: BorderSide(
        color: isSelected ? color : Colors.transparent,
        width: 2,
      ),
    );
  }
}
