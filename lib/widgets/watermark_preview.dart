import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/utils/date_formatter.dart';

class WatermarkPreview extends StatelessWidget {
  final String? imagePath;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final String packageName;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;

  const WatermarkPreview({
    super.key,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.packageName,
    required this.onPickCamera,
    required this.onPickGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 240,
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

          // Watermark Overlay Banner (Bottom Left)
          Positioned(
            left: 12,
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(191),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.checkmark_shield_fill,
                          color: Color(0xFF007AFF), size: 14),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'DINAS PUPR KAB. DOGIYAI - SIMONI PU',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '📍 GPS: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)} (±${accuracy.toStringAsFixed(1)}m)',
                    style: GoogleFonts.robotoMono(
                      color: const Color(0xFFFFD60A),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '🕒 WAKTU: ${DateFormatter.formatFull(timestamp)}',
                    style: GoogleFonts.robotoMono(
                      color: Colors.white70,
                      fontSize: 9.5,
                    ),
                  ),
                  if (packageName.isNotEmpty)
                    Text(
                      '📦 $packageName',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),

          // Top Action Buttons
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: onPickCamera,
                  icon: const Icon(CupertinoIcons.camera_fill, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  onPressed: onPickGallery,
                  icon: const Icon(CupertinoIcons.photo_fill, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
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
              decoration: BoxDecoration(
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
              'Ketuk ikon kamera untuk mengambil foto dokumentasi',
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
}
