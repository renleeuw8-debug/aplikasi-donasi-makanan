import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ApiService {
  // ===== NETWORK CONFIGURATION =====
  // Uncomment salah satu sesuai network yang dipakai

  // HOTSPOT HP (10.45.78.160)
  static const String baseUrl = 'http://10.45.78.160:3000/api';

  // WiFi HOME (192.168.100.9)
  // static const String baseUrl = 'http://192.168.100.9:3000/api';

  static String? _token;

  static String? get token => _token;

  static void initToken() {
    // Token diload dari memory saat login
  }

  static Future<void> setToken(String token) async {
    _token = token;
  }

  static Future<void> clearToken() async {
    _token = null;
  }

  // Auth - Register
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String nama,
    String? noHp,
    String? alamat,
    String role = 'donatur',
    double? latitude,
    double? longitude,
    String? namaPantiAsuhan,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'password_confirm': password,
          'nama': nama,
          'no_hp': noHp,
          'alamat': alamat,
          'role': role,
          'latitude': latitude,
          'longitude': longitude,
          'nama_panti_asuhan': namaPantiAsuhan,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message':
              jsonDecode(response.body)['message'] ?? 'Register berhasil',
          'userId': jsonDecode(response.body)['userId'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Register gagal',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Auth - Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        if (token != null) {
          _token = token;
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Login berhasil',
          'token': token,
          'user': data['user'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Login gagal',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Auth - Get User Profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (_token == null) {
        print('No token available');
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        print('Get profile failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  // Donasi - Create donasi baru
  static Future<Map<String, dynamic>> createDonasi({
    required String nama,
    required String kategori,
    String? deskripsi,
    int? jumlah,
    String? satuan,
    File? fotoFile,
    double? latitude,
    double? longitude,
    String? alamat,
  }) async {
    if (_token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login terlebih dahulu.',
      };
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/donasi'));

      // Add headers
      request.headers['Authorization'] = 'Bearer $_token';

      // Add fields
      request.fields['nama_barang'] = nama;
      request.fields['jenis_donasi'] = kategori;
      if (deskripsi != null) request.fields['deskripsi'] = deskripsi;
      if (jumlah != null) request.fields['jumlah'] = jumlah.toString();
      if (satuan != null) request.fields['satuan'] = satuan;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
      if (alamat != null) request.fields['alamat'] = alamat;

      // Add file if provided
      if (fotoFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('foto_donasi', fotoFile.path),
        );
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': jsonData['message'] ?? 'Donasi berhasil diunggah!',
          'donasiId': jsonData['donasiId'],
        };
      } else {
        return {
          'success': false,
          'message': jsonData['message'] ?? 'Gagal mengunggah donasi',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Donasi - Get donasi saya (untuk riwayat)
  static Future<Map<String, dynamic>> getMyDonasi() async {
    if (_token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login terlebih dahulu.',
      };
    }

    try {
      // Fetch semua donasi milik user (otomatis filter di backend)
      final response = await http.get(
        Uri.parse('$baseUrl/donasi'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? []};
      } else {
        return {'success': false, 'message': 'Gagal mengambil data donasi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Donasi - Get semua donasi tersedia
  static Future<Map<String, dynamic>> getDonasi({String? kategori}) async {
    try {
      String url = '$baseUrl/donasi';
      if (kategori != null) {
        url += '?kategori=$kategori';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? []};
      } else {
        return {'success': false, 'message': 'Gagal mengambil data donasi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Donasi - Get semua donasi sebagai List (untuk dashboard petugas)
  static Future<List<dynamic>> getAllDonasi({String? status}) async {
    try {
      String url = '$baseUrl/donasi';
      if (status != null) {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('getAllDonasi error: $e');
      return [];
    }
  }

  // Petugas - Get pending donations
  static Future<Map<String, dynamic>> getPendingDonasi() async {
    if (_token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login terlebih dahulu.',
      };
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/donasi/pending'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? []};
      } else {
        return {'success': false, 'message': 'Gagal mengambil donasi pending'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Petugas - Get donations waiting for verification
  static Future<List<dynamic>> getDonasiMenungguVerifikasi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/donasi/verify/menunggu'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      debugPrint(
        'getDonasiMenungguVerifikasi - Status: ${response.statusCode}',
      );
      debugPrint('getDonasiMenungguVerifikasi - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        debugPrint(
          'getDonasiMenungguVerifikasi error: Status ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('getDonasiMenungguVerifikasi exception: $e');
      return [];
    }
  }

  // Petugas - Get donations already verified (riwayat)
  static Future<List<dynamic>> getDonasiSudahDiverifikasi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/donasi/verify/diverifikasi'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      debugPrint('getDonasiSudahDiverifikasi - Status: ${response.statusCode}');
      debugPrint('getDonasiSudahDiverifikasi - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        debugPrint(
          'getDonasiSudahDiverifikasi error: Status ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('getDonasiSudahDiverifikasi exception: $e');
      return [];
    }
  }

  // Penerima - Receive donasi (klaim donasi)
  static Future<List<dynamic>> getDonasiSayaMenunggu() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/donasi/my/menunggu'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      debugPrint('getDonasiSayaMenunggu - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        debugPrint(
          'getDonasiSayaMenunggu error: Status ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('getDonasiSayaMenunggu exception: $e');
      return [];
    }
  }

  // Donatur - Get donasi yang sudah diverifikasi
  static Future<List<dynamic>> getDonasiSayaDiverifikasi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/donasi/my/diverifikasi'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      debugPrint('getDonasiSayaDiverifikasi - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        debugPrint(
          'getDonasiSayaDiverifikasi error: Status ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('getDonasiSayaDiverifikasi exception: $e');
      return [];
    }
  }

  // Penerima - Receive donasi (klaim donasi)
  static Future<Map<String, dynamic>> receiveDonasi({
    required int donasiId,
  }) async {
    if (_token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login terlebih dahulu.',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/donasi/$donasiId/receive'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Donasi berhasil diterima',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Gagal menerima donasi',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Petugas - Update donasi status
  static Future<Map<String, dynamic>> updateDonasiStatus({
    required int donasiId,
    required String status,
    String? catatan,
    int? penerimaId,
  }) async {
    if (_token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login terlebih dahulu.',
      };
    }

    try {
      debugPrint('=== updateDonasiStatus ===');
      debugPrint('URL: $baseUrl/donasi/$donasiId/status');
      debugPrint(
        'Body: {status: $status, catatan: $catatan, penerima_id: $penerimaId}',
      );

      final body = {
        'status': status,
        if (catatan != null) 'catatan': catatan,
        if (penerimaId != null) 'penerima_id': penerimaId,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/donasi/$donasiId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(body),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Status donasi berhasil diupdate',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              errorData['message'] ??
              'Gagal mengupdate status donasi (${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('updateDonasiStatus exception: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Generic GET request
  static Future<Map<String, dynamic>?> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('GET $endpoint failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('GET Error: $e');
      return null;
    }
  }

  // Generic POST request
  static Future<Map<String, dynamic>?> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print('POST $endpoint failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('POST Error: $e');
      return null;
    }
  }

  // Generic PUT request
  static Future<Map<String, dynamic>?> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('PUT $endpoint failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('PUT Error: $e');
      return null;
    }
  }

  // Generic DELETE request
  static Future<Map<String, dynamic>?> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('DELETE $endpoint failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('DELETE Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? nama,
    String? no_hp,
    String? alamat,
  }) async {
    if (_token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login terlebih dahulu.',
      };
    }

    try {
      final body = {
        if (nama != null) 'nama': nama,
        if (no_hp != null) 'no_hp': no_hp,
        if (alamat != null) 'alamat': alamat,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Profil berhasil diperbarui',
          'data': jsonDecode(response.body)['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Gagal memperbarui profil',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Statistics - Get jumlah donatur dan statistik lainnya
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/statistics'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? {}};
      } else {
        return {'success': false, 'message': 'Gagal mengambil statistik'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ========== KEBUTUHAN PENERIMA ==========

  static Future<List<dynamic>> getAllKebutuhan({String? status}) async {
    if (_token == null) {
      return [];
    }

    try {
      String url = '$baseUrl/kebutuhan';
      if (status != null) {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting kebutuhan: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getKebutuhanById(int id) async {
    if (_token == null) {
      return {'success': false, 'message': 'Token tidak ditemukan'};
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/kebutuhan/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? {}};
      } else {
        return {'success': false, 'message': 'Kebutuhan tidak ditemukan'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> createKebutuhanWithPhoto({
    required String jenisKebutuhan,
    required String deskripsi,
    required int jumlah,
    File? fotoFile,
  }) async {
    if (_token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login terlebih dahulu.',
      };
    }

    try {
      debugPrint('=== createKebutuhanWithPhoto ===');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/kebutuhan'),
      );

      request.headers['Authorization'] = 'Bearer $_token';
      request.fields['jenis_kebutuhan'] = jenisKebutuhan;
      request.fields['deskripsi'] = deskripsi;
      request.fields['jumlah'] = jumlah.toString();

      if (fotoFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('foto_kebutuhan', fotoFile.path),
        );
        debugPrint('File added: ${fotoFile.path}');
      }

      debugPrint('Sending request...');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: $responseBody');

      if (response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        return {
          'success': true,
          'message': data['message'] ?? 'Kebutuhan berhasil dibuat',
          'data': data['data'],
        };
      } else {
        final errorData = jsonDecode(responseBody);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Gagal membuat kebutuhan',
        };
      }
    } catch (e) {
      debugPrint('createKebutuhanWithPhoto exception: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> createKebutuhan({
    required String jenisKebutuhan,
    required String deskripsi,
    required int jumlah,
  }) async {
    if (_token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login terlebih dahulu.',
      };
    }

    try {
      debugPrint('=== createKebutuhan ===');
      debugPrint(
        'Body: {jenis_kebutuhan: $jenisKebutuhan, deskripsi: $deskripsi, jumlah: $jumlah}',
      );

      final response = await http.post(
        Uri.parse('$baseUrl/kebutuhan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'jenis_kebutuhan': jenisKebutuhan,
          'deskripsi': deskripsi,
          'jumlah': jumlah,
        }),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Kebutuhan berhasil dibuat',
          'data': data['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Gagal membuat kebutuhan',
        };
      }
    } catch (e) {
      debugPrint('createKebutuhan exception: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateKebutuhan({
    required int id,
    required String deskripsi,
    required int jumlah,
    required String status,
  }) async {
    if (_token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login terlebih dahulu.',
      };
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/kebutuhan/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'deskripsi': deskripsi,
          'jumlah': jumlah,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Kebutuhan berhasil diupdate',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Gagal mengupdate kebutuhan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> deleteKebutuhan(int id) async {
    if (_token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login terlebih dahulu.',
      };
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/kebutuhan/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Kebutuhan berhasil dihapus',
        };
      } else {
        return {'success': false, 'message': 'Gagal menghapus kebutuhan'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ==================== FITUR DONASI LANGSUNG ====================

  // Get daftar penerima
  static Future<Map<String, dynamic>> getPenerimaList() async {
    if (_token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login terlebih dahulu.',
      };
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/donasi/direct/recipients'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? [],
          'message': data['message'] ?? 'Daftar penerima berhasil diambil',
        };
      } else {
        return {'success': false, 'message': 'Gagal mengambil daftar penerima'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Donasi langsung ke penerima (dengan penerima_id)
  static Future<Map<String, dynamic>> createDonasiDirect({
    required int penerimaId,
    required String nama,
    required String kategori,
    String? deskripsi,
    int? jumlah,
    String? satuan,
    File? fotoFile,
    double? latitude,
    double? longitude,
    String? alamat,
  }) async {
    if (_token == null) {
      return {
        'success': false,
        'message': 'Token tidak ditemukan. Silakan login terlebih dahulu.',
      };
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/donasi/direct/donate'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $_token';

      // Add fields
      request.fields['penerima_id'] = penerimaId.toString();
      request.fields['nama_barang'] = nama;
      request.fields['jenis_donasi'] = kategori;
      if (deskripsi != null) request.fields['deskripsi'] = deskripsi;
      if (jumlah != null) request.fields['jumlah'] = jumlah.toString();
      if (satuan != null) request.fields['satuan'] = satuan;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
      if (alamat != null) request.fields['alamat'] = alamat;

      // Add file if provided
      if (fotoFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('foto_donasi', fotoFile.path),
        );
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message':
              jsonData['message'] ??
              'Donasi langsung berhasil dikirim ke penerima!',
          'data': jsonData['data'],
        };
      } else {
        return {
          'success': false,
          'message': jsonData['message'] ?? 'Gagal mengirim donasi langsung',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Penerima - Accept direct donation
  static Future<Map<String, dynamic>> acceptDirectDonation({
    required int donasiId,
    String? keterangan,
  }) async {
    if (_token == null) {
      return {'success': false, 'message': 'Token tidak ditemukan'};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/donasi/$donasiId/accept-direct'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'keterangan': keterangan ?? 'Diterima'}),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return {
          'success': true,
          'message': jsonData['message'] ?? 'Donasi berhasil diterima',
          'data': jsonData['data'],
        };
      } else {
        final jsonData = jsonDecode(response.body);
        return {
          'success': false,
          'message': jsonData['message'] ?? 'Gagal menerima donasi',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Penerima - Reject direct donation
  static Future<Map<String, dynamic>> rejectDirectDonation({
    required int donasiId,
    String? keterangan,
  }) async {
    if (_token == null) {
      return {'success': false, 'message': 'Token tidak ditemukan'};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/donasi/$donasiId/reject-direct'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'keterangan': keterangan ?? 'Ditolak'}),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return {
          'success': true,
          'message': jsonData['message'] ?? 'Donasi berhasil ditolak',
          'data': jsonData['data'],
        };
      } else {
        final jsonData = jsonDecode(response.body);
        return {
          'success': false,
          'message': jsonData['message'] ?? 'Gagal menolak donasi',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Upload Profile Photo
  static Future<Map<String, dynamic>> uploadProfilePhoto(File imageFile) async {
    try {
      if (!_token!.isNotEmpty) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/upload-profile-photo'),
      );

      request.headers['Authorization'] = 'Bearer $_token';
      request.files.add(
        await http.MultipartFile.fromPath('foto_profil', imageFile.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(responseBody);
        return {
          'success': true,
          'message': jsonData['message'] ?? 'Foto berhasil diupload',
          'data': jsonData['data'],
        };
      } else {
        final jsonData = jsonDecode(responseBody);
        return {
          'success': false,
          'message': jsonData['message'] ?? 'Gagal upload foto',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ===== FITUR 1: ACCEPT DONASI DENGAN FOTO BUKTI =====
  // Accept donation with photo proof (Fitur 1)
  static Future<bool> acceptDonationWithPhoto({
    required int donasiId,
    required File fotoBukti,
    String? keterangan,
  }) async {
    try {
      if (_token == null) {
        print('No token available');
        return false;
      }

      // Buat multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/donasi/$donasiId/accept-direct'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $_token';

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('foto_bukti_terima', fotoBukti.path),
      );

      // Add keterangan jika ada
      if (keterangan != null && keterangan.isNotEmpty) {
        request.fields['keterangan'] = keterangan;
      }

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(responseBody);
        return jsonData['success'] ?? false;
      } else {
        print('Accept donation failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error accepting donation with photo: $e');
      return false;
    }
  }

  // ===== FITUR 3: REGISTER DENGAN NAMA PANTI ASUHAN =====
  // Update user profile with panti name (if needed later)
  static Future<Map<String, dynamic>> updateProfileWithPantiName({
    required int userId,
    required String namaPantiAsuhan,
  }) async {
    try {
      if (_token == null) {
        print('No token available');
        return {'success': false, 'message': 'Token tidak tersedia'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'nama_panti_asuhan': namaPantiAsuhan}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Profile berhasil diupdate',
          'data': data['data'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Gagal update profile',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
