import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/models/shot_detail.dart';
import 'package:turbo_disc_golf/utils/constants/naming_constants.dart';
import 'package:turbo_disc_golf/utils/score_colors.dart';

/// Widget showing the list of shots for a specific shot shape or throw type
class ShotDetailsList extends StatelessWidget {
  const ShotDetailsList({
    required this.shotDetails,
    this.showThrowTechnique = true,
    this.useLandingSpotAbbreviations = true,
    super.key,
  });

  final List<ShotDetail> shotDetails;
  final bool showThrowTechnique;
  final bool useLandingSpotAbbreviations;

  @override
  Widget build(BuildContext context) {
    if (shotDetails.isEmpty) {
      return Text(
        'No shots found',
        style: TextStyle(fontSize: 13, color: const Color(0xFF6B7280)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: shotDetails.map((detail) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: ScoreColors.getScoreColor(detail.relativeScore),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${detail.holeNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _buildShotDescription(detail),
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Builds descriptive text like "BH Hyzer · Teepad → C1"
  String _buildShotDescription(ShotDetail detail) {
    final discThrow = detail.discThrow;
    final List<String> parts = <String>[];

    // Technique (short name) - only if showThrowTechnique is true
    if (showThrowTechnique && discThrow.technique != null) {
      final String? techName = throwTechniqueToShortName[discThrow.technique];
      if (techName != null && techName.isNotEmpty) {
        parts.add(techName);
      }
    }

    // Shot shape
    if (discThrow.shotShape != null) {
      final String? shapeName = shotShapeToName[discThrow.shotShape];
      if (shapeName != null && shapeName.isNotEmpty) {
        parts.add(shapeName);
      }
    }

    // Build the technique/shape part
    final String techniqueStr = parts.join(' ');

    // Starting location - infer from previous throw if needed
    final String startLoc = _getStartLocation(detail);

    // Ending location - use full names or abbreviations based on parameter
    String endLoc = '';
    if (discThrow.landingSpot != null) {
      if (useLandingSpotAbbreviations) {
        endLoc = landingSpotToShortName[discThrow.landingSpot] ?? '';
      } else {
        endLoc = landingSpotToName[discThrow.landingSpot] ?? '';
      }
    } else if (discThrow.distanceFeetAfterThrow != null) {
      endLoc = '${discThrow.distanceFeetAfterThrow} ft';
    }

    // Combine: "BH Hyzer · Teepad → C1" or "Hyzer · Teepad → Circle 1"
    final StringBuffer buffer = StringBuffer();
    if (techniqueStr.isNotEmpty) {
      buffer.write(techniqueStr);
    }
    if (startLoc.isNotEmpty || endLoc.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(' · ');
      if (startLoc.isNotEmpty) buffer.write(startLoc);
      if (startLoc.isNotEmpty && endLoc.isNotEmpty) buffer.write(' → ');
      if (endLoc.isNotEmpty) buffer.write(endLoc);
    }

    // Fallback if nothing available
    if (buffer.isEmpty) {
      return 'Shot ${detail.throwIndex + 1} · Par ${detail.par}';
    }

    return buffer.toString();
  }

  /// Gets the starting location for a throw, inferring from previous throw if needed
  String _getStartLocation(ShotDetail detail) {
    final discThrow = detail.discThrow;

    // First throw always starts from teepad
    if (detail.throwIndex == 0) {
      return 'Teepad';
    }

    // Use explicit distance before if available
    if (discThrow.distanceFeetBeforeThrow != null) {
      return '${discThrow.distanceFeetBeforeThrow} ft';
    }

    // Infer from previous throw's landing info
    if (detail.throwIndex > 0 &&
        detail.throwIndex <= detail.hole.throws.length) {
      final prevThrow = detail.hole.throws[detail.throwIndex - 1];

      // Previous throw's distance after takes precedence (more precise)
      if (prevThrow.distanceFeetAfterThrow != null) {
        return '${prevThrow.distanceFeetAfterThrow} ft';
      }

      // Fall back to previous throw's landing spot
      if (prevThrow.landingSpot != null) {
        if (useLandingSpotAbbreviations) {
          return landingSpotToShortName[prevThrow.landingSpot] ?? '';
        } else {
          return landingSpotToName[prevThrow.landingSpot] ?? '';
        }
      }
    }

    return '';
  }
}
