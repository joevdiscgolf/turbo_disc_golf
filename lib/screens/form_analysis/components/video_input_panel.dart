import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/camera_angle_toggle.dart';
import 'package:turbo_disc_golf/state/video_form_analysis_cubit.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

/// Panel for initiating video capture/import.
/// Always uses backhand throw type.
class VideoInputPanel extends StatefulWidget {
  const VideoInputPanel({super.key});

  @override
  State<VideoInputPanel> createState() => _VideoInputPanelState();
}

class _VideoInputPanelState extends State<VideoInputPanel> {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          _buildCameraAngleSelector(context),
          const SizedBox(height: 32),
          _buildVideoOptions(context),
          const SizedBox(height: 32),
          _buildTips(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF137e66), Color(0xFF1a9f7f)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF137e66).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.slow_motion_video,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Analyze Your Form',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Get AI-powered feedback on your throwing technique',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCameraAngleSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Camera Angle',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        CameraAngleToggle(
          selectedAngle: _selectedCameraAngle,
          onAngleChanged: (CameraAngle angle) {
            setState(() {
              _selectedCameraAngle = angle;
              // Update selected video to match the new camera angle
              _updateSelectedVideoForCameraAngle();
            });
          },
        ),
        const SizedBox(height: 8),
        Text(
          _selectedCameraAngle.description,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildVideoOptions(BuildContext context) {
    final VideoFormAnalysisCubit cubit =
        BlocProvider.of<VideoFormAnalysisCubit>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          width: double.infinity,
          height: 56,
          label: 'Record Video',
          icon: Icons.videocam,
          gradientBackground: const [Color(0xFF137e66), Color(0xFF1a9f7f)],
          fontSize: 16,
          fontWeight: FontWeight.w600,
          onPressed: () {
            cubit.recordVideo(
              throwType: ThrowTechnique.backhand,
              cameraAngle: _selectedCameraAngle,
            );
          },
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          width: double.infinity,
          height: 56,
          label: 'Import from Gallery',
          icon: Icons.photo_library,
          backgroundColor: Colors.grey[800]!,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          onPressed: () {
            cubit.importVideo(
              throwType: ThrowTechnique.backhand,
              cameraAngle: _selectedCameraAngle,
            );
          },
        ),
        // Test button - only visible in debug mode
        if (showFormAnalysisTestButton) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  width: double.infinity,
                  height: 56,
                  label: 'Test with Example',
                  icon: Icons.bug_report,
                  gradientBackground: const [
                    Color(0xFFFF9800),
                    Color(0xFFFF5722),
                  ],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  onPressed: () {
                    cubit.testWithAssetVideo(
                      throwType: ThrowTechnique.backhand,
                      cameraAngle: _selectedCameraAngle,
                      assetPath: _selectedTestVideoPath,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              _buildTestVideoSelector(),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTips(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Recording Tips',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _TipItem(text: 'Film from the side for the best angle'),
          const _TipItem(text: 'Ensure good lighting'),
          const _TipItem(text: 'Include your full throwing motion'),
          const _TipItem(text: 'Keep your phone steady or use a tripod'),
          const _TipItem(text: 'Video should be 5-30 seconds'),
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

class _TipItem extends StatelessWidget {
  const _TipItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.blue[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
