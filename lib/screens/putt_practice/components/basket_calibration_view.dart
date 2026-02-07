import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/models/data/putt_practice/basket_calibration.dart';

/// View for calibrating the basket position
class BasketCalibrationView extends StatelessWidget {
  final CameraController cameraController;
  final BasketCalibration? detectedBasket;
  final String message;
  final VoidCallback onConfirm;

  const BasketCalibrationView({
    super.key,
    required this.cameraController,
    this.detectedBasket,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    if (!cameraController.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        Center(
          child: AspectRatio(
            aspectRatio: cameraController.value.aspectRatio,
            child: CameraPreview(cameraController),
          ),
        ),

        // Basket detection overlay
        if (detectedBasket != null) _buildDetectionOverlay(),

        // Guide overlay when no basket detected
        if (detectedBasket == null) _buildGuideOverlay(),

        // Instructions
        _buildInstructions(),

        // Confirm button
        if (detectedBasket != null && detectedBasket!.confidence > 0.7)
          _buildConfirmButton(),
      ],
    );
  }

  Widget _buildDetectionOverlay() {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          final double left = detectedBasket!.left * width;
          final double top = detectedBasket!.top * height;
          final double right = detectedBasket!.right * width;
          final double bottom = detectedBasket!.bottom * height;

          final Color borderColor = detectedBasket!.confidence > 0.7
              ? Colors.green
              : Colors.yellow;

          return Stack(
            children: [
              // Semi-transparent overlay outside basket
              _buildDarkOverlay(left, top, right, bottom, width, height),

              // Basket bounding box
              Positioned(
                left: left,
                top: top,
                width: right - left,
                height: bottom - top,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: borderColor,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: borderColor,
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: borderColor.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${(detectedBasket!.confidence * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDarkOverlay(
    double left,
    double top,
    double right,
    double bottom,
    double width,
    double height,
  ) {
    return CustomPaint(
      size: Size(width, height),
      painter: _DarkOverlayPainter(
        basketRect: Rect.fromLTRB(left, top, right, bottom),
      ),
    );
  }

  Widget _buildGuideOverlay() {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          // Guide box in center of screen
          final double guideSize = width * 0.4;
          final double left = (width - guideSize) / 2;
          final double top = (height - guideSize) / 2;

          return Stack(
            children: [
              // Dark overlay
              Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),

              // Cutout for guide
              Positioned(
                left: left,
                top: top,
                width: guideSize,
                height: guideSize,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sports_golf,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Position basket here',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Corner guides
              _buildCornerGuide(left - 2, top - 2, true, true),
              _buildCornerGuide(left + guideSize - 18, top - 2, false, true),
              _buildCornerGuide(left - 2, top + guideSize - 18, true, false),
              _buildCornerGuide(
                  left + guideSize - 18, top + guideSize - 18, false, false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCornerGuide(double left, double top, bool isLeft, bool isTop) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            left: isLeft
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            top: isTop
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 150,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Positioned(
      bottom: 80,
      left: 32,
      right: 32,
      child: PrimaryButton(
        label: 'Confirm basket position',
        width: double.infinity,
        onPressed: onConfirm,
      ),
    );
  }
}

/// Custom painter for dark overlay with basket cutout
class _DarkOverlayPainter extends CustomPainter {
  final Rect basketRect;

  _DarkOverlayPainter({required this.basketRect});

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(basketRect, const Radius.circular(8)))
      ..fillType = PathFillType.evenOdd;

    final Paint paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DarkOverlayPainter oldDelegate) {
    return oldDelegate.basketRect != basketRect;
  }
}
