import 'dart:convert';

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
    final String throwTypeDisplay = analysis.throwType == 'backhand'
        ? 'Backhand'
        : 'Forehand';
    final String? formattedDateTime = _formatDateTime(analysis.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Content on the left
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, formattedDateTime),
                      const Spacer(),
                      _buildBottomRow(context, throwTypeDisplay),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Thumbnail on the right (full height)
                _buildThumbnail(context),
              ],
            ),
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
          child: formattedDateTime != null
              ? Text(
                  formattedDateTime,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
        // Severity badge on the right (hide if 'good')
        if (analysis.worstDeviationSeverity != null &&
            analysis.worstDeviationSeverity!.toLowerCase() != 'good')
          _SeverityBadge(severity: analysis.worstDeviationSeverity!),
      ],
    );
  }

  Widget _buildBottomRow(BuildContext context, String throwTypeDisplay) {
    return Row(
      children: [
        _ThrowTypeBadge(throwType: throwTypeDisplay),
        if (analysis.overallFormScore != null) ...[
          const SizedBox(width: 8),
          _buildScoreChip(context),
        ],
      ],
    );
  }

  Widget _buildScoreChip(BuildContext context) {
    return _InfoChip(
      icon: Icons.star,
      label: '${analysis.overallFormScore}',
      color: _getScoreColor(analysis.overallFormScore!),
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
      final DateTime dateTime = DateTime.parse(isoString).toLocal();
      final DateFormat formatter = DateFormat('MMM d, yyyy • h:mm a');
      return formatter.format(dateTime);
    } catch (e) {
      return null;
    }
  }

  Widget _buildThumbnail(BuildContext context) {
    if (analysis.thumbnailBase64 == null) {
      return _buildPlaceholderThumbnail();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.memory(
          base64Decode(analysis.thumbnailBase64!),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderThumbnail();
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholderThumbnail() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Center(
        child: Icon(Icons.sports, size: 30, color: Colors.grey[400]),
      ),
    );
  }
}

/// Throw type badge
class _ThrowTypeBadge extends StatelessWidget {
  const _ThrowTypeBadge({required this.throwType});

  final String throwType;

  @override
  Widget build(BuildContext context) {
    final bool isBackhand = throwType.toLowerCase() == 'backhand';
    final Color color1 = isBackhand
        ? const Color(0xFF5E35B1)
        : const Color(0xFFFF6F00);
    final Color color2 = isBackhand
        ? const Color(0xFF7E57C2)
        : const Color(0xFFFF8F00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        throwType,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        displayText,
        style: const TextStyle(
          fontSize: 11,
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
    final Color color2 = _getLighterColor(color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color2],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLighterColor(Color color) {
    // Create a lighter version of the color for gradient
    final HSLColor hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0)).toColor();
  }
}
