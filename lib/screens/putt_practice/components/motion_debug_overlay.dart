import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Overlay widget that draws boxes around detected motion regions
///
/// Used for debugging motion detection to visualize what the
/// motion detection service is tracking in real-time.
class MotionDebugOverlay extends StatelessWidget {
  /// List of motion bounding boxes in normalized 0-1 coordinates
  final List<Rect> motionBoxes;

  /// Colors to cycle through for different boxes
  static final List<Color> _boxColors = [
    Colors.red,
    Colors.blue,
    Colors.yellow,
    Colors.cyan,
    Colors.purple,
  ];

  const MotionDebugOverlay({
    super.key,
    required this.motionBoxes,
  });

  @override
  Widget build(BuildContext context) {
    if (motionBoxes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: CustomPaint(
        painter: _MotionBoxPainter(motionBoxes: motionBoxes),
      ),
    );
  }

  /// Get color for a box at given index
  static Color getColorForIndex(int index) {
    return _boxColors[index % _boxColors.length];
  }
}

/// Custom painter for drawing motion detection boxes
class _MotionBoxPainter extends CustomPainter {
  final List<Rect> motionBoxes;

  _MotionBoxPainter({required this.motionBoxes});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < motionBoxes.length; i++) {
      final Rect normalizedBox = motionBoxes[i];
      final Color color = MotionDebugOverlay.getColorForIndex(i);

      // Convert normalized coordinates to pixel coordinates
      final Rect pixelBox = Rect.fromLTRB(
        normalizedBox.left * size.width,
        normalizedBox.top * size.height,
        normalizedBox.right * size.width,
        normalizedBox.bottom * size.height,
      );

      // Draw semi-transparent fill
      final Paint fillPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawRect(pixelBox, fillPaint);

      // Draw border
      final Paint borderPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(pixelBox, borderPaint);

      // Draw motion label
      _drawLabel(canvas, pixelBox, i, color);
    }
  }

  void _drawLabel(Canvas canvas, Rect box, int index, Color color) {
    final String label = 'Motion ${index + 1}';

    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );

    builder.pushStyle(ui.TextStyle(
      color: Colors.white,
      background: Paint()..color = color.withValues(alpha: 0.8),
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
  bool shouldRepaint(covariant _MotionBoxPainter oldDelegate) {
    return oldDelegate.motionBoxes != motionBoxes;
  }
}
