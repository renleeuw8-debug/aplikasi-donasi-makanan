import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/donasi_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class DonasiMapScreen extends StatefulWidget {
  const DonasiMapScreen({super.key});

  @override
  State<DonasiMapScreen> createState() => _DonasiMapScreenState();
}

class _DonasiMapScreenState extends State<DonasiMapScreen> {
  String _selectedKategori = 'Semua';
  Position? _userLocation;
  List<DonasiModel> _donasiList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadDonasiData();
  }

  Future<void> _initLocation() async {
    final pos = await LocationService.instance.getCurrentPosition();
    if (mounted) {
      setState(() {
        _userLocation = pos;
      });
    }
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

  /// Hitung jarak dari user ke donasi (dalam km)
  double _calculateDistance(DonasiModel donasi) {
    if (_userLocation == null) return 0;

    return LocationService.instance.calculateDistance(
          _userLocation!.latitude,
          _userLocation!.longitude,
          donasi.lokasi?.latitude ?? 0,
          donasi.lokasi?.longitude ?? 0,
        ) /
        1000; // Convert to km
  }

  /// Format jarak untuk tampilkan
  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toStringAsFixed(0)} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  void _showDonasiDetail(DonasiModel d) {
    final jarak = _calculateDistance(d);
    final jarakText = _formatDistance(jarak);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
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
            if (d.deskripsi != null) ...[
              const SizedBox(height: 8),
              Text(d.deskripsi!),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(label: Text('Jumlah: ${d.jumlah}')),
                const SizedBox(width: 8),
                Chip(label: Text('Status: ${d.status}')),
              ],
            ),
            const SizedBox(height: 12),
            Chip(
              label: Text('📍 Jarak: $jarakText'),
              backgroundColor: Colors.blue.shade100,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur hubungi donatur akan ditambahkan.'),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Hubungi Donatur'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📍 Donasi GPS')),
      body: _userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter chips
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _KategoriChips(
                    selected: _selectedKategori,
                    onSelected: (value) {
                      setState(() => _selectedKategori = value);
                    },
                  ),
                ),
                // Lokasi user
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.my_location, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lokasi Kamu:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${_userLocation!.latitude.toStringAsFixed(4)}, '
                                  '${_userLocation!.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Donasi list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadDonasiData,
                    child: _getFilteredDonasi().isEmpty
                        ? const Center(child: Text('Tidak ada donasi tersedia'))
                        : ListView.builder(
                            itemCount: _getFilteredDonasi().length,
                            itemBuilder: (context, index) {
                              final donasi = _getFilteredDonasi()[index];
                              final jarak = _calculateDistance(donasi);
                              final jarakText = _formatDistance(jarak);

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: ListTile(
                                  title: Text(donasi.namaDonasi ?? 'Unknown'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        '📍 $jarakText',
                                        style: const TextStyle(
                                          color: Colors.teal,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${donasi.kategori} • ${donasi.status}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Chip(
                                    label: Text('${donasi.jumlah}x'),
                                    backgroundColor: Colors.teal.shade100,
                                  ),
                                  onTap: () => _showDonasiDetail(donasi),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _KategoriChips extends StatelessWidget {
  const _KategoriChips({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  static const List<String> _items = <String>[
    'Semua',
    'Makanan',
    'Pakaian',
    'Barang Bekas',
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _items.map((e) {
              final sel = e == selected;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(e),
                  selected: sel,
                  onSelected: (_) => onSelected(e),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
