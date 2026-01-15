import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'maps_display_page.dart';

class MapsExamplePage extends StatelessWidget {
  const MapsExamplePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contoh Google Maps'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Contoh 1: Tampil Maps Saja (View Only)
          Container(
            height: 300,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: WebViewWidget(
                controller: WebViewController()
                  ..setJavaScriptMode(JavaScriptMode.unrestricted)
                  ..loadHtmlString('''<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>body { margin: 0; padding: 0; } iframe { width: 100%; height: 100%; border: none; }</style>
</head>
<body>
  <iframe src="https://www.google.com/maps?q=-5.1400,119.4837&z=15&output=embed" allowfullscreen="" loading="lazy"></iframe>
</body>
</html>'''),
              ),
            ),
          ),

          // Tombol untuk contoh 2
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () =>
                  _showFullScreenMaps(context, allowSelection: false),
              icon: const Icon(Icons.map),
              label: const Text('Tampil Maps Full Screen (View)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tombol untuk contoh 3: Pilih Lokasi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () =>
                  _showFullScreenMaps(context, allowSelection: true),
              icon: const Icon(Icons.location_on),
              label: const Text('Pilih Lokasi di Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Informasi
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fitur Google Maps:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      '📍 Menampilkan Lokasi',
                      'Tampilkan peta dengan marker di lokasi tertentu',
                    ),
                    _buildFeatureItem(
                      '🎯 Pilih Lokasi',
                      'User dapat mengetuk peta untuk memilih lokasi baru',
                    ),
                    _buildFeatureItem(
                      '📡 GPS Auto-Detect',
                      'Otomatis mendeteksi lokasi GPS device user',
                    ),
                    _buildFeatureItem(
                      '🗺️ Zoom & Pan',
                      'Fitur zoom in/out dan pan/scroll built-in',
                    ),
                    _buildFeatureItem(
                      '📌 Info Window',
                      'Menampilkan informasi saat marker di-tap',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _showFullScreenMaps(
    BuildContext context, {
    required bool allowSelection,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapsDisplayPage(
          title: allowSelection ? 'Pilih Lokasi Donasi' : 'Peta Lokasi',
          initialLatitude: -5.1400,
          initialLongitude: 119.4837,
          allowSelection: allowSelection,
        ),
      ),
    );

    if (allowSelection && result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi terpilih'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
