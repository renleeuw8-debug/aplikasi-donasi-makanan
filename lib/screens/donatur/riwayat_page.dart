import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  late Future<List<dynamic>> _riwayatList;

  @override
  void initState() {
    super.initState();
    _riwayatList = _fetchRiwayat();
  }

  Future<List<dynamic>> _fetchRiwayat() async {
    final result = await ApiService.getMyDonasi();
    if (result['success']) {
      return result['data'] ?? [];
    } else {
      throw result['message'] ?? 'Gagal mengambil data riwayat';
    }
  }

  String _getStatusColor(String status) {
    switch (status?.toLowerCase()) {
      case 'menunggu':
        return '⏳ Menunggu Verifikasi';
      case 'diverifikasi':
        return '✅ Diverifikasi';
      case 'diterima':
        return '🙌 Diterima Penerima';
      case 'selesai':
        return '🎉 Selesai';
      case 'dibatalkan':
        return '❌ Dibatalkan';
      default:
        return status ?? 'Unknown';
    }
  }

  Color _getStatusColorValue(String status) {
    switch (status?.toLowerCase()) {
      case 'menunggu':
        return Colors.orange;
      case 'diverifikasi':
        return Colors.blue;
      case 'diterima':
        return Colors.green;
      case 'selesai':
        return Colors.purple;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Donasi Saya'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _riwayatList,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${snap.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _riwayatList = _fetchRiwayat();
                      });
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat donasi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mulai berbagi kebaikan dengan upload donasi',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final d = items[i];
              final status = d['status'] ?? 'pending';
              final statusText = _getStatusColor(status);
              final statusColor = _getStatusColorValue(status);

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['nama_barang'] ?? 'Donasi',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  d['jenis_donasi'] ?? 'Unknown',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(statusText),
                            backgroundColor: statusColor.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            icon: Icons.inventory_2,
                            label: '${d['jumlah'] ?? 0}x',
                          ),
                          _InfoChip(
                            icon: Icons.calendar_today,
                            label: _formatDate(d['created_at']),
                          ),
                          if (d['deskripsi'] != null)
                            _InfoChip(
                              icon: Icons.description,
                              label: d['deskripsi'],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      if (date is String) {
        final parsed = DateTime.tryParse(date);
        if (parsed != null) {
          return '${parsed.day}/${parsed.month}/${parsed.year}';
        }
      }
      return date.toString();
    } catch (e) {
      return '-';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
