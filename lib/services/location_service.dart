import 'package:geolocator/geolocator.dart';
import 'dart:async';

/// Service untuk GPS Location (Latitude & Longitude)
/// Platform Support: Android ✅ | iOS ✅ | Web ✅
/// NO Google Cloud, NO Google Maps API - 100% GRATIS
class LocationService {
  LocationService._();
  static final instance = LocationService._();

  /// Cek & request permission lokasi
  /// Return true jika permission granted
  Future<bool> ensurePermission() async {
    // Cek apakah location service enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ Location service disabled');
      return false;
    }

    // Cek permission
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Accept jika always atau whileInUse
    final hasPermission = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (!hasPermission) {
      print('❌ Location permission denied: $permission');
    }
    return hasPermission;
  }

  /// Ambil lokasi GPS saat ini (sekali)
  /// Return: Position(latitude, longitude) atau null jika gagal
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPerm = await ensurePermission();
      if (!hasPerm) {
        print('⚠️ Permission tidak granted');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );

      print('✅ GPS Success: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Error getting position: $e');
      return null;
    }
  }

  /// Stream lokasi real-time (terus update)
  /// Berguna untuk tracking lokasi user yang bergerak
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // Update jika bergerak 10 meter
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Hitung jarak antara 2 lokasi (dalam meter)
  /// Berguna untuk menghitung jarak donasi ke lokasi user
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Format jarak ke string yang lebih readable
  /// Contoh: 1500m → "1.5 km", 500m → "500 m"
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Hitung bearing (arah) dari satu lokasi ke lokasi lain
  double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.bearingBetween(lat1, lon1, lat2, lon2);
  }
}
