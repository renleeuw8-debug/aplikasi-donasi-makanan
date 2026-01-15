import 'package:flutter/material.dart';
import '../../models/donasi_model.dart';
import '../../services/api_service.dart';

class RiwayatDonasiPenerimaPage extends StatefulWidget {
  const RiwayatDonasiPenerimaPage({super.key});

  @override
  State<RiwayatDonasiPenerimaPage> createState() =>
      _RiwayatDonasiPenerimaPageState();
}

class _RiwayatDonasiPenerimaPageState extends State<RiwayatDonasiPenerimaPage> {
  List<DonasiModel> _allDonasi = [];
  List<DonasiModel> _filteredDonasi = [];
  String _selectedFilter = 'semua';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDonasi();
  }

  Future<void> _loadDonasi() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getMyDonasi();
      if (response['success'] == true) {
        final dataList = response['data'] as List;
        final donasi = dataList.map((d) => DonasiModel.fromJson(d)).toList();

        if (mounted) {
          setState(() {
            _allDonasi = donasi;
            _applyFilter();
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

  void _applyFilter() {
    if (_selectedFilter == 'semua') {
      _filteredDonasi = _allDonasi;
    } else {
      _filteredDonasi = _allDonasi
          .where((d) => (d.status ?? 'pending') == _selectedFilter)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📜 Riwayat Donasi')),
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Semua',
                  selected: _selectedFilter == 'semua',
                  onTap: () {
                    setState(() {
                      _selectedFilter = 'semua';
                      _applyFilter();
                    });
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Diterima',
                  selected: _selectedFilter == 'diterima',
                  onTap: () {
                    setState(() {
                      _selectedFilter = 'diterima';
                      _applyFilter();
                    });
                  },
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Diverifikasi',
                  selected: _selectedFilter == 'diverifikasi',
                  onTap: () {
                    setState(() {
                      _selectedFilter = 'diverifikasi';
                      _applyFilter();
                    });
                  },
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Menunggu',
                  selected: _selectedFilter == 'menunggu',
                  onTap: () {
                    setState(() {
                      _selectedFilter = 'menunggu';
                      _applyFilter();
                    });
                  },
                  color: Colors.orange,
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDonasi.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada riwayat donasi',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredDonasi.length,
                    itemBuilder: (context, index) {
                      final donasi = _filteredDonasi[index];
                      return _DonasiHistoryCard(donasi: donasi);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Filter Chip
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: selected ? chipColor.withOpacity(0.2) : null,
      side: BorderSide(color: selected ? chipColor : Colors.grey.shade300),
    );
  }
}

/// Donasi History Card
class _DonasiHistoryCard extends StatelessWidget {
  final DonasiModel donasi;

  const _DonasiHistoryCard({required this.donasi});

  @override
  Widget build(BuildContext context) {
    final status = donasi.status ?? 'pending';
    final statusColor =
        {
          'diterima': Colors.green,
          'pending': Colors.orange,
          'ditolak': Colors.red,
          'tersedia': Colors.blue,
          'diambil': Colors.blue,
          'selesai': Colors.green,
        }[status] ??
        Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donasi.namaDonasi ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dari: ${donasi.namaPenerima ?? 'Unknown'}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    fontSize: 13,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category & Quantity - Full Width
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      donasi.kategori ?? 'Umum',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '📦 ${donasi.jumlah} item',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(donasi.tanggalUpload),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),

          // Description - Full Display
          if (donasi.deskripsi != null && donasi.deskripsi!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                donasi.deskripsi!,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Action Button
          if (status == 'pending' || status == 'tersedia')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to confirmation page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur konfirmasi penerimaan segera hadir'),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Konfirmasi Penerimaan'),
              ),
            )
          else if (status == 'diterima' || status == 'selesai')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Sudah dikonfirmasi',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else if (status == 'ditolak')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, color: Colors.red, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Ditolak',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getStatusLabel(String? status) {
    final labels = {
      'pending': 'Menunggu',
      'tersedia': 'Tersedia',
      'diambil': 'Diambil',
      'selesai': 'Selesai',
      'diterima': 'Diterima',
      'ditolak': 'Ditolak',
    };
    return labels[status] ?? status ?? 'Unknown';
  }

  String _formatDate(dynamic dateData) {
    if (dateData == null) return 'Tanggal Tidak Diketahui';

    try {
      final date = dateData is DateTime
          ? dateData
          : dateData is String
          ? DateTime.parse(dateData)
          : DateTime.now();

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Tanggal Tidak Diketahui';
    }
  }
}
