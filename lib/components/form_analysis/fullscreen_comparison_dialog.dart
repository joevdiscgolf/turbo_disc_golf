import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/form_analysis/form_analysis_image.dart';
import 'package:turbo_disc_golf/components/form_analysis/pro_reference_image_content.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/checkpoint_data_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_response_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/user_alignment_metadata.dart';
import 'package:turbo_disc_golf/models/handedness.dart';
import 'package:turbo_disc_golf/models/video_orientation.dart';
import 'package:turbo_disc_golf/services/pro_reference_loader.dart';

/// Fullscreen dialog for comparing user form to pro reference with PageView.
class FullscreenComparisonDialog extends StatefulWidget {
  const FullscreenComparisonDialog({
    super.key,
    required this.checkpoints,
    required this.throwType,
    required this.proRefLoader,
    required this.initialIndex,
    required this.showSkeletonOnly,
    required this.onToggleMode,
    required this.onIndexChanged,
    required this.cameraAngle,
    this.proPlayerId,
    this.videoOrientation,
    this.detectedHandedness,
    this.poseAnalysisResponse,
    this.userAlignmentByCheckpointId,
  });

  final List<CheckpointDataV2> checkpoints;
  final String throwType;
  final ProReferenceLoader proRefLoader;
  final int initialIndex;
  final Handedness? detectedHandedness;
  final bool showSkeletonOnly;
  final ValueChanged<bool> onToggleMode;
  final ValueChanged<int> onIndexChanged;
  final CameraAngle cameraAngle;

  /// Optional pro player ID override for multi-pro comparison.
  final String? proPlayerId;

  final VideoOrientation? videoOrientation;

  /// Pose analysis response containing user landmarks for alignment
  final FormAnalysisResponseV2? poseAnalysisResponse;

  /// Pre-computed user alignment metadata by checkpoint ID.
  /// Used for proper sizing when checkpoints are pro-specific.
  final Map<String, UserAlignmentMetadata?>? userAlignmentByCheckpointId;

  @override
  State<FullscreenComparisonDialog> createState() =>
      _FullscreenComparisonDialogState();
}

class _FullscreenComparisonDialogState
    extends State<FullscreenComparisonDialog> {
  late PageController _pageController;
  late int _currentIndex;
  late bool _showSkeletonOnly;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _showSkeletonOnly = widget.showSkeletonOnly;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Enable landscape orientation for fullscreen viewing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Force portrait orientation when dialog closes
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
    final CheckpointDataV2 currentCheckpoint =
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
          currentCheckpoint.metadata.checkpointName,
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
            if (_currentIndex > 0)
              _buildNavigationArrow(isLeft: true, onTap: _goToPrevious),
            if (_currentIndex < widget.checkpoints.length - 1)
              _buildNavigationArrow(isLeft: false, onTap: _goToNext),
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

  Widget _buildCheckpointPage(CheckpointDataV2 checkpoint) {
    // Note: In V2, individual checkpoint images are not stored
    // This dialog should ideally use video frames, but for now we'll show no user image
    final String? userImageUrl = null; // No per-checkpoint images in V2

    final bool isPortrait =
        widget.videoOrientation == VideoOrientation.portrait;

    if (isPortrait) {
      return Row(
        children: [
          Expanded(child: _buildFullscreenPanel('You', userImageUrl)),
          const SizedBox(width: 4),
          Expanded(child: _buildFullscreenProReferencePanel(checkpoint)),
        ],
      );
    }

    return Column(
      children: [
        Expanded(child: _buildFullscreenPanel('You', userImageUrl)),
        Container(height: 2, color: Colors.grey[800]),
        Expanded(child: _buildFullscreenProReferencePanel(checkpoint)),
      ],
    );
  }

  Widget _buildFullscreenProReferencePanel(CheckpointDataV2 checkpoint) {
    // Get user landmarks for alignment calculation
    final List<PoseLandmark>? userLandmarks =
        _getUserLandmarksForCheckpoint(checkpoint.metadata.checkpointId);

    // Get user alignment metadata from pre-computed map
    final UserAlignmentMetadata? userAlignment =
        widget.userAlignmentByCheckpointId?[checkpoint.metadata.checkpointId];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Pro reference',
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
            child: ProReferenceImageContent(
              checkpoint: checkpoint,
              throwType: widget.throwType,
              cameraAngle: widget.cameraAngle,
              showSkeletonOnly: _showSkeletonOnly,
              proRefLoader: widget.proRefLoader,
              proPlayerId: widget.proPlayerId,
              detectedHandedness: widget.detectedHandedness,
              userLandmarks: userLandmarks,
              userAlignment: userAlignment,
            ),
          ),
        ),
      ],
    );
  }

  /// Gets user landmarks for a specific checkpoint.
  /// First tries to get from CheckpointDataV2 (stored data), then falls back
  /// to FormAnalysisResponseV2 (fresh analysis that hasn't been saved yet).
  List<PoseLandmark>? _getUserLandmarksForCheckpoint(String checkpointId) {
    // First, try to get landmarks from the stored CheckpointDataV2
    try {
      final CheckpointDataV2 checkpoint = widget.checkpoints.firstWhere(
        (cp) => cp.metadata.checkpointId == checkpointId,
      );
      if (checkpoint.userPose.landmarks.isNotEmpty) {
        return checkpoint.userPose.landmarks;
      }
    } catch (e) {
      // Checkpoint not found, continue to fallback
    }

    // Fallback: try to get from FormAnalysisResponseV2 (for fresh analysis)
    if (widget.poseAnalysisResponse == null) return null;

    try {
      final CheckpointDataV2 checkpointData =
          widget.poseAnalysisResponse!.checkpoints.firstWhere(
        (cp) => cp.metadata.checkpointId == checkpointId,
      );
      return checkpointData.userPose.landmarks;
    } catch (e) {
      debugPrint(
          'Failed to get user landmarks for checkpoint $checkpointId: $e');
      return null;
    }
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
                ? FormAnalysisImage(imageUrl: imageUrl)
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
