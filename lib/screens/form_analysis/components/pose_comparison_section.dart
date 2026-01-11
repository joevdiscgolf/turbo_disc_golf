import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';

/// Section displaying pose comparison between user and reference.
class PoseComparisonSection extends StatefulWidget {
  const PoseComparisonSection({super.key, required this.poseAnalysis});

  final PoseAnalysisResponse poseAnalysis;

  @override
  State<PoseComparisonSection> createState() => _PoseComparisonSectionState();
}

class _PoseComparisonSectionState extends State<PoseComparisonSection> {
  int _selectedCheckpointIndex = 0;
  bool _isTipsExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.poseAnalysis.checkpoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildCheckpointSelector(context),
        const SizedBox(height: 16),
        _buildComparisonCard(context),
        const SizedBox(height: 16),
        _buildAngleDeviations(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6B4EFF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.compare_arrows,
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
                  'Pose Comparison',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Compare your form to pro reference',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckpointSelector(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: widget.poseAnalysis.checkpoints.length,
        itemBuilder: (context, index) {
          final CheckpointPoseData checkpoint =
              widget.poseAnalysis.checkpoints[index];
          final bool isSelected = index == _selectedCheckpointIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(checkpoint.checkpointName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCheckpointIndex = index);
                }
              },
              selectedColor: const Color(0xFF6B4EFF),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              backgroundColor: Colors.grey[100],
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }

  Widget _buildComparisonCard(BuildContext context) {
    final CheckpointPoseData checkpoint =
        widget.poseAnalysis.checkpoints[_selectedCheckpointIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          // Stacked comparison images
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStackedImages(checkpoint),
          ),
          // Divider
          Divider(height: 1, color: Colors.grey[200]),
          // Checkpoint info
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
                    _buildSeverityBadge(checkpoint.deviationSeverity),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  checkpoint.checkpointDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                ),
                if (checkpoint.coachingTips.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildCoachingTips(context, checkpoint.coachingTips),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackedImages(CheckpointPoseData checkpoint) {
    // Check if we have separate images, otherwise fall back to combined
    final bool hasSeparateImages = checkpoint.userImageBase64 != null &&
        checkpoint.userImageBase64!.isNotEmpty;

    if (!hasSeparateImages) {
      // Fall back to the combined side-by-side or comparison image
      return _buildFallbackImage(checkpoint);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User's form
        _buildLabeledImage(
          label: 'YOUR FORM',
          imageBase64: checkpoint.userImageBase64,
        ),
        const SizedBox(height: 12),
        // Reference/Ideal form
        _buildLabeledImage(
          label: 'PRO REFERENCE',
          imageBase64: checkpoint.referenceImageBase64,
        ),
      ],
    );
  }

  Widget _buildLabeledImage({
    required String label,
    required String? imageBase64,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[900],
            child: _decodeAndDisplayImage(imageBase64),
          ),
        ),
      ],
    );
  }

  Widget _decodeAndDisplayImage(String? imageBase64) {
    if (imageBase64 == null || imageBase64.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
        ),
      );
    }

    try {
      final Uint8List imageBytes = base64Decode(imageBase64);
      return Image.memory(
        imageBytes,
        fit: BoxFit.contain,
        width: double.infinity,
        height: 200,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }
  }

  Widget _buildFallbackImage(CheckpointPoseData checkpoint) {
    // Fall back to existing side-by-side or comparison image
    final String? imageBase64 =
        checkpoint.sideBySideImageBase64 ?? checkpoint.comparisonImageBase64;

    if (imageBase64 == null || imageBase64.isEmpty) {
      return Container(
        height: 280,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
        ),
      );
    }

    try {
      final Uint8List imageBytes = base64Decode(imageBase64);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 280,
          color: Colors.grey[900],
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
            width: double.infinity,
            height: 280,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 280,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      return Container(
        height: 280,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }
  }

  Widget _buildSeverityBadge(String severity) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildCoachingTips(BuildContext context, List<String> tips) {
    return GestureDetector(
      onTap: () => setState(() => _isTipsExpanded = !_isTipsExpanded),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF137e66).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.tips_and_updates,
                  size: 16,
                  color: Color(0xFF137e66),
                ),
                const SizedBox(width: 6),
                Text(
                  'Tips',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF137e66),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${tips.length})',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF137e66).withValues(alpha: 0.7),
                      ),
                ),
                const Spacer(),
                Icon(
                  _isTipsExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: const Color(0xFF137e66),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  ...tips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
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
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
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
              crossFadeState: _isTipsExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAngleDeviations(BuildContext context) {
    final CheckpointPoseData checkpoint =
        widget.poseAnalysis.checkpoints[_selectedCheckpointIndex];

    if (checkpoint.deviations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
          Text(
            'Angle Analysis',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          ...checkpoint.deviations.map(
            (deviation) => _buildDeviationRow(context, deviation),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviationRow(BuildContext context, AngleDeviation deviation) {
    final bool isGood = deviation.withinTolerance;
    final Color statusColor = isGood
        ? const Color(0xFF4CAF50)
        : (deviation.deviation != null && deviation.deviation!.abs() > 20)
            ? const Color(0xFFF44336)
            : const Color(0xFFFF9800);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isGood ? Icons.check : Icons.warning_amber,
              size: 18,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatAngleName(deviation.angleName),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  'You: ${deviation.userValue.toStringAsFixed(0)}° • '
                  'Pro: ${deviation.referenceValue?.toStringAsFixed(0) ?? '--'}°',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          if (deviation.deviation != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${deviation.deviation! > 0 ? '+' : ''}${deviation.deviation!.toStringAsFixed(0)}°',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatAngleName(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : word)
        .join(' ');
  }
}
