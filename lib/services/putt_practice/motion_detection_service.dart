import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:turbo_disc_golf/utils/constants/putting_constants.dart';

/// Service for detecting motion using frame differencing
///
/// This provides a simpler alternative to ML-based disc detection
/// by tracking moving regions between consecutive frames.
class MotionDetectionService {
  /// Previous frame data for comparison
  Uint8List? _previousFrame;

  /// Previous frame dimensions
  int _previousWidth = 0;
  int _previousHeight = 0;

  /// Detect motion between frames
  ///
  /// Returns list of bounding boxes (normalized 0-1 coordinates)
  /// for regions with detected motion.
  List<Rect> detectMotion(
    Uint8List currentFrame,
    int width,
    int height,
  ) {
    // If dimensions changed or no previous frame, store and return empty
    if (_previousFrame == null ||
        _previousWidth != width ||
        _previousHeight != height) {
      _previousFrame = Uint8List.fromList(currentFrame);
      _previousWidth = width;
      _previousHeight = height;
      return [];
    }

    try {
      // Compute motion mask
      final Uint8List motionMask = _computeMotionMask(
        _previousFrame!,
        currentFrame,
        width,
        height,
      );

      // Find connected components (motion regions)
      final List<Rect> motionBoxes = _findMotionRegions(
        motionMask,
        width,
        height,
      );

      // Update previous frame
      _previousFrame = Uint8List.fromList(currentFrame);

      return motionBoxes;
    } catch (e) {
      debugPrint('[MotionDetectionService] Error detecting motion: $e');
      _previousFrame = Uint8List.fromList(currentFrame);
      return [];
    }
  }

  /// Compute binary motion mask from frame difference
  Uint8List _computeMotionMask(
    Uint8List previousFrame,
    Uint8List currentFrame,
    int width,
    int height,
  ) {
    final int length = width * height;
    final Uint8List mask = Uint8List(length);

    // Use minimum length to avoid index out of bounds
    final int minLength = [
      previousFrame.length,
      currentFrame.length,
      length,
    ].reduce((a, b) => a < b ? a : b);

    for (int i = 0; i < minLength; i++) {
      final int diff = (currentFrame[i] - previousFrame[i]).abs();
      mask[i] = diff > motionThreshold ? 255 : 0;
    }

    return mask;
  }

  /// Find bounding boxes of motion regions using connected component analysis
  List<Rect> _findMotionRegions(
    Uint8List motionMask,
    int width,
    int height,
  ) {
    // Downsample for faster processing (4x4 blocks)
    const int blockSize = 4;
    final int blocksX = width ~/ blockSize;
    final int blocksY = height ~/ blockSize;

    // Create block activity map
    final List<List<bool>> blockActivity =
        List.generate(blocksY, (_) => List.filled(blocksX, false));

    // Compute activity per block
    for (int by = 0; by < blocksY; by++) {
      for (int bx = 0; bx < blocksX; bx++) {
        int activePixels = 0;
        for (int dy = 0; dy < blockSize; dy++) {
          for (int dx = 0; dx < blockSize; dx++) {
            final int x = bx * blockSize + dx;
            final int y = by * blockSize + dy;
            final int idx = y * width + x;
            if (idx < motionMask.length && motionMask[idx] > 0) {
              activePixels++;
            }
          }
        }
        // Block is active if at least 25% of pixels show motion
        blockActivity[by][bx] = activePixels >= (blockSize * blockSize) ~/ 4;
      }
    }

    // Find connected regions using flood fill
    final List<Rect> regions = [];
    final List<List<bool>> visited =
        List.generate(blocksY, (_) => List.filled(blocksX, false));

    for (int by = 0; by < blocksY; by++) {
      for (int bx = 0; bx < blocksX; bx++) {
        if (blockActivity[by][bx] && !visited[by][bx]) {
          // Flood fill to find connected region
          final (int minX, int minY, int maxX, int maxY) =
              _floodFill(blockActivity, visited, bx, by, blocksX, blocksY);

          // Convert block coordinates to normalized pixel coordinates
          final double left = (minX * blockSize) / width;
          final double top = (minY * blockSize) / height;
          final double right = ((maxX + 1) * blockSize) / width;
          final double bottom = ((maxY + 1) * blockSize) / height;

          // Calculate area in pixels
          final int areaBlocks = (maxX - minX + 1) * (maxY - minY + 1);
          final int areaPixels = areaBlocks * blockSize * blockSize;

          // Only include regions above minimum area threshold
          if (areaPixels >= minMotionArea) {
            regions.add(Rect.fromLTRB(
              left.clamp(0.0, 1.0),
              top.clamp(0.0, 1.0),
              right.clamp(0.0, 1.0),
              bottom.clamp(0.0, 1.0),
            ));
          }
        }
      }
    }

    // Sort by area (largest first) and limit count
    regions.sort((a, b) {
      final double areaA = (a.right - a.left) * (a.bottom - a.top);
      final double areaB = (b.right - b.left) * (b.bottom - b.top);
      return areaB.compareTo(areaA);
    });

    if (regions.length > maxMotionBoxes) {
      return regions.sublist(0, maxMotionBoxes);
    }

    return regions;
  }

  /// Flood fill to find connected region bounds
  (int, int, int, int) _floodFill(
    List<List<bool>> activity,
    List<List<bool>> visited,
    int startX,
    int startY,
    int width,
    int height,
  ) {
    int minX = startX;
    int minY = startY;
    int maxX = startX;
    int maxY = startY;

    final List<(int, int)> stack = [(startX, startY)];

    while (stack.isNotEmpty) {
      final (int x, int y) = stack.removeLast();

      if (x < 0 || x >= width || y < 0 || y >= height) continue;
      if (visited[y][x] || !activity[y][x]) continue;

      visited[y][x] = true;

      // Update bounds
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;

      // Add neighbors
      stack.add((x + 1, y));
      stack.add((x - 1, y));
      stack.add((x, y + 1));
      stack.add((x, y - 1));
    }

    return (minX, minY, maxX, maxY);
  }

  /// Reset the previous frame buffer
  void reset() {
    _previousFrame = null;
    _previousWidth = 0;
    _previousHeight = 0;
  }

  /// Dispose resources
  void dispose() {
    _previousFrame = null;
  }
}
