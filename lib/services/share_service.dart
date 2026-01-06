import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Service for capturing widgets as images and sharing them.
class ShareService {
  /// Captures a widget wrapped in RepaintBoundary as a PNG image.
  ///
  /// [repaintKey] should be the GlobalKey attached to a RepaintBoundary widget.
  /// [pixelRatio] controls the image resolution (default 3.0 for high quality).
  ///
  /// Returns the image as bytes, or null if capture failed.
  Future<Uint8List?> captureWidget(
    GlobalKey repaintKey, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final RenderRepaintBoundary? boundary =
          repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        return null;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Shares an image via the native share sheet.
  ///
  /// [imageBytes] is the PNG image data to share.
  /// [caption] is optional text to include with the share.
  /// [filename] is the name for the temporary file (without extension).
  ///
  /// Returns true if sharing succeeded, false if there was an error.
  Future<bool> shareImage(
    Uint8List imageBytes, {
    String? caption,
    String filename = 'judgment',
  }) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath =
          '${tempDir.path}/${filename}_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File(filePath);
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: caption,
      );
      return true;
    } catch (e) {
      // Platform channel errors can occur if native bindings aren't ready
      // Fall back to text-only sharing
      if (caption != null) {
        await Share.share(caption);
        return true;
      }
      return false;
    }
  }

  /// Captures a widget and immediately shares it.
  ///
  /// Convenience method that combines [captureWidget] and [shareImage].
  /// Returns true if sharing succeeded, false if capture or sharing failed.
  Future<bool> captureAndShare(
    GlobalKey repaintKey, {
    String? caption,
    String filename = 'judgment',
    double pixelRatio = 3.0,
  }) async {
    final Uint8List? imageBytes = await captureWidget(
      repaintKey,
      pixelRatio: pixelRatio,
    );

    if (imageBytes == null) {
      // Widget capture failed - fall back to text-only sharing
      if (caption != null) {
        await Share.share(caption);
        return true;
      }
      return false;
    }

    return shareImage(
      imageBytes,
      caption: caption,
      filename: filename,
    );
  }
}
