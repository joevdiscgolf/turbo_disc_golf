import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// View for displaying a historical form analysis from Firestore.
class HistoryAnalysisView extends StatefulWidget {
  const HistoryAnalysisView({
    super.key,
    required this.analysis,
    required this.onBack,
  });

  final FormAnalysisRecord analysis;
  final VoidCallback onBack;

  @override
  State<HistoryAnalysisView> createState() => _HistoryAnalysisViewState();
}

class _HistoryAnalysisViewState extends State<HistoryAnalysisView> {
  int _selectedCheckpointIndex = 0;
  bool _showSkeletonOnly = false;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(child: _buildCheckpointSelector(context)),
        SliverToBoxAdapter(child: _buildComparisonCard(context)),
        if (widget.analysis.topCoachingTips?.isNotEmpty ?? false)
          SliverToBoxAdapter(child: _buildCoachingTips(context)),
        SliverToBoxAdapter(child: _buildBackButton(context)),
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final DateTime createdAt = DateTime.parse(widget.analysis.createdAt);
    final String dateStr = DateFormat.yMMMMd().format(createdAt);
    final String timeStr = DateFormat.jm().format(createdAt);
    final bool isBackhand =
        widget.analysis.throwType.toLowerCase() == 'backhand';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4EFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.history,
                  color: Color(0xFF6B4EFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis History',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '$dateStr at $timeStr',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              _buildViewModeToggle(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                label: isBackhand ? 'Backhand' : 'Forehand',
                icon: Icons.sports_golf,
                color: isBackhand
                    ? const Color(0xFF2196F3)
                    : const Color(0xFF9C27B0),
              ),
              const SizedBox(width: 8),
              if (widget.analysis.overallFormScore != null)
                _buildInfoChip(
                  label: 'Score: ${widget.analysis.overallFormScore}',
                  icon: Icons.star,
                  color: _getScoreColor(widget.analysis.overallFormScore!),
                ),
              const SizedBox(width: 8),
              if (widget.analysis.worstDeviationSeverity != null)
                _buildSeverityChip(widget.analysis.worstDeviationSeverity!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChip(String severity) {
    Color color;
    String label;

    switch (severity.toLowerCase()) {
      case 'good':
        color = const Color(0xFF4CAF50);
        label = 'Good';
        break;
      case 'minor':
        color = const Color(0xFFFF9800);
        label = 'Minor Issues';
        break;
      case 'moderate':
        color = const Color(0xFFFF5722);
        label = 'Moderate';
        break;
      case 'significant':
        color = const Color(0xFFF44336);
        label = 'Needs Work';
        break;
      default:
        color = Colors.grey;
        label = severity;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showSkeletonOnly = false),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: !_showSkeletonOnly
                    ? const Color(0xFF6B4EFF).withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('📹', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showSkeletonOnly = true),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _showSkeletonOnly
                    ? const Color(0xFF6B4EFF).withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('💀', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckpointSelector(BuildContext context) {
    final int checkpointCount = widget.analysis.checkpoints.length;
    if (checkpointCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              _buildPositionChip(context, 0),
              const SizedBox(width: 8),
              if (checkpointCount > 1)
                _buildPositionChip(context, 1)
              else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
          if (checkpointCount > 2) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPositionChip(context, 2),
                const SizedBox(width: 8),
                if (checkpointCount > 3)
                  _buildPositionChip(context, 3)
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPositionChip(BuildContext context, int index) {
    if (index >= widget.analysis.checkpoints.length) {
      return const Expanded(child: SizedBox.shrink());
    }

    final CheckpointRecord checkpoint = widget.analysis.checkpoints[index];
    final bool isSelected = index == _selectedCheckpointIndex;
    final String displayName = _formatChipLabel(checkpoint.checkpointName);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCheckpointIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6B4EFF) : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$displayName (${index + 1})',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  String _formatChipLabel(String name) {
    return name
        .replaceAll(' Position', '')
        .replaceAll(' position', '')
        .trim();
  }

  Widget _buildComparisonCard(BuildContext context) {
    if (widget.analysis.checkpoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final CheckpointRecord checkpoint =
        widget.analysis.checkpoints[_selectedCheckpointIndex];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildImageComparison(checkpoint),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        checkpoint.checkpointName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    _buildSeverityChip(checkpoint.deviationSeverity),
                  ],
                ),
                if (checkpoint.coachingTips.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...checkpoint.coachingTips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(color: Color(0xFF137e66)),
                          ),
                          Expanded(
                            child: Text(
                              tip,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageComparison(CheckpointRecord checkpoint) {
    // Select image URLs based on view mode
    final String? userImageUrl = _showSkeletonOnly
        ? checkpoint.userSkeletonUrl
        : checkpoint.userImageUrl;
    final String? refImageUrl = checkpoint.referenceImageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabeledImage(
          label: 'Your Form',
          imageUrl: userImageUrl,
        ),
        const SizedBox(height: 12),
        _buildLabeledImage(
          label: 'Pro Reference',
          imageUrl: refImageUrl,
        ),
      ],
    );
  }

  Widget _buildLabeledImage({
    required String label,
    required String? imageUrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: TurbColors.darkGray,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 200,
            width: double.infinity,
            color: Colors.black,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoachingTips(BuildContext context) {
    final List<String> tips = widget.analysis.topCoachingTips ?? [];
    if (tips.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF137e66).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates,
                size: 20,
                color: Color(0xFF137e66),
              ),
              const SizedBox(width: 8),
              Text(
                'Top Tips',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF137e66),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(color: Color(0xFF137e66)),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[800],
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: PrimaryButton(
        width: double.infinity,
        height: 56,
        label: 'Back to Form Coach',
        icon: Icons.arrow_back,
        gradientBackground: const [Color(0xFF137e66), Color(0xFF1a9f7f)],
        fontSize: 16,
        fontWeight: FontWeight.w600,
        onPressed: () {
          HapticFeedback.lightImpact();
          widget.onBack();
        },
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFF2196F3);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }
}
