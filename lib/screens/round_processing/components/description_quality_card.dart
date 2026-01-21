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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
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
            Icon(
              FlutterRemix.lightbulb_line,
              size: 18,
              color: SenseiColors.gray[500],
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
    final List<ThrowQualityIssue> throwIssues = widget.report.allThrowIssues;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: SenseiColors.gray[100]),
          const SizedBox(height: 8),
          ...throwIssues.asMap().entries.map((entry) {
            final int index = entry.key;
            final ThrowQualityIssue issue = entry.value;
            final bool isLast = index == throwIssues.length - 1;
            return _buildThrowIssueRow(issue, isLast: isLast);
          }),
          const SizedBox(height: 8),
          Text(
            'Tap a row to edit that hole',
            style: TextStyle(
              fontSize: 12,
              color: SenseiColors.gray[400],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThrowIssueRow(ThrowQualityIssue issue, {required bool isLast}) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            // Convert hole number to 0-based index
            widget.onHoleTap(issue.holeNumber - 1);
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                // Hole and shot info
                Text(
                  'H${issue.holeNumber}, T${issue.throwNumber}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: SenseiColors.gray[700],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '—',
                  style: TextStyle(
                    fontSize: 13,
                    color: SenseiColors.gray[300],
                  ),
                ),
                const SizedBox(width: 8),
                // Missing info
                Expanded(
                  child: Text(
                    _formatMissingForThrow(issue),
                    style: TextStyle(
                      fontSize: 13,
                      color: SenseiColors.gray[500],
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: SenseiColors.gray[300],
                ),
              ],
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, color: SenseiColors.gray[100]),
      ],
    );
  }

  String _formatMissingForThrow(ThrowQualityIssue issue) {
    final List<String> missing = [];
    if (issue.missingDisc) missing.add('Disc name');
    if (issue.missingTechnique) missing.add('Throw type');
    return missing.join(', ');
  }
}
