import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageUtils {
  /// Generates a compressed thumbnail from base64 image data
  /// Returns base64 string of compressed thumbnail
  /// Target: 100x100px, JPEG quality 75
  static String? generateThumbnail({
    required String base64Image,
    int targetSize = 100,
    int jpegQuality = 75,
  }) {
    try {
      // Decode base64 to bytes
      final Uint8List imageBytes = base64Decode(base64Image);

      // Decode image (handles PNG, JPG, etc.)
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Resize to target dimensions (maintains aspect ratio)
      img.Image thumbnail = img.copyResize(
        image,
        width: targetSize,
        height: targetSize,
        interpolation: img.Interpolation.average,
      );

      // Encode as JPEG with compression
      final Uint8List compressedBytes = Uint8List.fromList(
        img.encodeJpg(thumbnail, quality: jpegQuality),
      );

      // Convert back to base64
      return base64Encode(compressedBytes);
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }
}
