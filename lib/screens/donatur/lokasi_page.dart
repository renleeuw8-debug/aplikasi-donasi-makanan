import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class LokasiPage extends StatefulWidget {
  const LokasiPage({super.key});

  @override
  State<LokasiPage> createState() => _LokasiPageState();
}

class _LokasiPageState extends State<LokasiPage> {
  List<Map<String, dynamic>> _lokasiList = [];
  bool _isLoading = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadLokasiList();
    _getCurrentLocation();
  }

  Future<void> _loadLokasiList() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/api/lokasi');
      if (response != null && response['success'] == true) {
        setState(() {
          _lokasiList = List<Map<String, dynamic>>.from(response['data'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading lokasi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.instance.getCurrentPosition();
      setState(() => _currentPosition = position);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  String _buildMapHtml(double latitude, double longitude) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { margin: 0; padding: 0; }
        iframe { width: 100%; height: 100%; border: none; }
      </style>
    </head>
    <body>
      <iframe src="https://www.google.com/maps?q=$latitude,$longitude&z=15&output=embed" allowfullscreen="" loading="lazy"></iframe>
    </body>
    </html>
    ''';
  }

  void _showLokasiDialog({Map<String, dynamic>? lokasi}) {
    final namaCtrl = TextEditingController(text: lokasi?['nama_lokasi'] ?? '');
    final alamatCtrl = TextEditingController(text: lokasi?['alamat'] ?? '');
    final deskCtrl = TextEditingController(text: lokasi?['deskripsi'] ?? '');

    double lat = lokasi?['latitude'] ?? _currentPosition?.latitude ?? 0;
    double lng = lokasi?['longitude'] ?? _currentPosition?.longitude ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lokasi == null ? 'Tambah Lokasi' : 'Edit Lokasi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Lokasi',
                  hintText: 'Contoh: Rumah, Kantor',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: alamatCtrl,
                decoration: const InputDecoration(labelText: 'Alamat'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: deskCtrl,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text(
                'Lokasi: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Gunakan Lokasi Saat Ini'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (namaCtrl.text.isEmpty || alamatCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama dan alamat harus diisi')),
                );
                return;
              }

              try {
                if (lokasi == null) {
                  // Create
                  final response = await ApiService.post('/api/lokasi', {
                    'nama_lokasi': namaCtrl.text,
                    'alamat': alamatCtrl.text,
                    'latitude': lat,
                    'longitude': lng,
                    'deskripsi': deskCtrl.text,
                  });
                  if (response != null && response['success'] == true) {
                    _loadLokasiList();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Lokasi berhasil ditambahkan'),
                      ),
                    );
                  }
                } else {
                  // Update
                  final response =
                      await ApiService.put('/api/lokasi/${lokasi['id']}', {
                        'nama_lokasi': namaCtrl.text,
                        'alamat': alamatCtrl.text,
                        'latitude': lat,
                        'longitude': lng,
                        'deskripsi': deskCtrl.text,
                      });
                  if (response != null && response['success'] == true) {
                    _loadLokasiList();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Lokasi berhasil diperbarui'),
                      ),
                    );
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
              }
            },
            child: Text(lokasi == null ? 'Tambah' : 'Perbarui'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Saya'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lokasiList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada lokasi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tambahkan lokasi donasi Anda untuk memudahkan',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _lokasiList.length,
              itemBuilder: (ctx, idx) {
                final lokasi = _lokasiList[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.location_on, color: Colors.white),
                    ),
                    title: Text(
                      lokasi['nama_lokasi'] ?? 'Lokasi',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      lokasi['alamat'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          child: const Text('Edit'),
                          onTap: () {
                            Future.delayed(
                              Duration.zero,
                              () => _showLokasiDialog(lokasi: lokasi),
                            );
                          },
                        ),
                        PopupMenuItem(
                          child: const Text('Hapus'),
                          onTap: () {
                            _deleteLokasiDialog(lokasi['id']);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () => _showLokasiDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _deleteLokasiDialog(int lokasiId) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Lokasi'),
        content: const Text('Apakah Anda yakin ingin menghapus lokasi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final response = await ApiService.delete(
                  '/api/lokasi/$lokasiId',
                );
                if (response != null && response['success'] == true) {
                  _loadLokasiList();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Lokasi berhasil dihapus')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
