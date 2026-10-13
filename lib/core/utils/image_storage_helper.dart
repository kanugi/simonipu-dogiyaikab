import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStorageHelper {
  /// Menyimpan file gambar sementara dari camera/picker ke memori aplikasi permanen
  static Future<String> saveImageToAppStorage(String sourceFilePath, {required String prefix}) async {
    if (sourceFilePath.isEmpty) return '';

    final sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) return '';

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDir.path, 'simonipu_photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final ext = p.extension(sourceFilePath).isNotEmpty ? p.extension(sourceFilePath) : '.jpg';
      final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final destinationPath = p.join(photosDir.path, fileName);

      final savedFile = await sourceFile.copy(destinationPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('Error saveImageToAppStorage: $e');
      return sourceFilePath;
    }
  }

  /// Membaca file gambar lokal dan mengonversinya ke Data URI Base64 Scheme
  static Future<String> fileToDataUriBase64(String filePath) async {
    if (filePath.isEmpty) return '';

    // Jika string sudah merupakan URL HTTP/HTTPS (data dari server), abaikan
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return '';
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) return '';

      final List<int> imageBytes = await file.readAsBytes();
      final String base64String = base64Encode(imageBytes);

      String mimeType = 'image/jpeg';
      final ext = p.extension(filePath).toLowerCase();
      if (ext == '.png') {
        mimeType = 'image/png';
      }

      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      debugPrint('Error fileToDataUriBase64 ($filePath): $e');
      return '';
    }
  }
}
