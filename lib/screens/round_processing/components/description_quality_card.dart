import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/description_quality_analyzer.dart';

/// A collapsible card displaying description quality feedback.
/// Shows which throws are missing disc or technique information.
class DescriptionQualityCard extends StatefulWidget {
  const DescriptionQualityCard({
    super.key,
    required this.report,
    required this.onHoleTap,
  });

  final DescriptionQualityReport report;
  final void Function(int holeIndex) onHoleTap;

  @override
  State<DescriptionQualityCard> createState() => _DescriptionQualityCardState();
}

class _DescriptionQualityCardState extends State<DescriptionQualityCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Don't show if there are no issues
    if (!widget.report.hasIssues) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            flattenedOverWhite(const Color(0xFFE1BEE7), 0.15),
            flattenedOverWhite(const Color(0xFFE1BEE7), 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: flattenedOverWhite(const Color(0xFFCE93D8), 0.15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          if (_isExpanded) _buildExpandedContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _isExpanded = !_isExpanded);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(
              FlutterRemix.lightbulb_line,
              size: 18,
              color: Color(0xFF7E57C2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.report.shortSummary,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: _isExpanded ? 0.5 : 0,
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...widget.report.holeIssues.map((issue) => _buildHoleIssueRow(issue)),
          const SizedBox(height: 8),
          Text(
            'Tap a hole to add details',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoleIssueRow(HoleQualityIssue issue) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Convert hole number to 0-based index
        widget.onHoleTap(issue.holeNumber - 1);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF7E57C2).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${issue.holeNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7E57C2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _formatMissingFields(issue.missingFields),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  String _formatMissingFields(List<String> fields) {
    if (fields.isEmpty) return '';
    final List<String> formatted = fields.map((f) {
      switch (f) {
        case 'disc':
          return 'disc name';
        case 'technique':
          return 'shot type';
        default:
          return f;
      }
    }).toList();
    return 'Missing ${formatted.join(', ')}';
  }
}
