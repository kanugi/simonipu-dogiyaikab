import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/utils/date_formatter.dart';

/// Widget preview foto dengan watermark overlay.
/// Menampilkan pratinjau foto yang dipilih beserta informasi watermark
/// (GPS, waktu, nama paket, kegiatan, path) di bagian bawah foto.
class WatermarkPreview extends StatelessWidget {
  final String? imagePath;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final bool hasLocation;
  final DateTime timestamp;
  final String packageName;
  final String kegiatanName;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback? onRemove;

  const WatermarkPreview({
    super.key,
    required this.imagePath,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.hasLocation = false,
    required this.timestamp,
    required this.packageName,
    required this.kegiatanName,
    required this.onPickCamera,
    required this.onPickGallery,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Image / Placeholder
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imagePath != null && imagePath!.isNotEmpty
                  ? Image.file(
                      File(imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),

          // Watermark Overlay Banner (Bottom)
          Positioned(
            left: 12,
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand header
                  Row(
                    children: [
                      const Icon(CupertinoIcons.checkmark_shield_fill,
                          color: Color(0xFF007AFF), size: 13),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'DINAS PUPR KAB. DOGIYAI  |  SIMONI PU',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Nama Paket
                  if (packageName.isNotEmpty)
                    Row(
                      children: [
                        const Text('📦 ', style: TextStyle(fontSize: 9)),
                        Expanded(
                          child: Text(
                            packageName,
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  // Kegiatan
                  if (kegiatanName.isNotEmpty)
                    Row(
                      children: [
                        const Text('🔧 ', style: TextStyle(fontSize: 9)),
                        Expanded(
                          child: Text(
                            kegiatanName,
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 9.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  // File path (basename)
                  if (imagePath != null && imagePath!.isNotEmpty)
                    Row(
                      children: [
                        const Text('📁 ', style: TextStyle(fontSize: 9)),
                        Expanded(
                          child: Text(
                            _basename(imagePath!),
                            style: GoogleFonts.robotoMono(
                              color: Colors.white38,
                              fontSize: 8.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 2),

                  // GPS
                  Text(
                    hasLocation && latitude != null && longitude != null
                        ? '📍 GPS: ${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}  ±${accuracy?.toStringAsFixed(1) ?? '?'}m'
                        : '📍 GPS: Tidak tersedia',
                    style: GoogleFonts.robotoMono(
                      color: hasLocation
                          ? const Color(0xFFFFD60A)
                          : Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // Timestamp
                  Text(
                    '🕒 ${DateFormatter.formatFull(timestamp)}',
                    style: GoogleFonts.robotoMono(
                      color: Colors.white54,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Action Buttons: Kamera + Galeri + (jika ada foto) Hapus
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                _actionButton(
                  icon: CupertinoIcons.camera_fill,
                  onTap: onPickCamera,
                  tooltip: 'Kamera',
                ),
                const SizedBox(width: 6),
                _actionButton(
                  icon: CupertinoIcons.photo_fill,
                  onTap: onPickGallery,
                  tooltip: 'Galeri',
                ),
                if (onRemove != null && imagePath != null) ...[
                  const SizedBox(width: 6),
                  _actionButton(
                    icon: CupertinoIcons.trash_fill,
                    onTap: onRemove!,
                    tooltip: 'Hapus',
                    color: const Color(0xFFFF3B30),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color color = Colors.white,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1C1C1E),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white10,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.camera,
                color: Colors.white54,
                size: 36,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ketuk ikon kamera untuk\nmengambil foto dokumentasi',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Extract basename dari path file
  static String _basename(String path) {
    return path.split('/').last.split('\\').last;
  }
}
