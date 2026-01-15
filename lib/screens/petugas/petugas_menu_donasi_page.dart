import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

import '../../services/api_service.dart';
import 'verifikasi_donasi_page.dart';

class PetugasMenuDonasiPage extends StatefulWidget {
  const PetugasMenuDonasiPage({super.key});

  @override
  State<PetugasMenuDonasiPage> createState() => _PetugasMenuDonasiPageState();
}

class _PetugasMenuDonasiPageState extends State<PetugasMenuDonasiPage> {
  Position? _currentLocation;
  final double _radiusKm = 5.0;
  late Future<List<dynamic>> _donasiList;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    // Fetch donasi menunggu verifikasi dari endpoint khusus petugas
    _donasiList = ApiService.getDonasiMenungguVerifikasi();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) setState(() => _currentLocation = position);
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: color.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Menu Donasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<dynamic>>(
              future: _donasiList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada donasi tersedia',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allDonasi = snapshot.data!;

                // Calculate distances (semua sudah status 'menunggu' dari backend)
                final nearby = allDonasi.map((donasi) {
                  double distance = 999;
                  try {
                    if (donasi['lokasi'] != null) {
                      distance = _calculateDistance(
                        _currentLocation!.latitude,
                        _currentLocation!.longitude,
                        donasi['lokasi']['latitude'] ?? 0,
                        donasi['lokasi']['longitude'] ?? 0,
                      );
                    }
                  } catch (e) {
                    debugPrint('Distance calc error: $e');
                  }

                  return {...donasi, 'distance': distance};
                }).toList();

                // Sort by distance
                nearby.sort(
                  (a, b) =>
                      (a['distance'] as num).compareTo(b['distance'] as num),
                );

                if (nearby.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada donasi dalam jangkauan',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: nearby.length,
                  itemBuilder: (context, index) {
                    final donasi = nearby[index];
                    final distance = donasi['distance'] as double;
                    final isWithinRadius = distance <= _radiusKm;

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
                              Icons.local_dining,
                              color: color.primary,
                            ),
                          ),
                        ),
                        title: Text(
                          donasi['nama_barang'] ?? 'Donasi',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Qty: ${donasi['jumlah'] ?? 0} | Jarak: ${distance.toStringAsFixed(2)} km',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (!isWithinRadius)
                              Text(
                                'Di luar jangkauan ${_radiusKm}km',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => VerifikasiDonasiPage(
                                  donasi: donasi.cast<String, dynamic>(),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            'Verifikasi',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                        enabled: true,
                        onTap: null,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
