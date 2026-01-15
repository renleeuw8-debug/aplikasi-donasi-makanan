import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Enum untuk tipe aktor - harus di luar class
enum ActorType { donor, recipient, officer, admin }

/// Service untuk mengelola foto profil dengan folder terpisah per aktor
/// Struktur folder:
/// - App Documents/
///   ├── profiles/
///   │   ├── donors/
///   │   ├── recipients/
///   │   ├── officers/
///   │   └── admins/

class ProfilePhotoService {
  static const String _donorFolder = 'profiles/donors';
  static const String _recipientFolder = 'profiles/recipients';
  static const String _officerFolder = 'profiles/officers';
  static const String _adminFolder = 'profiles/admins';

  /// Dapatkan folder untuk tipe aktor tertentu
  static String _getFolderForType(ActorType type) {
    switch (type) {
      case ActorType.donor:
        return _donorFolder;
      case ActorType.recipient:
        return _recipientFolder;
      case ActorType.officer:
        return _officerFolder;
      case ActorType.admin:
        return _adminFolder;
    }
  }

  /// Dapatkan path folder profil untuk aktor tertentu
  static Future<Directory> getProfilePhotoDirectory(ActorType type) async {
    final appDir = await getApplicationDocumentsDirectory();
    final folderPath = '${appDir.path}/${_getFolderForType(type)}';
    final folder = Directory(folderPath);

    // Buat folder jika belum ada
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    return folder;
  }

  /// Simpan foto profil untuk aktor tertentu dengan ID unik (UID user)
  static Future<File> saveProfilePhoto(
    ActorType type,
    String userId,
    File sourcePhoto,
  ) async {
    try {
      final directory = await getProfilePhotoDirectory(type);
      final destinationPath = '${directory.path}/$userId.jpg';
      final destinationFile = File(destinationPath);

      // Copy file dari source ke destination
      await sourcePhoto.copy(destinationFile.path);
      return destinationFile;
    } catch (e) {
      throw Exception('Gagal menyimpan foto: $e');
    }
  }

  /// Load foto profil untuk aktor tertentu dengan ID unik
  static Future<File?> loadProfilePhoto(ActorType type, String userId) async {
    try {
      final directory = await getProfilePhotoDirectory(type);
      final photoFile = File('${directory.path}/$userId.jpg');

      if (await photoFile.exists()) {
        return photoFile;
      }
      return null;
    } catch (e) {
      throw Exception('Gagal load foto: $e');
    }
  }

  /// Delete foto profil
  static Future<void> deleteProfilePhoto(ActorType type, String userId) async {
    try {
      final directory = await getProfilePhotoDirectory(type);
      final photoFile = File('${directory.path}/$userId.jpg');

      if (await photoFile.exists()) {
        await photoFile.delete();
      }
    } catch (e) {
      throw Exception('Gagal delete foto: $e');
    }
  }

  /// Get nama file foto
  static String getPhotoFileName(String userId) {
    return '$userId.jpg';
  }
}
