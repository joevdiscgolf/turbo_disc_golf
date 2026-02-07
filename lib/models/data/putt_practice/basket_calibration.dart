import 'package:json_annotation/json_annotation.dart';

part 'basket_calibration.g.dart';

/// Calibration data for the detected basket in the camera frame
@JsonSerializable(anyMap: true, explicitToJson: true)
class BasketCalibration {
  /// Bounding box of the basket in normalized coordinates (0-1)
  final double left;
  final double top;
  final double right;
  final double bottom;

  /// Center point of the basket (normalized 0-1)
  final double centerX;
  final double centerY;

  /// Estimated width of the basket in pixels at the current frame
  final double basketWidthPixels;

  /// Pixels per inch scale factor (based on standard basket diameter ~21.5")
  final double pixelsPerInch;

  /// Confidence score of the calibration (0.0 to 1.0)
  final double confidence;

  /// Whether calibration has been confirmed by the user
  final bool userConfirmed;

  /// Timestamp when calibration was performed
  final DateTime calibratedAt;

  BasketCalibration({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.centerX,
    required this.centerY,
    required this.basketWidthPixels,
    required this.pixelsPerInch,
    required this.confidence,
    required this.userConfirmed,
    required this.calibratedAt,
  });

  /// Standard disc golf basket diameter in inches
  static const double standardBasketDiameterInches = 21.5;

  /// Width of the bounding box (normalized)
  double get width => right - left;

  /// Height of the bounding box (normalized)
  double get height => bottom - top;

  /// Create a calibration from detected basket bounding box
  factory BasketCalibration.fromDetection({
    required double left,
    required double top,
    required double right,
    required double bottom,
    required double frameWidth,
    required double confidence,
  }) {
    final double centerX = (left + right) / 2;
    final double centerY = (top + bottom) / 2;
    final double widthNormalized = right - left;
    final double basketWidthPixels = widthNormalized * frameWidth;
    final double pixelsPerInch =
        basketWidthPixels / standardBasketDiameterInches;

    return BasketCalibration(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      centerX: centerX,
      centerY: centerY,
      basketWidthPixels: basketWidthPixels,
      pixelsPerInch: pixelsPerInch,
      confidence: confidence,
      userConfirmed: false,
      calibratedAt: DateTime.now(),
    );
  }

  /// Convert a pixel position to normalized position relative to basket center
  /// Returns (relativeX, relativeY) where:
  /// - relativeX: -1 (far left) to 1 (far right)
  /// - relativeY: -1 (far bottom) to 1 (far top)
  (double, double) pixelToRelative(double pixelX, double pixelY) {
    // Convert to normalized coordinates relative to basket center
    // Scale by basket width to normalize
    final double relativeX = (pixelX - centerX) / (width / 2);
    final double relativeY = (centerY - pixelY) / (height / 2);
    return (relativeX, relativeY);
  }

  /// Estimate distance in feet from pixel position
  double? estimateDistanceFeet(double pixelDistance) {
    if (pixelsPerInch <= 0) return null;
    return (pixelDistance / pixelsPerInch) / 12.0;
  }

  /// Create a copy with user confirmation
  BasketCalibration confirm() {
    return BasketCalibration(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      centerX: centerX,
      centerY: centerY,
      basketWidthPixels: basketWidthPixels,
      pixelsPerInch: pixelsPerInch,
      confidence: confidence,
      userConfirmed: true,
      calibratedAt: calibratedAt,
    );
  }

  factory BasketCalibration.fromJson(Map<String, dynamic> json) =>
      _$BasketCalibrationFromJson(json);

  Map<String, dynamic> toJson() => _$BasketCalibrationToJson(this);
}
