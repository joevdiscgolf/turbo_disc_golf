import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/camera_angle_toggle.dart';
import 'package:turbo_disc_golf/state/video_form_analysis_cubit.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

/// Panel for initiating video capture/import.
/// Always uses backhand throw type.
class VideoInputBody extends StatefulWidget {
  const VideoInputBody({super.key, required this.topViewpadding});

  final double topViewpadding;

  @override
  State<VideoInputBody> createState() => _VideoInputBodyState();
}

class _VideoInputBodyState extends State<VideoInputBody> {
  // Available test videos with display names and camera angles
  static const List<({String path, String name, CameraAngle angle})>
  _testVideos = [
    (
      path: 'assets/test_videos/joe_example_throw_1.mov',
      name: 'Joe #1',
      angle: CameraAngle.side,
    ),
    (
      path: 'assets/test_videos/joe_example_throw_2.mov',
      name: 'Joe #2',
      angle: CameraAngle.side,
    ),
    (
      path: 'assets/test_videos/joe_example_throw_3.mov',
      name: 'Joe #3',
      angle: CameraAngle.side,
    ),
    (
      path: 'assets/test_videos/joe_example_throw_4.mov',
      name: 'Joe #4',
      angle: CameraAngle.side,
    ),
    (
      path: 'assets/test_videos/joe_example_throw_5.mov',
      name: 'Joe #5',
      angle: CameraAngle.side,
    ),
    (
      path: 'assets/test_videos/joe_example_throw_6.mov',
      name: 'Joe #6',
      angle: CameraAngle.side,
    ),
    (
      path: 'assets/test_videos/joe_example_throw_rear_1.mov',
      name: 'Joe Rear #1',
      angle: CameraAngle.rear,
    ),
    (
      path: 'assets/test_videos/joe_example_throw_rear_2.mov',
      name: 'Joe Rear #2',
      angle: CameraAngle.rear,
    ),
    (
      path: 'assets/test_videos/joe_example_throw_rear_3.mp4',
      name: 'Joe Rear #3',
      angle: CameraAngle.rear,
    ),
    (
      path: 'assets/test_videos/spin_doctor_example_throw_rear_1.mov',
      name: 'Spin Doctor',
      angle: CameraAngle.rear,
    ),
    (
      path: 'assets/test_videos/schmidt_example_throw_1.mov',
      name: 'Schmidt #1',
      angle: CameraAngle.side,
    ),
    (
      path: 'assets/test_videos/trent_example_throw_1.mov',
      name: 'Trent #1',
      angle: CameraAngle.side,
    ),
  ];

  String _selectedTestVideoPath =
      'assets/test_videos/joe_example_throw_2.mov'; // Default to joe #2

  CameraAngle _selectedCameraAngle = CameraAngle.side; // Default to side view

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: widget.topViewpadding + 40,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildCameraAngleSelector(context),
                  const SizedBox(height: 24),
                  _buildVideoOptions(context),
                  const SizedBox(height: 24),
                  _buildTips(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.slow_motion_video_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analyze Your Form',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Get AI-powered feedback on your form',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraAngleSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: CameraAngleToggle(
        selectedAngle: _selectedCameraAngle,
        onAngleChanged: (CameraAngle angle) {
          setState(() {
            _selectedCameraAngle = angle;
            // Update selected video to match the new camera angle
            _updateSelectedVideoForCameraAngle();
          });
        },
      ),
    );
  }

  Widget _buildVideoOptions(BuildContext context) {
    final VideoFormAnalysisCubit cubit =
        BlocProvider.of<VideoFormAnalysisCubit>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Side-by-side action cards
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.videocam,
                title: 'RECORD VIDEO',
                subtitle: 'Capture your throw live',
                gradient: const [Color(0xFF137e66), Color(0xFF1a9f7f)],
                onPressed: () {
                  cubit.recordVideo(
                    throwType: ThrowTechnique.backhand,
                    cameraAngle: _selectedCameraAngle,
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionCard(
                icon: Icons.photo_library,
                title: 'IMPORT VIDEO',
                subtitle: 'Choose from your gallery',
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                onPressed: () {
                  cubit.importVideo(
                    throwType: ThrowTechnique.backhand,
                    cameraAngle: _selectedCameraAngle,
                  );
                },
              ),
            ),
          ],
        ),

        // Debug test section (only visible in debug mode)
        if (showFormAnalysisTestButton) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(child: _buildTestVideoSelector()),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      cubit.testWithAssetVideo(
                        throwType: ThrowTechnique.backhand,
                        cameraAngle: _selectedCameraAngle,
                        assetPath: _selectedTestVideoPath,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Run Test'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTips(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tips_and_updates_rounded,
                  color: Color(0xFF81C784),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Pro Tips for Best Results',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: const [
              _TipItem(text: 'Film from side', compact: true),
              _TipItem(text: 'Good lighting', compact: true),
              _TipItem(text: 'Full motion', compact: true),
              _TipItem(text: 'Steady camera', compact: true),
              _TipItem(text: '5-30 seconds', compact: true),
            ],
          ),
        ],
      ),
    );
  }

  /// Update selected video when camera angle changes to ensure it matches
  void _updateSelectedVideoForCameraAngle() {
    final List<({String path, String name, CameraAngle angle})>
    availableVideos = _getFilteredTestVideos();

    // Check if current selection is still valid for the new angle
    final bool isCurrentVideoValid = availableVideos.any(
      (v) => v.path == _selectedTestVideoPath,
    );

    // If current video doesn't match new angle, select the first available video
    if (!isCurrentVideoValid && availableVideos.isNotEmpty) {
      _selectedTestVideoPath = availableVideos.first.path;
    }
  }

  /// Get test videos filtered by the selected camera angle
  List<({String path, String name, CameraAngle angle})>
  _getFilteredTestVideos() {
    return _testVideos
        .where((video) => video.angle == _selectedCameraAngle)
        .toList();
  }

  Widget _buildTestVideoSelector() {
    // Get videos filtered by current camera angle
    final List<({String path, String name, CameraAngle angle})>
    availableVideos = _getFilteredTestVideos();

    // Find the display name for the currently selected video
    final String selectedName = availableVideos
        .firstWhere(
          (v) => v.path == _selectedTestVideoPath,
          orElse: () => availableVideos.isNotEmpty
              ? availableVideos.first
              : _testVideos.first,
        )
        .name;

    return PopupMenuButton<String>(
      initialValue: _selectedTestVideoPath,
      onSelected: (String value) {
        setState(() => _selectedTestVideoPath = value);
        HapticFeedback.lightImpact();
      },
      itemBuilder: (BuildContext context) => availableVideos
          .map(
            (video) => PopupMenuItem<String>(
              value: video.path,
              child: Row(
                children: [
                  if (video.path == _selectedTestVideoPath)
                    const Icon(Icons.check, size: 18, color: Color(0xFF137e66))
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  Text(
                    video.name,
                    style: TextStyle(
                      fontWeight: video.path == _selectedTestVideoPath
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    this.gradient,
    this.backgroundColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final List<Color>? gradient;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient != null ? LinearGradient(colors: gradient!) : null,
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({required this.text, this.compact = false});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFF81C784),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        if (compact)
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          )
        else
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}
