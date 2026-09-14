import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_colors.dart';

class PermissionService {
  /// Meminta izin Kamera secara eksplisit dengan dukungan penuh Android 13+ & Custom ROM.
  /// Mengembalikan `true` jika izin diberikan, `false` jika ditolak.
  static Future<bool> requestCameraPermission(BuildContext context) async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      if (context.mounted) {
        _showPermissionDialog(
          context: context,
          title: 'Akses Kamera Dibutuhkan',
          message:
              'Aplikasi membutuhkan izin Kamera untuk mengambil foto dokumentasi kendali. '
              'Silakan aktifkan izin Kamera melalui Pengaturan Aplikasi HP Anda.',
        );
      }
      return false;
    }

    return false;
  }

  /// Meminta izin Galeri/Penyimpanan sesuai versi Android (READ_MEDIA_IMAGES di Android 13+ / READ_EXTERNAL_STORAGE di Android <= 12).
  static Future<bool> requestGalleryPermission(BuildContext context) async {
    // Android Photo Picker di Android 13+ modern tidak selalu membutuhkan izin penyimpanan statis,
    // namun pada Custom ROM (AOSP) izin photos/storage tetap harus diperiksa.
    Permission permission = Platform.isAndroid
        ? (await Permission.photos.status.isGranted ? Permission.photos : Permission.storage)
        : Permission.photos;

    PermissionStatus status = await permission.status;

    if (status.isDenied) {
      status = await permission.request();
    }

    // Jika photos granted, limited (Android 14 partial access), atau storage granted
    if (status.isGranted || status.isLimited) {
      return true;
    }

    // Jika izin galeri ditolak secara permanen
    if (status.isPermanentlyDenied || status.isRestricted) {
      if (context.mounted) {
        _showPermissionDialog(
          context: context,
          title: 'Akses Penyimpanan/Galeri Dibutuhkan',
          message:
              'Aplikasi membutuhkan izin membaca galeri untuk memilih foto dokumentasi. '
              'Silakan aktifkan izin Foto/Penyimpanan di Pengaturan Aplikasi HP Anda.',
        );
      }
      return false;
    }

    // fallback izinkan sistem photo picker bawaan jika didukung
    return true;
  }

  /// Dialog peringatan standar untuk mengarahkan pengguna ke Pengaturan Aplikasi HP
  static void _showPermissionDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Row(
          children: [
            const Icon(
              CupertinoIcons.lock_shield_fill,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            message,
            style: GoogleFonts.inter(fontSize: 13),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Pengaturan HP'),
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }
}
