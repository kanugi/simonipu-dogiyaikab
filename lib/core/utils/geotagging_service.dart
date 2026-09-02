import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'date_formatter.dart';

/// Hasil dari operasi geotagging
class GeotagResult {
  /// Path ke file foto BARU yang sudah ter-burn watermark.
  /// Ini adalah file berbeda dari foto asli kamera.
  final String path;
  final bool hasLocation;
  final String? error;

  const GeotagResult({
    required this.path,
    required this.hasLocation,
    this.error,
  });

  bool get isSuccess => error == null;
}

/// Service untuk membakar (burn) watermark geotagging langsung ke PIKSEL foto.
///
/// ### Perbedaan penting:
/// - **Preview watermark** (WatermarkPreview widget): hanya overlay di UI, TIDAK ada di file foto
/// - **Burn watermark** (service ini): watermark ditulis langsung ke data piksel foto,
///   sehingga siapapun yang membuka file foto akan melihat watermark tersebut —
///   termasuk di database/server setelah di-upload
///
/// Output: file JPEG baru di temp directory dengan watermark ter-burn permanen.
class GeotaggingService {
  // ── Warna watermark (RGBA) ──────────────────────────────────────────────────
  static final _colorWhite = img.ColorRgba8(255, 255, 255, 255);
  static final _colorYellow = img.ColorRgba8(255, 214, 10, 255);
  static final _colorGrey = img.ColorRgba8(200, 200, 200, 255);
  static final _colorBg = img.ColorRgba8(0, 0, 0, 185);
  static final _colorBlueLine = img.ColorRgba8(0, 122, 255, 255);
  static final _colorGreen = img.ColorRgba8(52, 199, 89, 255);

  /// Burns watermark onto photo file at [imagePath].
  ///
  /// Proses:
  /// 1. Baca bytes foto asli
  /// 2. Decode JPEG → img.Image
  /// 3. Auto-rotate EXIF (penting untuk foto kamera portrait/landscape)
  /// 4. Render watermark banner ke piksel gambar
  /// 5. Encode kembali ke JPEG
  /// 6. Simpan ke file BARU di temp directory
  /// 7. Return path file BARU (inilah yang dikirim ke API)
  ///
  /// Jika terjadi error, throw Exception (TIDAK diam-diam return foto asli).
  static Future<GeotagResult> burnWatermark({
    required String imagePath,
    required String packageName,
    required String kegiatanName,
    required DateTime timestamp,
    double? latitude,
    double? longitude,
    double? accuracy,
  }) async {
    final bool hasLocation = latitude != null && longitude != null;

    debugPrint('=== GeotaggingService.burnWatermark ===');
    debugPrint('Input path  : $imagePath');
    debugPrint('hasLocation : $hasLocation');
    if (hasLocation) {
      debugPrint('GPS         : $latitude, $longitude (±${accuracy}m)');
    }

    // 1. Verifikasi file asli ada
    final File originalFile = File(imagePath);
    if (!originalFile.existsSync()) {
      throw Exception('File foto tidak ditemukan: $imagePath');
    }

    final int fileSizeKb = (await originalFile.length() / 1024).round();
    debugPrint('File size   : ${fileSizeKb}KB');

    // 2. Baca bytes
    final Uint8List originalBytes = await originalFile.readAsBytes();
    if (originalBytes.isEmpty) {
      throw Exception('File foto kosong: $imagePath');
    }

    // 3. Decode gambar
    img.Image? image = img.decodeImage(originalBytes);
    if (image == null) {
      throw Exception(
        'Gagal decode gambar. Format tidak didukung atau file rusak: $imagePath',
      );
    }
    debugPrint('Decoded     : ${image.width}x${image.height}');

    // 4. Auto-rotate berdasarkan EXIF orientation
    image = img.bakeOrientation(image);
    debugPrint('After rotate: ${image.width}x${image.height}');

    // 5. Siapkan teks watermark
    final String timeStr = DateFormatter.formatWatermark(timestamp);
    final String gpsStr = hasLocation
        ? 'GPS: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}  ±${accuracy?.toStringAsFixed(1) ?? '?'}m'
        : 'GPS: Tidak tersedia';
    final String truncatedPkg = _truncate(packageName, 52);
    final String truncatedKeg = _truncate(kegiatanName, 52);

    // 6. Render watermark banner ke piksel
    _renderWatermark(
      image: image,
      packageName: truncatedPkg,
      kegiatanName: truncatedKeg,
      gpsStr: gpsStr,
      timeStr: timeStr,
      hasLocation: hasLocation,
    );

    // 7. Encode ke JPEG quality 88
    final Uint8List outputBytes = img.encodeJpg(image, quality: 88);
    debugPrint('Output size : ${(outputBytes.length / 1024).round()}KB');

    // 8. Simpan ke temp directory (file BARU — foto asli tidak diubah)
    final Directory tempDir = await getTemporaryDirectory();
    final String outFilename = 'wm_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String outPath = p.join(tempDir.path, outFilename);
    final File outFile = File(outPath);
    await outFile.writeAsBytes(outputBytes, flush: true);

    // Verifikasi file output ada dan tidak kosong
    if (!outFile.existsSync() || await outFile.length() == 0) {
      throw Exception('Gagal menyimpan foto ber-watermark ke: $outPath');
    }

    debugPrint('Output path : $outPath ✅');
    debugPrint('=======================================');

    return GeotagResult(path: outPath, hasLocation: hasLocation);
  }

  // ── Render watermark banner ke piksel image ──────────────────────────────────
  static void _renderWatermark({
    required img.Image image,
    required String packageName,
    required String kegiatanName,
    required String gpsStr,
    required String timeStr,
    required bool hasLocation,
  }) {
    final int imgW = image.width;
    final int imgH = image.height;

    // Gunakan font 14px untuk gambar apapun ukurannya
    // arial14 lebih kecil tapi tetap terbaca
    final font = img.arial14;
    final int lineH = 14;
    final int pad = 9;

    // Baris: brand, paket, kegiatan, gps, waktu = 5 baris
    const int numLines = 5;
    final int bannerH = numLines * lineH + pad * 2;
    final int bannerTop = imgH - bannerH - 10;
    final int bannerLeft = 10;
    final int bannerRight = imgW - 10;
    final int bannerWidth = bannerRight - bannerLeft;

    // Background semi-transparan
    _blendRect(
      image,
      x1: bannerLeft, y1: bannerTop,
      x2: bannerRight, y2: imgH - 10,
      color: _colorBg,
    );

    // Aksen garis kiri biru
    _blendRect(
      image,
      x1: bannerLeft, y1: bannerTop,
      x2: bannerLeft + 3, y2: imgH - 10,
      color: _colorBlueLine,
    );

    // Separator line tipis
    _blendRect(
      image,
      x1: bannerLeft + pad,
      y1: bannerTop + lineH + pad - 1,
      x2: bannerLeft + (bannerWidth * 0.7).toInt(),
      y2: bannerTop + lineH + pad,
      color: img.ColorRgba8(255, 255, 255, 60),
    );

    int tx = bannerLeft + pad;
    int ty = bannerTop + pad;

    // Baris 1: Brand header (putih tebal)
    img.drawString(image,
      'DINAS PUPR KAB. DOGIYAI | SIMONI PU',
      font: font, x: tx, y: ty, color: _colorWhite);
    ty += lineH;

    // Baris 2: Nama Paket
    img.drawString(image,
      'PAKET: $packageName',
      font: font, x: tx, y: ty, color: _colorWhite);
    ty += lineH;

    // Baris 3: Kegiatan
    img.drawString(image,
      'KEGIATAN: $kegiatanName',
      font: font, x: tx, y: ty, color: _colorGrey);
    ty += lineH;

    // Baris 4: GPS (kuning jika ada, abu jika tidak)
    img.drawString(image,
      gpsStr,
      font: font, x: tx, y: ty,
      color: hasLocation ? _colorYellow : _colorGrey);
    ty += lineH;

    // Baris 5: Waktu
    img.drawString(image,
      'WAKTU: $timeStr',
      font: font, x: tx, y: ty, color: _colorGrey);

    // Badge GPS aktif (pojok kanan atas banner)
    if (hasLocation) {
      const badgeText = ' GPS ';
      final badgeX = bannerRight - 42;
      final badgeY = bannerTop + 5;
      _blendRect(image,
        x1: badgeX, y1: badgeY,
        x2: badgeX + 38, y2: badgeY + 14,
        color: _colorGreen);
      img.drawString(image, badgeText,
        font: img.arial14, x: badgeX + 2, y: badgeY + 1,
        color: _colorWhite);
    }
  }

  // ── Alpha-blended rectangle ─────────────────────────────────────────────────
  static void _blendRect(
    img.Image image, {
    required int x1, required int y1,
    required int x2, required int y2,
    required img.Color color,
  }) {
    final int left = math.min(x1, x2).clamp(0, image.width - 1);
    final int top = math.min(y1, y2).clamp(0, image.height - 1);
    final int right = math.max(x1, x2).clamp(0, image.width - 1);
    final int bottom = math.max(y1, y2).clamp(0, image.height - 1);
    final double alpha = (color.a as num).toDouble() / 255.0;

    for (int y = top; y <= bottom; y++) {
      for (int x = left; x <= right; x++) {
        final existing = image.getPixel(x, y);
        final int r = ((color.r as num) * alpha + (existing.r as num) * (1 - alpha)).round();
        final int g = ((color.g as num) * alpha + (existing.g as num) * (1 - alpha)).round();
        final int b = ((color.b as num) * alpha + (existing.b as num) * (1 - alpha)).round();
        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
  }

  // ── Truncate text ───────────────────────────────────────────────────────────
  static String _truncate(String text, int max) {
    if (text.length <= max) return text;
    return '${text.substring(0, max - 3)}...';
  }
}
