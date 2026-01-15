import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/api_service.dart';
import '../../widgets/panti_asuhan_registration_field.dart';

class RegisterPenerimaPage extends StatefulWidget {
  const RegisterPenerimaPage({super.key});

  @override
  State<RegisterPenerimaPage> createState() => _RegisterPenerimaPageState();
}

class _RegisterPenerimaPageState extends State<RegisterPenerimaPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _kontakCtrl = TextEditingController();
  final _pantiCtrl = TextEditingController(); // Fitur 3: Panti Asuhan

  bool _obscure = true;
  bool _obscure2 = true;
  bool _loading = false;
  bool _locationLoading = false;

  double? _latitude = -5.1395119;
  double? _longitude = 119.4851;
  String? _locationLabel = '📍 -5.1395, 119.4851';
  Set<String> _selectedKebutuhan = {};
  late WebViewController _mapController;

  // List kebutuhan options
  final List<String> _kebutuhanOptions = [
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
    _initializeMap();
  }

  void _initializeMap() {
    _mapController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_buildMapHtml());
  }

  String _buildMapHtml() {
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
      <iframe src="https://www.google.com/maps?q=${_latitude ?? -5.1395119},${_longitude ?? 119.4851}&z=15&output=embed" allowfullscreen="" loading="lazy"></iframe>
    </body>
    </html>
    ''';
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _alamatCtrl.dispose();
    _kontakCtrl.dispose();
    _pantiCtrl.dispose(); // Fitur 3: Dispose panti controller
    super.dispose();
  }

  /// Get current location using geolocator
  Future<void> _getCurrentLocation() async {
    setState(() => _locationLoading = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin lokasi ditolak')),
            );
          }
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationLabel =
            '📍 ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        // Reload map with new coordinates
        _mapController.loadHtmlString(_buildMapHtml());
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lokasi berhasil diambil')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _registerPenerima() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih lokasi terlebih dahulu')),
      );
      return;
    }
    if (_selectedKebutuhan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih minimal satu kebutuhan')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // Register to MySQL backend
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim(),
          'password': _passCtrl.text,
          'password_confirm': _confirmCtrl.text,
          'nama': _namaCtrl.text.trim(),
          'role': 'penerima',
          'alamat': _alamatCtrl.text.trim(),
          'kontak': _kontakCtrl.text.trim(),
          'latitude': _latitude,
          'longitude': _longitude,
          'kebutuhan': _selectedKebutuhan.toList(),
          'nama_panti_asuhan': _pantiCtrl.text.trim().isEmpty
              ? null
              : _pantiCtrl.text.trim(), // Fitur 3
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi berhasil! Silakan login.')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Gagal mendaftar');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal daftar: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Sebagai Penerima')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '🏘️ Daftar Penerima Donasi',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lengkapi data diri Anda untuk menerima donasi dari donatur',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _namaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'Masukkan nama lengkap Anda',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                  hintText: 'example@email.com',
                ),
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Email tidak valid'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  helperText: 'Min. 6 karakter',
                ),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Min. 6 karakter' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscure2,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure2 ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                  ),
                ),
                validator: (v) =>
                    (v != _passCtrl.text) ? 'Password tidak sama' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alamatCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alamat Lengkap',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  hintText: 'Jl. ... No. ...',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kontakCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor Kontak (WhatsApp)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+62...',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              // Fitur 3: Panti Asuhan Field
              PantiAshuanRegistrationField(
                controller: _pantiCtrl,
                isRequired: false,
              ),
              const SizedBox(height: 24),

              // Location Picker
              const SizedBox(height: 8),

              const SizedBox(height: 12),
              const SizedBox(height: 24),
              // Kebutuhan Selection
              Text(
                'Pilih Kebutuhan Anda',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kebutuhanOptions
                    .where((k) => k.isNotEmpty) // Filter out empty items
                    .map((kebutuhan) {
                      final isSelected = _selectedKebutuhan.contains(kebutuhan);
                      return FilterChip(
                        label: Text(
                          kebutuhan,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        selected: isSelected,
                        backgroundColor: Colors.grey[200],
                        selectedColor: Theme.of(context).colorScheme.primary,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedKebutuhan.add(kebutuhan);
                            } else {
                              _selectedKebutuhan.remove(kebutuhan);
                            }
                          });
                        },
                      );
                    })
                    .toList(),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: _locationLoading ? null : _getCurrentLocation,
                icon: _locationLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: const Text('Gunakan Lokasi Saat Ini'),
              ),
              const SizedBox(height: 32),

              // Preview Lokasi - Dipindahkan ke bawah
              if (_latitude != null && _longitude != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview Lokasi Anda',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 200,
                          child: WebViewWidget(controller: _mapController),
                        ),
                      ),
                    ],
                  ),
                ),

              FilledButton(
                onPressed: _loading ? null : _registerPenerima,
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Daftar Sebagai Penerima'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sudah punya akun?'),
                  TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    child: const Text('Masuk'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
