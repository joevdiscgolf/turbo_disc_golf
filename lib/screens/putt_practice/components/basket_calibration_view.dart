import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/models/data/putt_practice/basket_calibration.dart';
import 'package:turbo_disc_golf/utils/constants/putting_constants.dart';

/// View for calibrating the basket position
/// Supports both ML-based auto-detection and manual box drawing
class BasketCalibrationView extends StatefulWidget {
  final CameraController cameraController;
  final BasketCalibration? detectedBasket;
  final String message;
  final int stableFrameCount;
  final void Function(double left, double top, double right, double bottom)?
      onManualCalibration;

  /// Number of frames required for auto-confirmation
  static const int _requiredStableFrames = 15;

  const BasketCalibrationView({
    super.key,
    required this.cameraController,
    this.detectedBasket,
    required this.message,
    this.stableFrameCount = 0,
    this.onManualCalibration,
  });

  @override
  State<BasketCalibrationView> createState() => _BasketCalibrationViewState();
}

class _BasketCalibrationViewState extends State<BasketCalibrationView> {
  /// Start point of manual drawing (in normalized 0-1 coordinates)
  Offset? _startPoint;

  /// End point of manual drawing (in normalized 0-1 coordinates)
  Offset? _endPoint;

  /// Whether the user is currently drawing
  bool _isDrawing = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.cameraController.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview - fills entire screen
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: widget.cameraController.value.previewSize?.height ?? 1,
              height: widget.cameraController.value.previewSize?.width ?? 1,
              child: CameraPreview(widget.cameraController),
            ),
          ),
        ),

        // Manual drawing gesture layer (when not using ML detection)
        if (!useMLBasketDetection) _buildManualDrawingLayer(),

        // ML Basket detection overlay (bounding box)
        if (useMLBasketDetection && widget.detectedBasket != null)
          _buildDetectionOverlay(),

        // Manual drawing overlay
        if (!useMLBasketDetection && _hasValidDrawing) _buildManualBoxOverlay(),

        // Instructions
        _buildInstructions(),

        // Progress indicator when locking on (ML mode)
        if (useMLBasketDetection && widget.stableFrameCount > 0)
          _buildProgressIndicator(),

        // Confirm button (manual mode)
        if (!useMLBasketDetection && _hasValidDrawing && !_isDrawing)
          _buildConfirmButton(),
      ],
    );
  }

  bool get _hasValidDrawing =>
      _startPoint != null &&
      _endPoint != null &&
      (_endPoint!.dx - _startPoint!.dx).abs() > 0.05 &&
      (_endPoint!.dy - _startPoint!.dy).abs() > 0.05;

  Widget _buildManualDrawingLayer() {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onPanStart: (details) {
              final Offset normalizedPoint = _normalizePoint(
                details.localPosition,
                constraints.maxWidth,
                constraints.maxHeight,
              );
              setState(() {
                _startPoint = normalizedPoint;
                _endPoint = normalizedPoint;
                _isDrawing = true;
              });
            },
            onPanUpdate: (details) {
              if (_isDrawing) {
                final Offset normalizedPoint = _normalizePoint(
                  details.localPosition,
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                setState(() {
                  _endPoint = normalizedPoint;
                });
              }
            },
            onPanEnd: (details) {
              setState(() {
                _isDrawing = false;
              });
            },
            child: Container(color: Colors.transparent),
          );
        },
      ),
    );
  }

  Offset _normalizePoint(Offset point, double width, double height) {
    return Offset(
      (point.dx / width).clamp(0.0, 1.0),
      (point.dy / height).clamp(0.0, 1.0),
    );
  }

  Widget _buildManualBoxOverlay() {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          final double left = (_startPoint!.dx < _endPoint!.dx
                  ? _startPoint!.dx
                  : _endPoint!.dx) *
              width;
          final double top = (_startPoint!.dy < _endPoint!.dy
                  ? _startPoint!.dy
                  : _endPoint!.dy) *
              height;
          final double right = (_startPoint!.dx > _endPoint!.dx
                  ? _startPoint!.dx
                  : _endPoint!.dx) *
              width;
          final double bottom = (_startPoint!.dy > _endPoint!.dy
                  ? _startPoint!.dy
                  : _endPoint!.dy) *
              height;

          final Color borderColor = _isDrawing ? Colors.yellow : Colors.green;

          return Stack(
            children: [
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
                    color: borderColor.withValues(alpha: 0.1),
                  ),
                  child: _isDrawing
                      ? null
                      : Column(
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
                              child: const Text(
                                'Basket',
                                style: TextStyle(
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

  Widget _buildConfirmButton() {
    return Positioned(
      bottom: 80,
      left: 32,
      right: 32,
      child: ElevatedButton.icon(
        onPressed: _confirmManualCalibration,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.check),
        label: const Text(
          'Confirm basket position',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _confirmManualCalibration() {
    if (!_hasValidDrawing || widget.onManualCalibration == null) return;

    final double left = _startPoint!.dx < _endPoint!.dx
        ? _startPoint!.dx
        : _endPoint!.dx;
    final double top = _startPoint!.dy < _endPoint!.dy
        ? _startPoint!.dy
        : _endPoint!.dy;
    final double right = _startPoint!.dx > _endPoint!.dx
        ? _startPoint!.dx
        : _endPoint!.dx;
    final double bottom = _startPoint!.dy > _endPoint!.dy
        ? _startPoint!.dy
        : _endPoint!.dy;

    widget.onManualCalibration!(left, top, right, bottom);
  }

  Widget _buildProgressIndicator() {
    final double progress =
        widget.stableFrameCount / BasketCalibrationView._requiredStableFrames;
    return Positioned(
      bottom: 80,
      left: 32,
      right: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.green : Colors.white,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionOverlay() {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          final double left = widget.detectedBasket!.left * width;
          final double top = widget.detectedBasket!.top * height;
          final double right = widget.detectedBasket!.right * width;
          final double bottom = widget.detectedBasket!.bottom * height;

          final Color borderColor = widget.detectedBasket!.confidence > 0.7
              ? Colors.green
              : Colors.yellow;

          // Basket bounding box only - no dark overlay
          return Positioned(
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
                      '${(widget.detectedBasket!.confidence * 100).toInt()}%',
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
          );
        },
      ),
    );
  }

  Widget _buildInstructions() {
    final String message = useMLBasketDetection
        ? widget.message
        : (_hasValidDrawing && !_isDrawing
            ? 'Tap confirm to set basket position'
            : 'Draw a box around the basket');

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
}
