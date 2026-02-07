import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/utils/constants/putting_constants.dart';

/// Overlay widget that draws boxes around detected objects
///
/// Used for debugging detection to visualize what the detection
/// service is tracking in real-time. Works for both ML-based
/// disc detection (YOLOv8) and motion-based detection.
class DetectionDebugOverlay extends StatelessWidget {
  /// List of detection bounding boxes in normalized 0-1 coordinates
  final List<Rect> detectionBoxes;

  /// Colors to cycle through for different boxes
  static final List<Color> _boxColors = [
    Colors.orange, // Primary color for disc detection
    Colors.cyan,
    Colors.yellow,
    Colors.purple,
    Colors.pink,
  ];

  const DetectionDebugOverlay({
    super.key,
    required this.detectionBoxes,
  });

  @override
  Widget build(BuildContext context) {
    if (detectionBoxes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: CustomPaint(
        painter: _DetectionBoxPainter(
          detectionBoxes: detectionBoxes,
          isMLDetection: useMLDiscDetection,
        ),
      ),
    );
  }

  /// Get color for a box at given index
  static Color getColorForIndex(int index) {
    return _boxColors[index % _boxColors.length];
  }
}

/// Custom painter for drawing detection boxes
class _DetectionBoxPainter extends CustomPainter {
  final List<Rect> detectionBoxes;
  final bool isMLDetection;

  _DetectionBoxPainter({
    required this.detectionBoxes,
    required this.isMLDetection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < detectionBoxes.length; i++) {
      final Rect normalizedBox = detectionBoxes[i];
      final Color color = DetectionDebugOverlay.getColorForIndex(i);

      // Convert normalized coordinates to pixel coordinates
      final Rect pixelBox = Rect.fromLTRB(
        normalizedBox.left * size.width,
        normalizedBox.top * size.height,
        normalizedBox.right * size.width,
        normalizedBox.bottom * size.height,
      );

      // Draw semi-transparent fill
      final Paint fillPaint = Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawRect(pixelBox, fillPaint);

      // Draw border (thicker for ML detection)
      final Paint borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isMLDetection ? 3.0 : 2.0;
      canvas.drawRect(pixelBox, borderPaint);

      // Draw label
      _drawLabel(canvas, pixelBox, i, color);
    }
  }

  void _drawLabel(Canvas canvas, Rect box, int index, Color color) {
    // Use different label based on detection type
    final String label = isMLDetection ? 'Disc ${index + 1}' : 'Motion ${index + 1}';

    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );

    builder.pushStyle(ui.TextStyle(
      color: Colors.white,
      background: Paint()..color = color.withValues(alpha: 0.9),
    ));
    builder.addText(' $label ');

    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 100));

    // Position label at top-left of box
    canvas.drawParagraph(
      paragraph,
      Offset(box.left + 2, box.top + 2),
    );
  }

  @override
  bool shouldRepaint(covariant _DetectionBoxPainter oldDelegate) {
    return oldDelegate.detectionBoxes != detectionBoxes ||
        oldDelegate.isMLDetection != isMLDetection;
  }
}
