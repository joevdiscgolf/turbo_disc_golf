import 'package:flutter/material.dart';

/// Educational content widget for the import scorecard feature.
/// Displays instructions on how to properly import a scorecard image.
class ImportScorecardEducationPanel extends StatelessWidget {
  const ImportScorecardEducationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildInstructionsCard(context),
      ],
    );
  }

  Widget _buildInstructionsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBulletPoint(
            context,
            'Import a screenshot of your round data',
            Icons.photo_library_outlined,
          ),
          const SizedBox(height: 16),
          _buildBulletPoint(
            context,
            'Crop the image so it\'s just your round data showing - your score on each hole should be visible',
            Icons.crop,
          ),
          const SizedBox(height: 16),
          _buildBulletPoint(
            context,
            'Your score on each hole will be imported into the UI',
            Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(
    BuildContext context,
    String text,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
