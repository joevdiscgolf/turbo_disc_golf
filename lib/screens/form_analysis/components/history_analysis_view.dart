import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:intl/intl.dart';

import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/services/pro_reference_loader.dart';
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
  final ProReferenceLoader _proRefLoader = ProReferenceLoader();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildCheckpointSelector(context)),
            SliverToBoxAdapter(child: _buildComparisonCard(context)),
            if (widget.analysis.topCoachingTips?.isNotEmpty ?? false)
              SliverToBoxAdapter(child: _buildCoachingTips(context)),
            const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
          ],
        ),
        _buildFloatingViewToggle(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final DateTime createdAt = DateTime.parse(widget.analysis.createdAt);
    final String formattedDateTime = DateFormat(
      'EEEE, MMM d \'at\' h:mm a',
    ).format(createdAt);
    final bool isBackhand =
        widget.analysis.throwType.toLowerCase() == 'backhand';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
        children: [
          _buildHeroScore(context),
          Divider(height: 1, color: Colors.grey[300]),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildInfoChip(
                  label: isBackhand ? 'Backhand' : 'Forehand',
                  icon: Icons.sports_golf,
                  color: isBackhand
                      ? const Color(0xFF2196F3)
                      : const Color(0xFF9C27B0),
                ),
                if (widget.analysis.cameraAngle != null) ...[
                  const SizedBox(width: 8),
                  _buildCameraAngleChip(widget.analysis.cameraAngle!),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    formattedDateTime,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ),
                if (widget.analysis.worstDeviationSeverity != null)
                  _buildSeverityChip(widget.analysis.worstDeviationSeverity!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroScore(BuildContext context) {
    final int? score = widget.analysis.overallFormScore;

    if (score == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          children: [
            Text(
              '--',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Overall Form Score',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final Color scoreColor = _getScoreColor(score);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                  height: 1.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 3),
                child: Text(
                  '/100',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Overall Form Score',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          _buildProgressBar(score, scoreColor),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int score, Color color) {
    final double progress = (score / 100).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 8,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: 8,
              width: constraints.maxWidth * progress,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
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

  Widget _buildCameraAngleChip(String cameraAngle) {
    final bool isSideView = cameraAngle.toLowerCase() == 'side';
    final Color color = isSideView
        ? const Color(0xFF1976D2)
        : const Color(0xFF00897B);
    final IconData icon = isSideView
        ? Icons.photo_camera
        : Icons.videocam;
    final String label = isSideView ? 'Side' : 'Rear';

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

  Widget _buildFloatingViewToggle() {
    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 112,
          height: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFD8B4FE), Color(0xFFC084FC)],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9333EA).withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Animated slider background
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: _showSkeletonOnly
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 52,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
              // Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildViewToggleButton(
                    icon: Icons.videocam_outlined,
                    isSelected: !_showSkeletonOnly,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showSkeletonOnly = false);
                    },
                  ),
                  _buildViewToggleButton(
                    icon: Icons.accessibility_new,
                    isSelected: _showSkeletonOnly,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showSkeletonOnly = true);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 52,
        height: 44,
        child: Center(
          child: Icon(
            icon,
            size: 22,
            color: isSelected ? Colors.white : const Color(0xFF6B21B6),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckpointSelector(BuildContext context) {
    final int checkpointCount = widget.analysis.checkpoints.length;
    if (checkpointCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: List.generate(checkpointCount, (index) {
          return Expanded(
            child: _buildTabSegment(
              _formatChipLabel(
                widget.analysis.checkpoints[index].checkpointName,
              ),
              index == _selectedCheckpointIndex,
              () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCheckpointIndex = index);
              },
              isFirst: index == 0,
              isLast: index == checkpointCount - 1,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabSegment(
    String name,
    bool isSelected,
    VoidCallback onTap, {
    required bool isFirst,
    required bool isLast,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8B5CF6), Color(0xFF6B4EFF)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: isFirst ? const Radius.circular(11) : Radius.zero,
            bottomLeft: isFirst ? const Radius.circular(11) : Radius.zero,
            topRight: isLast ? const Radius.circular(11) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(11) : Radius.zero,
          ),
        ),
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  String _formatChipLabel(String name) {
    return name.replaceAll(' Position', '').replaceAll(' position', '').trim();
  }

  Widget _buildComparisonCard(BuildContext context) {
    if (widget.analysis.checkpoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final CheckpointRecord checkpoint =
        widget.analysis.checkpoints[_selectedCheckpointIndex];

    return GestureDetector(
      onTap: () => _showFullscreenComparison(checkpoint),
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white.withValues(alpha: 0.0), Colors.white],
            stops: const [0.0, 0.25],
          ),
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
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildImageComparison(checkpoint),
            ),
            const SizedBox(height: 16),
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
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
                                style: Theme.of(context).textTheme.bodySmall
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
      ),
    );
  }

  Widget _buildImageComparison(CheckpointRecord checkpoint) {
    // Select image URLs based on view mode
    final String? userImageUrl = _showSkeletonOnly
        ? checkpoint.userSkeletonUrl
        : checkpoint.userImageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabeledImage(
          label: 'Your Form',
          imageUrl: userImageUrl,
          showArrow: true,
          onTap: () => _showFullscreenComparison(checkpoint),
        ),
        const SizedBox(height: 12),
        _buildProReferenceImage(
          checkpoint: checkpoint,
          onTap: () => _showFullscreenComparison(checkpoint),
        ),
      ],
    );
  }

  Widget _buildProReferenceImage({
    required CheckpointRecord checkpoint,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Pro Reference',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: TurbColors.darkGray,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.black,
              child: _buildProReferenceImageContent(checkpoint),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProReferenceImageContent(CheckpointRecord checkpoint) {
    // New records with proPlayerId: Use hybrid asset loading
    if (checkpoint.proPlayerId != null) {
      return FutureBuilder<ImageProvider>(
        future: _proRefLoader.loadReferenceImage(
          proPlayerId: checkpoint.proPlayerId!,
          throwType: widget.analysis.throwType,
          checkpoint: checkpoint.checkpointId,
          isSkeleton: _showSkeletonOnly,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Failed to load pro reference: ${snapshot.error}');
            return const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            );
          }

          if (!snapshot.hasData) {
            return Container(
                  color: Colors.grey[900],
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.grey[800]!,
                          Colors.grey[700]!,
                          Colors.grey[800]!,
                        ],
                      ),
                    ),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: 1500.ms,
                  color: Colors.white.withValues(alpha: 0.3),
                );
          }

          // Apply alignment transformation
          return Transform.translate(
            offset: Offset(
              MediaQuery.of(context).size.width *
                  (checkpoint.referenceHorizontalOffsetPercent ?? 0) /
                  100,
              0,
            ),
            child: Image(image: snapshot.data!, fit: BoxFit.contain),
          );
        },
      );
    }

    // Legacy records with referenceImageUrl: Use CachedNetworkImage
    final String? refImageUrl = _showSkeletonOnly
        ? checkpoint.referenceSkeletonUrl
        : checkpoint.referenceImageUrl;

    if (refImageUrl != null && refImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        key: ValueKey(refImageUrl),
        imageUrl: refImageUrl,
        fit: BoxFit.contain,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (context, url) =>
            Container(
                  color: Colors.grey[900],
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.grey[800]!,
                          Colors.grey[700]!,
                          Colors.grey[800]!,
                        ],
                      ),
                    ),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: 1500.ms,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }

    // Fallback: No image available
    return const Center(
      child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
    );
  }

  void _showFullscreenComparison(CheckpointRecord checkpoint) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      useSafeArea: false,
      builder: (dialogContext) => _FullscreenComparisonDialog(
        checkpoints: widget.analysis.checkpoints,
        throwType: widget.analysis.throwType,
        proRefLoader: _proRefLoader,
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
    required String? imageUrl,
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
              color: Colors.black,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      key: ValueKey(imageUrl),
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      placeholder: (context, url) =>
                          Container(
                                color: Colors.grey[900],
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.grey[800]!,
                                        Colors.grey[700]!,
                                        Colors.grey[800]!,
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
                              .shimmer(
                                duration: 1500.ms,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
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
                  const Text('• ', style: TextStyle(color: Color(0xFF137e66))),
                  Expanded(
                    child: Text(
                      tip,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[800]),
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

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFF2196F3);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }
}

/// Fullscreen dialog for comparing user form to pro reference with PageView.
class _FullscreenComparisonDialog extends StatefulWidget {
  const _FullscreenComparisonDialog({
    required this.checkpoints,
    required this.throwType,
    required this.proRefLoader,
    required this.initialIndex,
    required this.showSkeletonOnly,
    required this.onToggleMode,
    required this.onIndexChanged,
  });

  final List<CheckpointRecord> checkpoints;
  final String throwType;
  final ProReferenceLoader proRefLoader;
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
    final CheckpointRecord currentCheckpoint =
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
        actions: [_buildToggleButton()],
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
            // Navigation arrows
            if (_currentIndex > 0)
              _buildNavigationArrow(isLeft: true, onTap: _goToPrevious),
            if (_currentIndex < widget.checkpoints.length - 1)
              _buildNavigationArrow(isLeft: false, onTap: _goToNext),
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

  Widget _buildCheckpointPage(CheckpointRecord checkpoint) {
    final String? userImageUrl = _showSkeletonOnly
        ? checkpoint.userSkeletonUrl
        : checkpoint.userImageUrl;

    return Column(
      children: [
        Expanded(child: _buildFullscreenPanel('Your Form', userImageUrl)),
        Container(height: 2, color: Colors.grey[800]),
        Expanded(child: _buildFullscreenProReferencePanel(checkpoint)),
      ],
    );
  }

  Widget _buildFullscreenProReferencePanel(CheckpointRecord checkpoint) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Pro Reference',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: _buildFullscreenProReferenceContent(checkpoint),
          ),
        ),
      ],
    );
  }

  Widget _buildFullscreenProReferenceContent(CheckpointRecord checkpoint) {
    // New records with proPlayerId: Use hybrid asset loading
    if (checkpoint.proPlayerId != null) {
      return FutureBuilder<ImageProvider>(
        future: widget.proRefLoader.loadReferenceImage(
          proPlayerId: checkpoint.proPlayerId!,
          throwType: widget.throwType,
          checkpoint: checkpoint.checkpointId,
          isSkeleton: _showSkeletonOnly,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('Failed to load pro reference: ${snapshot.error}');
            return const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            );
          }

          if (!snapshot.hasData) {
            return Container(
                  color: Colors.grey[900],
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.grey[800]!,
                          Colors.grey[700]!,
                          Colors.grey[800]!,
                        ],
                      ),
                    ),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: 1500.ms,
                  color: Colors.white.withValues(alpha: 0.3),
                );
          }

          // Apply alignment transformation
          return Transform.translate(
            offset: Offset(
              MediaQuery.of(context).size.width *
                  (checkpoint.referenceHorizontalOffsetPercent ?? 0) /
                  100,
              0,
            ),
            child: Image(image: snapshot.data!, fit: BoxFit.contain),
          );
        },
      );
    }

    // Legacy records with referenceImageUrl: Use CachedNetworkImage
    final String? refImageUrl = _showSkeletonOnly
        ? checkpoint.referenceSkeletonUrl
        : checkpoint.referenceImageUrl;

    if (refImageUrl != null && refImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        key: ValueKey(refImageUrl),
        imageUrl: refImageUrl,
        fit: BoxFit.contain,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (context, url) =>
            Container(
                  color: Colors.grey[900],
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.grey[800]!,
                          Colors.grey[700]!,
                          Colors.grey[800]!,
                        ],
                      ),
                    ),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                  duration: 1500.ms,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }

    // Fallback: No image available
    return const Center(
      child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
    );
  }

  Widget _buildFullscreenPanel(String label, String? imageUrl) {
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
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    key: ValueKey(imageUrl),
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (context, url) =>
                        Container(
                              color: Colors.grey[900],
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.grey[800]!,
                                      Colors.grey[700]!,
                                      Colors.grey[800]!,
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .shimmer(
                              duration: 1500.ms,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
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
}
