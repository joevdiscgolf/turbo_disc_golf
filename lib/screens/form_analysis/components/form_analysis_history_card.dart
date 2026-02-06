import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:turbo_disc_golf/components/shimmer_box.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_response_v2.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

class FormAnalysisHistoryCard extends StatelessWidget {
  const FormAnalysisHistoryCard({
    super.key,
    required this.analysis,
    required this.onTap,
  });

  final FormAnalysisResponseV2 analysis;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String throwTypeDisplay =
        analysis.analysisResults.throwType == 'backhand'
        ? 'Backhand'
        : 'Forehand';
    final String? formattedDateTime = _formatDateTime(analysis.createdAt);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: defaultCardBoxShadow(),
        ),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildBottomRow(BuildContext context, String throwTypeDisplay) {
    return Row(
      children: [
        _ThrowTypeBadge(throwType: throwTypeDisplay),
        const SizedBox(width: 8),
        _CameraAngleBadge(angle: analysis.analysisResults.cameraAngle),
      ],
    );
  }

  String? _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) {
      return null;
    }

    try {
      final DateTime dateTime = DateTime.parse(isoString).toLocal();
      final DateFormat formatter = DateFormat('MMM d, yyyy');
      return formatter.format(dateTime);
    } catch (e) {
      return null;
    }
  }

  Widget _buildThumbnail(BuildContext context) {
    final String? thumbnailUrl = analysis.videoMetadata.thumbnailUrl;

    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: thumbnailUrl,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholderThumbnail(),
          errorWidget: (context, url, error) => _buildPlaceholderThumbnail(),
        ),
      );
    }

    return _buildPlaceholderThumbnail();
  }

  Widget _buildPlaceholderThumbnail() {
    return ShimmerBox(
      width: 70,
      height: 70,
      borderRadius: 8,
      color: SenseiColors.gray.shade100,
    );
  }
}

/// Shimmer skeleton placeholder for form analysis history cards during loading
class FormAnalysisHistoryCardShimmer extends StatelessWidget {
  const FormAnalysisHistoryCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: defaultCardBoxShadow(),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date placeholder
                  ShimmerBox(
                    width: 120,
                    height: 24,
                    borderRadius: 4,
                    color: SenseiColors.gray.shade100,
                  ),
                  const Spacer(),
                  // Badges placeholder
                  Row(
                    children: [
                      ShimmerBox(
                        width: 80,
                        height: 28,
                        borderRadius: 12,
                        color: SenseiColors.gray.shade100,
                      ),
                      const SizedBox(width: 8),
                      ShimmerBox(
                        width: 60,
                        height: 28,
                        borderRadius: 12,
                        color: SenseiColors.gray.shade100,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Thumbnail placeholder
            ShimmerBox(
              width: 70,
              height: 70,
              borderRadius: 8,
              color: SenseiColors.gray.shade100,
            ),
          ],
        ),
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

/// Camera angle badge with icon and label
class _CameraAngleBadge extends StatelessWidget {
  const _CameraAngleBadge({required this.angle});

  final CameraAngle angle;

  @override
  Widget build(BuildContext context) {
    final bool isSideView = angle == CameraAngle.side;
    final Color color1 = isSideView
        ? const Color(0xFF1976D2)
        : const Color(0xFF00897B);
    final Color color2 = isSideView
        ? const Color(0xFF2196F3)
        : const Color(0xFF26A69A);
    final String label = isSideView ? 'Side' : 'Rear';

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: Image.asset(
              isSideView
                  ? 'assets/form_icons/side_view_backhand_clear.png'
                  : 'assets/form_icons/rear_view_backhand_clear.png',
              fit: BoxFit.contain,
            ),
          ),
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
}
