import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';

import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

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
  bool _showSkeletonOnly = false;

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
          const SizedBox(width: 12),
          _buildViewModeToggle(),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
    final int checkpointCount = widget.poseAnalysis.checkpoints.length;

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
    if (index >= widget.poseAnalysis.checkpoints.length) {
      return const Expanded(child: SizedBox.shrink());
    }

    final CheckpointPoseData checkpoint =
        widget.poseAnalysis.checkpoints[index];
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

  /// Removes "Position" from checkpoint names for cleaner chip labels.
  String _formatChipLabel(String name) {
    return name
        .replaceAll(' Position', '')
        .replaceAll(' position', '')
        .trim();
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
    // Select images based on view mode
    final String? userImage = _showSkeletonOnly
        ? checkpoint.userSkeletonOnlyBase64
        : checkpoint.userImageBase64;
    // Pro reference: silhouette+skeleton in video mode, skeleton-only in skeleton mode
    final String? refImage = _showSkeletonOnly
        ? checkpoint.referenceSkeletonOnlyBase64
        : (checkpoint.referenceSilhouetteWithSkeletonBase64 ?? checkpoint.referenceImageBase64);

    // Check if we have separate images, otherwise fall back to combined
    final bool hasSeparateImages = userImage != null && userImage.isNotEmpty;

    if (!hasSeparateImages) {
      // Fall back to the combined side-by-side or comparison image
      return _buildFallbackImage(checkpoint);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User's form
        _buildLabeledImage(
          label: 'Your Form',
          imageBase64: userImage,
          showArrow: true,
          onTap: () => _showFullscreenComparison(
            userImage: userImage,
            referenceImage: refImage,
          ),
        ),
        const SizedBox(height: 12),
        // Reference/Ideal form
        _buildLabeledImage(
          label: 'Pro Reference',
          imageBase64: refImage,
          showArrow: false,
          onTap: () => _showFullscreenComparison(
            userImage: userImage,
            referenceImage: refImage,
          ),
        ),
      ],
    );
  }

  void _showFullscreenComparison({
    required String? userImage,
    required String? referenceImage,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      useSafeArea: false,
      builder: (dialogContext) => _FullscreenComparisonDialog(
        checkpoints: widget.poseAnalysis.checkpoints,
        initialIndex: _selectedCheckpointIndex,
        showSkeletonOnly: _showSkeletonOnly,
        onToggleMode: (bool newMode) {
          setState(() => _showSkeletonOnly = newMode);
        },
        onIndexChanged: (int newIndex) {
          setState(() => _selectedCheckpointIndex = newIndex);
        },
      ),
    );
  }

  Widget _buildLabeledImage({
    required String label,
    required String? imageBase64,
    required bool showArrow,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TurbColors.darkGray,
                ),
              ),
              const Spacer(),
              if (showArrow)
                Icon(
                  FlutterRemix.arrow_right_s_line,
                  size: 20,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[900],
              child: _decodeAndDisplayImage(imageBase64),
            ),
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
        fit: BoxFit.cover,
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
    // Prefer silhouette comparison if available, fall back to existing options
    final String? imageBase64 = checkpoint.comparisonWithSilhouetteBase64 ??
        checkpoint.sideBySideImageBase64 ??
        checkpoint.comparisonImageBase64;

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

/// Fullscreen dialog for comparing user form to pro reference with PageView.
class _FullscreenComparisonDialog extends StatefulWidget {
  const _FullscreenComparisonDialog({
    required this.checkpoints,
    required this.initialIndex,
    required this.showSkeletonOnly,
    required this.onToggleMode,
    required this.onIndexChanged,
  });

  final List<CheckpointPoseData> checkpoints;
  final int initialIndex;
  final bool showSkeletonOnly;
  final ValueChanged<bool> onToggleMode;
  final ValueChanged<int> onIndexChanged;

  @override
  State<_FullscreenComparisonDialog> createState() =>
      _FullscreenComparisonDialogState();
}

class _FullscreenComparisonDialogState
    extends State<_FullscreenComparisonDialog> {
  late PageController _pageController;
  late int _currentIndex;
  late bool _showSkeletonOnly;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _showSkeletonOnly = widget.showSkeletonOnly;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.checkpoints.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final CheckpointPoseData currentCheckpoint =
        widget.checkpoints[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          currentCheckpoint.checkpointName,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          _buildToggleButton(),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.checkpoints.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                widget.onIndexChanged(index);
              },
              itemBuilder: (context, index) {
                return _buildCheckpointPage(widget.checkpoints[index]);
              },
            ),
            // Navigation arrows (only show if can navigate in that direction)
            if (_currentIndex > 0)
              _buildNavigationArrow(
                isLeft: true,
                onTap: _goToPrevious,
              ),
            if (_currentIndex < widget.checkpoints.length - 1)
              _buildNavigationArrow(
                isLeft: false,
                onTap: _goToNext,
              ),
            // Page indicator
            if (widget.checkpoints.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: _buildPageIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _showSkeletonOnly
                ? () {
                    setState(() => _showSkeletonOnly = false);
                    widget.onToggleMode(false);
                  }
                : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: !_showSkeletonOnly
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Opacity(
                  opacity: !_showSkeletonOnly ? 1.0 : 0.5,
                  child: const Text('📹', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: !_showSkeletonOnly
                ? () {
                    setState(() => _showSkeletonOnly = true);
                    widget.onToggleMode(true);
                  }
                : null,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _showSkeletonOnly
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Opacity(
                  opacity: _showSkeletonOnly ? 1.0 : 0.5,
                  child: const Text('💀', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationArrow({
    required bool isLeft,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: isLeft ? 8 : null,
      right: isLeft ? null : 8,
      top: 0,
      bottom: 0,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLeft ? Icons.chevron_left : Icons.chevron_right,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.checkpoints.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentIndex
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckpointPage(CheckpointPoseData checkpoint) {
    final String? userImage = _showSkeletonOnly
        ? checkpoint.userSkeletonOnlyBase64
        : checkpoint.userImageBase64;
    // Pro reference: silhouette+skeleton in video mode, skeleton-only in skeleton mode
    final String? refImage = _showSkeletonOnly
        ? checkpoint.referenceSkeletonOnlyBase64
        : (checkpoint.referenceSilhouetteWithSkeletonBase64 ?? checkpoint.referenceImageBase64);

    return Column(
      children: [
        Expanded(
          child: _buildFullscreenPanel('Your Form', userImage),
        ),
        Container(height: 2, color: Colors.grey[800]),
        Expanded(
          child: _buildFullscreenPanel('Pro Reference', refImage),
        ),
      ],
    );
  }

  Widget _buildFullscreenPanel(String label, String? imageBase64) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: _decodeAndDisplayImage(imageBase64),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _decodeAndDisplayImage(String? imageBase64) {
    if (imageBase64 == null || imageBase64.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
        ),
      );
    }

    try {
      final Uint8List imageBytes = base64Decode(imageBase64);
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[900],
            child: const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }
  }
}
