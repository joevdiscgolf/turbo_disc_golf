import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/components/cards/standard_card.dart';
import 'package:turbo_disc_golf/components/form_analysis/filming_angles_diagram.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Educational content showing ideal camera positions for form analysis.
///
/// Displays bird's eye view diagrams for both side and rear filming angles,
/// with explanations of proper camera positioning.
class FilmingAnglesEducationContent extends StatelessWidget {
  const FilmingAnglesEducationContent({super.key});

  static const Color _arrowColor = Color(0xFF3B82F6); // Blue

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Position your camera correctly for the most accurate form analysis. These diagrams show ideal camera positions from a bird\'s eye view.',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: SenseiColors.darkGray,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(),
        const SizedBox(height: 16),
        _buildDiagramsRow(),
        const SizedBox(height: 20),
        _buildDescriptionsRow(),
      ],
    );
  }

  Widget _buildLegend() {
    return StandardCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(
            icon: Icons.circle,
            iconSize: 10,
            color: Colors.black,
            label: 'You',
          ),
          _buildLegendItem(
            icon: Icons.arrow_forward,
            iconSize: 14,
            color: _arrowColor,
            label: 'Throw direction',
          ),
          _buildLegendItem(
            icon: Icons.videocam,
            iconSize: 14,
            color: SenseiColors.gray[700]!,
            label: 'Camera',
          ),
        ],
      ),
    );
  }

  Widget _buildDiagramsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildDiagramCard(
            title: 'Side view',
            angle: FilmingAngleType.side,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDiagramCard(
            title: 'Rear view',
            angle: FilmingAngleType.rear,
          ),
        ),
      ],
    );
  }

  Widget _buildDiagramCard({
    required String title,
    required FilmingAngleType angle,
  }) {
    return StandardCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: SenseiColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          FilmingAnglesDiagram(cameraAngle: angle, size: 120),
        ],
      ),
    );
  }

  Widget _buildDescriptionsRow() {
    return Column(
      children: [
        _buildDescriptionItem(
          title: 'Side view',
          description:
              'Position the camera to the side, slightly behind you. This captures your full throwing motion.',
        ),
        const SizedBox(height: 12),
        _buildDescriptionItem(
          title: 'Rear view',
          description:
              'Position the camera directly behind you. This shows body alignment and weight transfer.',
        ),
      ],
    );
  }

  Widget _buildDescriptionItem({
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: SenseiColors.gray[400],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: SenseiColors.darkGray.withValues(alpha: 0.85),
                height: 1.45,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required IconData icon,
    required double iconSize,
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: SenseiColors.gray[600],
          ),
        ),
      ],
    );
  }
}
