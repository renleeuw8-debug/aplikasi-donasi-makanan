import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/penerima_model.dart';

class PenerimaService {
  FirebaseFirestore? _firestore;
  bool _firebaseAvailable = true;
  
  PenerimaService() {
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      _firebaseAvailable = false;
      print('Firebase not initialized: $e');
    }
  }

  // Collection reference - will throw if Firebase not available
  CollectionReference<Map<String, dynamic>> get _penerimaCollection {
    if (!_firebaseAvailable || _firestore == null) {
      throw Exception('Firebase not initialized. Please use backend API instead of PenerimaService.');
    }
    return _firestore!.collection('penerima');
  }

  /// Create new Penerima record
  Future<String> createPenerima(PenerimaModel penerima) async {
    try {
      final docRef = await _penerimaCollection.add(penerima.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Error creating penerima: $e');
    }
  }

  /// Get single Penerima by ID
  Future<PenerimaModel?> getPenerimaById(String penerimaId) async {
    try {
      final doc = await _penerimaCollection.doc(penerimaId).get();
      if (doc.exists) {
        return PenerimaModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting penerima: $e');
    }
  }

  /// Get Penerima by userId (Firebase Auth UID)
  Future<PenerimaModel?> getPenerimaByUserId(String userId) async {
    try {
      final query = await _penerimaCollection
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return PenerimaModel.fromSnapshot(query.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting penerima by userId: $e');
    }
  }

  /// Get all active Penerima (pagination supported)
  Future<List<PenerimaModel>> getAllPenerima({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _penerimaCollection
          .where('status', isEqualTo: 'aktif')
          .orderBy('tanggal_daftar', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final docs = await query.get();
      return docs.docs.map((doc) => PenerimaModel.fromSnapshot(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching penerima list: $e');
    }
  }

  /// Get Penerima nearby (within X km radius)
  /// Default 5 km radius
  Future<List<PenerimaModel>> getPenerimaNearby({
    required double latitude,
    required double longitude,
    double radiusInKm = 5.0,
  }) async {
    try {
      final allPenerima = await _penerimaCollection
          .where('status', isEqualTo: 'aktif')
          .get();

      final nearby = <PenerimaModel>[];

      for (final doc in allPenerima.docs) {
        final penerima = PenerimaModel.fromSnapshot(doc);
        final distance = _calculateDistance(
          latitude,
          longitude,
          penerima.lokasi.latitude,
          penerima.lokasi.longitude,
        );

        if (distance <= radiusInKm) {
          nearby.add(penerima);
        }
      }

      // Sort by distance (nearest first)
      nearby.sort((a, b) {
        final distA = _calculateDistance(
          latitude,
          longitude,
          a.lokasi.latitude,
          a.lokasi.longitude,
        );
        final distB = _calculateDistance(
          latitude,
          longitude,
          b.lokasi.latitude,
          b.lokasi.longitude,
        );
        return distA.compareTo(distB);
      });

      return nearby;
    } catch (e) {
      throw Exception('Error fetching nearby penerima: $e');
    }
  }

  /// Update Penerima data
  Future<void> updatePenerima(String penerimaId, PenerimaModel penerima) async {
    try {
      await _penerimaCollection.doc(penerimaId).update(penerima.toJson());
    } catch (e) {
      throw Exception('Error updating penerima: $e');
    }
  }

  /// Update specific fields
  Future<void> updatePenerimaFields(
    String penerimaId,
    Map<String, dynamic> fields,
  ) async {
    try {
      await _penerimaCollection.doc(penerimaId).update(fields);
    } catch (e) {
      throw Exception('Error updating penerima fields: $e');
    }
  }

  /// Delete Penerima (soft delete - set status to inactive)
  Future<void> deletePenerima(String penerimaId) async {
    try {
      await _penerimaCollection.doc(penerimaId).update({
        'status': 'tidak_aktif',
      });
    } catch (e) {
      throw Exception('Error deleting penerima: $e');
    }
  }

  /// Search Penerima by name
  Future<List<PenerimaModel>> searchPenerimaByName(String query) async {
    try {
      final results = await _penerimaCollection
          .where('status', isEqualTo: 'aktif')
          .orderBy('nama')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .get();

      return results.docs
          .map((doc) => PenerimaModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Error searching penerima: $e');
    }
  }

  /// Get Penerima with specific needs
  Future<List<PenerimaModel>> getPenerimaByNeeds(List<String> kebutuhan) async {
    try {
      final results = await _penerimaCollection
          .where('status', isEqualTo: 'aktif')
          .where('kebutuhan', arrayContainsAny: kebutuhan)
          .get();

      return results.docs
          .map((doc) => PenerimaModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching penerima by needs: $e');
    }
  }

  /// Increment total donation counter
  Future<void> incrementDonasiCounter(String penerimaId) async {
    try {
      await _penerimaCollection.doc(penerimaId).update({
        'total_donasi_diterima': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Error incrementing donation counter: $e');
    }
  }

  /// Update Penerima status (aktif, tidak_aktif, terverifikasi)
  Future<void> updateStatus(String penerimaId, String status) async {
    try {
      final update = {
        'status': status,
        if (status == 'terverifikasi') 'tanggal_verifikasi': Timestamp.now(),
      };
      await _penerimaCollection.doc(penerimaId).update(update);
    } catch (e) {
      throw Exception('Error updating status: $e');
    }
  }

  /// Calculate distance between two coordinates (Haversine formula)
  /// Returns distance in kilometers
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

  /// Convert degrees to radians
  double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }

  /// Listen to all Penerima changes in real-time
  Stream<List<PenerimaModel>> getAllPenerimaStream() {
    return _penerimaCollection
        .where('status', isEqualTo: 'aktif')
        .orderBy('tanggal_daftar', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PenerimaModel.fromSnapshot(doc))
              .toList();
        });
  }

  /// Listen to single Penerima changes
  Stream<PenerimaModel?> getPenerimaStreamById(String penerimaId) {
    return _penerimaCollection.doc(penerimaId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return PenerimaModel.fromSnapshot(snapshot);
      }
      return null;
    });
  }
}
