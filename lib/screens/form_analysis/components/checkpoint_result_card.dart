import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_result.dart';

/// Card displaying the analysis result for a single checkpoint.
class CheckpointResultCard extends StatefulWidget {
  const CheckpointResultCard({
    super.key,
    required this.result,
  });

  final CheckpointAnalysisResult result;

  @override
  State<CheckpointResultCard> createState() => _CheckpointResultCardState();
}

class _CheckpointResultCardState extends State<CheckpointResultCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context),
          if (_isExpanded) _buildExpandedContent(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() => _isExpanded = !_isExpanded);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildScoreIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.result.checkpointName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: widget.result.keyPointResults
                        .take(4)
                        .map((kp) => _buildStatusDot(kp.status))
                        .toList(),
                  ),
                ],
              ),
            ),
            Icon(
              _isExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator() {
    final Color color = _getScoreColor(widget.result.score);

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '${widget.result.score}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDot(KeyPointStatus status) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 12),
          Text(
            widget.result.feedback,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
          ),
          if (widget.result.comparisonToReference != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.compare_arrows,
                    size: 18,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.result.comparisonToReference!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[800],
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Key Points',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          ...widget.result.keyPointResults.map(
            (kp) => _KeyPointRow(keyPoint: kp),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFF2196F3);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  Color _getStatusColor(KeyPointStatus status) {
    switch (status) {
      case KeyPointStatus.excellent:
        return const Color(0xFF4CAF50);
      case KeyPointStatus.good:
        return const Color(0xFF8BC34A);
      case KeyPointStatus.needsImprovement:
        return const Color(0xFFFF9800);
      case KeyPointStatus.poor:
        return const Color(0xFFF44336);
      case KeyPointStatus.notVisible:
        return Colors.grey;
    }
  }
}

class _KeyPointRow extends StatelessWidget {
  const _KeyPointRow({required this.keyPoint});

  final KeyPointResult keyPoint;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusIcon(),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  keyPoint.keyPointName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              _buildStatusLabel(context),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            keyPoint.observation,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          if (keyPoint.suggestion != null &&
              keyPoint.suggestion!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF137e66).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.tips_and_updates,
                    size: 14,
                    color: Color(0xFF137e66),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      keyPoint.suggestion!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF137e66),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData iconData;
    Color color;

    switch (keyPoint.status) {
      case KeyPointStatus.excellent:
        iconData = Icons.check_circle;
        color = const Color(0xFF4CAF50);
        break;
      case KeyPointStatus.good:
        iconData = Icons.check_circle_outline;
        color = const Color(0xFF8BC34A);
        break;
      case KeyPointStatus.needsImprovement:
        iconData = Icons.warning_amber;
        color = const Color(0xFFFF9800);
        break;
      case KeyPointStatus.poor:
        iconData = Icons.error;
        color = const Color(0xFFF44336);
        break;
      case KeyPointStatus.notVisible:
        iconData = Icons.visibility_off;
        color = Colors.grey;
        break;
    }

    return Icon(iconData, size: 20, color: color);
  }

  Widget _buildStatusLabel(BuildContext context) {
    String label;
    Color color;

    switch (keyPoint.status) {
      case KeyPointStatus.excellent:
        label = 'Excellent';
        color = const Color(0xFF4CAF50);
        break;
      case KeyPointStatus.good:
        label = 'Good';
        color = const Color(0xFF8BC34A);
        break;
      case KeyPointStatus.needsImprovement:
        label = 'Improve';
        color = const Color(0xFFFF9800);
        break;
      case KeyPointStatus.poor:
        label = 'Poor';
        color = const Color(0xFFF44336);
        break;
      case KeyPointStatus.notVisible:
        label = 'N/A';
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
