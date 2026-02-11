import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:turbo_disc_golf/components/asset_image_icon.dart';
import 'package:turbo_disc_golf/components/cards/standard_card.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/handedness.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// A card displaying analysis metadata: camera angle and recording date/time.
///
/// Shown at the top of the video tab in form analysis to provide context
/// about when and how the video was recorded.
class AnalysisMetadataCard extends StatelessWidget {
  const AnalysisMetadataCard({
    super.key,
    required this.cameraAngle,
    this.createdAt,
    this.detectedHandedness,
  });

  /// The camera angle used for the analysis (side or rear).
  final CameraAngle cameraAngle;

  /// ISO 8601 timestamp when the analysis was created.
  /// If null, the date/time section is not shown.
  final String? createdAt;

  /// Detected handedness from the analysis.
  /// If provided, shows a "Lefty" or "Righty" badge.
  final Handedness? detectedHandedness;

  // Colors matching CameraAngleSelectionPanel
  static const Color _sidePrimary = Color(0xFF1976D2);
  static const Color _sideLight = Color(0xFF2196F3);
  static const Color _rearPrimary = Color(0xFF00897B);
  static const Color _rearLight = Color(0xFF26A69A);

  // Colors matching HandednessSelectionPanel
  static const Color _leftyPrimary = Color(0xFF7B5B9A);
  static const Color _leftyLight = Color(0xFF9C7AB8);
  static const Color _rightyPrimary = Color(0xFF4A7FC1);
  static const Color _rightyLight = Color(0xFF6B9AD8);

  String get _cameraAngleLabel {
    switch (cameraAngle) {
      case CameraAngle.side:
        return 'Side view';
      case CameraAngle.rear:
        return 'Rear view';
    }
  }

  String get _cameraAngleAsset {
    switch (cameraAngle) {
      case CameraAngle.side:
        return 'assets/form_icons/side_view_backhand_clear.png';
      case CameraAngle.rear:
        return 'assets/form_icons/rear_view_backhand_clear.png';
    }
  }

  (Color, Color) get _cameraAngleColors {
    switch (cameraAngle) {
      case CameraAngle.side:
        return (_sidePrimary, _sideLight);
      case CameraAngle.rear:
        return (_rearPrimary, _rearLight);
    }
  }

  String? get _formattedDateTime {
    if (createdAt == null) return null;
    try {
      final DateTime dateTime = DateTime.parse(createdAt!);
      final DateFormat dateFormat = DateFormat('MMM d, yyyy');
      final DateFormat timeFormat = DateFormat('h:mm a');
      return '${dateFormat.format(dateTime)} · ${timeFormat.format(dateTime)}';
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? dateTimeStr = _formattedDateTime;
    final (Color color1, Color color2) = _cameraAngleColors;

    return StandardCard(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Camera angle icon with gradient background
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color1, color2],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Transform.flip(
                    flipX: detectedHandedness == Handedness.left,
                    child: AssetImageIcon(
                      _cameraAngleAsset,
                      size: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Camera angle and date/time info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _cameraAngleLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: SenseiColors.darkGray,
                          height: 1.3,
                        ),
                      ),
                      if (dateTimeStr != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          dateTimeStr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: SenseiColors.gray[500],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Handedness badge in top right corner
          if (detectedHandedness != null)
            Positioned(
              top: 12,
              right: 12,
              child: _buildHandednessBadge(),
            ),
        ],
      ),
    );
  }

  Widget _buildHandednessBadge() {
    final bool isLefty = detectedHandedness == Handedness.left;
    final String label = isLefty ? 'Lefty' : 'Righty';
    final Color lightColor = flattenedOverWhite(
      isLefty ? _leftyLight : _rightyLight,
      0.9,
    );
    final Color darkColor = flattenedOverWhite(
      isLefty ? _leftyPrimary : _rightyPrimary,
      0.9,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lightColor, darkColor],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
