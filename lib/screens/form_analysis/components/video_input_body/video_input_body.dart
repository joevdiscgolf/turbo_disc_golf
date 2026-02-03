import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_disc_golf/components/compact_popup_menu_item.dart';
import 'package:turbo_disc_golf/components/education/form_analysis_education_panel.dart';
import 'package:turbo_disc_golf/components/panels/education_panel.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/handedness.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/camera_angle_selection_dialog.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/video_input_body/components/best_results_card.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/state/video_form_analysis_cubit.dart';

const String _hasSeenFormAnalysisEducationKey = 'hasSeenFormAnalysisEducation';

/// Panel for initiating video capture/import.
/// Always uses backhand throw type.
class VideoInputBody extends StatefulWidget {
  const VideoInputBody({
    super.key,
    required this.topViewpadding,
    required this.loggingService,
  });

  final double topViewpadding;
  final LoggingServiceBase loggingService;

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
      path: 'assets/test_videos/joe_example_throw_7.mov',
      name: 'Joe #7',
      angle: CameraAngle.side,
    ),
    (
      path: 'assets/test_videos/joe_example_throw_2_mirrored.mp4',
      name: 'Joe #2 Mirrored',
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
      path: 'assets/test_videos/joe_example_throw_rear_3_mirrored.mp4',
      name: 'Joe Rear #3 Mirrored',
      angle: CameraAngle.rear,
    ),
    (
      path: 'assets/test_videos/spin_doctor_example_throw_rear_1.mov',
      name: 'Spin Doctor',
      angle: CameraAngle.rear,
    ),
    (
      path: 'assets/test_videos/wes_example_throw_rear_1.mov',
      name: 'Wes Rear #1',
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
  Handedness _selectedHandedness = Handedness.right; // Default to right-handed

  /// Checks if this is the first time user is importing a video for form analysis.
  /// Shows education panel if first time, then proceeds with import.
  Future<void> _checkFirstTimeEducation() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool hasSeenEducation =
        prefs.getBool(_hasSeenFormAnalysisEducationKey) ?? false;

    if (!hasSeenEducation && mounted) {
      await _showFormAnalysisEducation();
      await prefs.setBool(_hasSeenFormAnalysisEducationKey, true);
    }
  }

  /// Shows the form analysis education panel.
  Future<void> _showFormAnalysisEducation() async {
    if (!mounted) return;
    await EducationPanel.show(
      context,
      title: 'Tips for best results',
      modalName: 'Form Analysis Education',
      accentColor: const Color(0xFF137e66),
      contentBuilder: (_) => const FormAnalysisEducationPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: widget.topViewpadding + 32,
                bottom: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildV2Header(context),
                  const SizedBox(height: 32),
                  _buildV2GlassUploadCard(context),
                  const SizedBox(height: 16),
                  FormAnalysisBestResultsCard(
                    loggingService: widget.loggingService,
                    selectedCameraAngle: _selectedCameraAngle,
                  ),
                  _buildV2DebugSection(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildV2Header(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/icon/app_icon_clear_bg.png',
                  width: 40,
                  height: 40,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Form analysis',
              style: GoogleFonts.exo2(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Compare your form against the best',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildV2GlassUploadCard(BuildContext context) {
    final VideoFormAnalysisCubit cubit =
        BlocProvider.of<VideoFormAnalysisCubit>(context);
    final LoggingService logger = locator.get<LoggingService>();
    final FeatureFlagService flags = locator.get<FeatureFlagService>();

    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();

        // Show camera angle selection dialog if feature flag is enabled
        if (flags.showCameraAngleSelectionDialog) {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.7),
            builder: (BuildContext context) => CameraAngleSelectionDialog(
              onSelected: (CameraAngle angle) async {
                setState(() => _selectedCameraAngle = angle);
                logger.track(
                  'Import Video Button Tapped',
                  properties: {
                    'camera_angle': angle.name,
                    'handedness': _selectedHandedness.name,
                    'version': 'v2',
                  },
                );
                await _checkFirstTimeEducation();
                if (!mounted) return;
                cubit.importVideo(
                  throwType: ThrowTechnique.backhand,
                  cameraAngle: angle,
                  handedness: _selectedHandedness,
                );
              },
            ),
          );
        } else {
          logger.track(
            'Import Video Button Tapped',
            properties: {
              'camera_angle': _selectedCameraAngle.name,
              'handedness': _selectedHandedness.name,
              'version': 'v2',
            },
          );
          await _checkFirstTimeEducation();
          if (!mounted) return;
          cubit.importVideo(
            throwType: ThrowTechnique.backhand,
            cameraAngle: _selectedCameraAngle,
            handedness: _selectedHandedness,
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            _buildV2SettingsRow(context),
            // Divider(
            //   color: SenseiColors.white.withValues(alpha: 0.1),
            //   height: 40,
            // ),
            const SizedBox(height: 20),
            _buildV2UploadArea(context),
          ],
        ),
      ),
    );
  }

  Widget _buildV2UploadArea(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: Colors.white.withValues(alpha: 0.3),
        strokeWidth: 1.5,
        dashWidth: 8,
        dashSpace: 6,
        borderRadius: 16,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF137e66).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam_outlined,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to import video',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select from your gallery',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildV2SettingsRow(BuildContext context) {
    final FeatureFlagService flags = locator.get<FeatureFlagService>();

    // Hide camera angle selector if dialog is enabled
    if (flags.showCameraAngleSelectionDialog) {
      return _buildV2HandednessSection(context);
    }

    return Row(
      children: [
        Expanded(child: _buildV2CameraAngleSection(context)),
        const SizedBox(width: 12),
        Expanded(child: _buildV2HandednessSection(context)),
      ],
    );
  }

  Widget _buildV2CameraAngleSection(BuildContext context) {
    return Column(
      children: [
        Text(
          'Camera',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _V2CompactToggle(
          options: const ['Side', 'Rear'],
          selectedIndex: _selectedCameraAngle == CameraAngle.side ? 0 : 1,
          onChanged: (int index) {
            setState(() {
              _selectedCameraAngle = index == 0
                  ? CameraAngle.side
                  : CameraAngle.rear;
              _updateSelectedVideoForCameraAngle();
            });
          },
        ),
      ],
    );
  }

  Widget _buildV2HandednessSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Throwing hand',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _V2CompactToggle(
          options: const ['Left', 'Right'],
          selectedIndex: _selectedHandedness == Handedness.left ? 0 : 1,
          onChanged: (int index) {
            setState(() {
              _selectedHandedness = index == 0
                  ? Handedness.left
                  : Handedness.right;
            });
          },
        ),
      ],
    );
  }

  Widget _buildV2DebugSection(BuildContext context) {
    if (!locator.get<FeatureFlagService>().showFormAnalysisTestButton) {
      return const SizedBox.shrink();
    }

    final VideoFormAnalysisCubit cubit =
        BlocProvider.of<VideoFormAnalysisCubit>(context);

    return Column(
      children: [
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
                      handedness: _selectedHandedness,
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
    );
  }

  // ==========================================================================
  // Shared Helper Methods
  // ==========================================================================

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
            (video) => CompactPopupMenuItem<String>(
              value: video.path,
              label: video.name,
              showCheckmark: video.path == _selectedTestVideoPath,
              iconColor: const Color(0xFF137e66),
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

/// Compact toggle that scales to fit available width
class _V2CompactToggle extends StatelessWidget {
  const _V2CompactToggle({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: List.generate(options.length, (index) {
          final bool isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onChanged(index);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF137e66)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  options[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// CustomPainter for dashed border effect
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.borderRadius,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = _createDashedPath(path);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source) {
    final Path dashedPath = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double segmentLength = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        dashedPath.addPath(
          metric.extractPath(distance, distance + segmentLength),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.borderRadius != borderRadius;
  }
}
