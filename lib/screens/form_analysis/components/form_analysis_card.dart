import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';

class FormAnalysisCard extends StatelessWidget {
  const FormAnalysisCard({
    super.key,
    required this.analysis,
    required this.onTap,
  });

  final FormAnalysisRecord analysis;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String throwTypeDisplay = analysis.throwType == 'backhand' ? 'BH' : 'FH';
    final String? formattedDateTime = _formatDateTime(analysis.createdAt);
    final int checkpointCount = analysis.checkpoints.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, formattedDateTime),
              const SizedBox(height: 12),
              _buildStatsRow(context, throwTypeDisplay, checkpointCount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String? formattedDateTime) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date/time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Form Analysis',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (formattedDateTime != null) ...[
                const SizedBox(height: 2),
                Text(
                  formattedDateTime,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Severity badge
        if (analysis.worstDeviationSeverity != null)
          _SeverityBadge(severity: analysis.worstDeviationSeverity!),
      ],
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    String throwTypeDisplay,
    int checkpointCount,
  ) {
    return Row(
      children: [
        // Throw type chip
        _InfoChip(
          icon: Icons.sports,
          label: throwTypeDisplay,
          color: const Color(0xFF1565C0),
        ),
        const SizedBox(width: 12),
        // Score display if available
        if (analysis.overallFormScore != null) ...[
          _InfoChip(
            icon: Icons.star,
            label: '${analysis.overallFormScore}',
            color: _getScoreColor(analysis.overallFormScore!),
          ),
          const SizedBox(width: 12),
        ],
        // Checkpoint count
        _InfoChip(
          icon: Icons.list,
          label: '$checkpointCount checkpoint${checkpointCount != 1 ? 's' : ''}',
          color: Colors.grey[700]!,
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) {
      return const Color(0xFF137e66); // Excellent - green
    } else if (score >= 75) {
      return const Color(0xFF1976D2); // Good - blue
    } else if (score >= 60) {
      return const Color(0xFFFF8F00); // Fair - orange
    } else {
      return const Color(0xFFD32F2F); // Needs work - red
    }
  }

  String? _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) {
      return null;
    }

    try {
      final DateTime dateTime = DateTime.parse(isoString);
      final DateFormat formatter = DateFormat('MMM d, yyyy • h:mm a');
      return formatter.format(dateTime);
    } catch (e) {
      return null;
    }
  }
}

/// Severity badge with color coding
class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final String severity;

  @override
  Widget build(BuildContext context) {
    final Color color1 = _getGradientColor1(severity);
    final Color color2 = _getGradientColor2(severity);
    final String displayText = _getDisplayText(severity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color1.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        displayText,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getGradientColor1(String severity) {
    switch (severity) {
      case 'good':
        return const Color(0xFF2E7D32); // Green
      case 'minor':
        return const Color(0xFF1976D2); // Blue
      case 'moderate':
        return const Color(0xFFFF8F00); // Orange
      case 'significant':
        return const Color(0xFFC62828); // Red
      default:
        return const Color(0xFF757575); // Gray fallback
    }
  }

  Color _getGradientColor2(String severity) {
    switch (severity) {
      case 'good':
        return const Color(0xFF43A047);
      case 'minor':
        return const Color(0xFF2196F3);
      case 'moderate':
        return const Color(0xFFFFB300);
      case 'significant':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _getDisplayText(String severity) {
    switch (severity) {
      case 'good':
        return 'Good Form';
      case 'minor':
        return 'Minor Issues';
      case 'moderate':
        return 'Moderate';
      case 'significant':
        return 'Needs Work';
      default:
        return severity;
    }
  }
}

/// Small info chip with icon and label
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
