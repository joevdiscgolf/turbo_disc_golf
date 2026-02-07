import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/models/data/putt_practice/putt_practice_session.dart';

/// Overlay showing live session statistics
class SessionStatsOverlay extends StatelessWidget {
  final PuttPracticeSession session;

  const SessionStatsOverlay({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: 'Makes',
            value: '${session.makes}',
            color: Colors.green,
          ),
          _buildDivider(),
          _buildStatItem(
            label: 'Misses',
            value: '${session.misses}',
            color: Colors.red,
          ),
          _buildDivider(),
          _buildStatItem(
            label: 'Percentage',
            value: '${session.makePercentage.toStringAsFixed(0)}%',
            color: _getPercentageColor(session.makePercentage),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey[700],
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.lightGreen;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }
}
