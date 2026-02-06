import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/asset_image_icon.dart';
import 'package:turbo_disc_golf/components/backgrounds/animated_particle_background.dart';
import 'package:turbo_disc_golf/components/compact_popup_menu_item.dart';
import 'package:turbo_disc_golf/components/education/form_analysis_education_panel.dart';
import 'package:turbo_disc_golf/components/liquid_glass_card.dart';
import 'package:turbo_disc_golf/components/loaders/atomic_nuclear_loader.dart';
import 'package:turbo_disc_golf/components/panels/education_panel.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/handedness.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/analysis_completion_transition.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/analysis_results_view.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/camera_angle_selection_panel.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/cycling_analysis_text.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/handedness_selection_panel.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_type.dart';
import 'package:turbo_disc_golf/state/video_form_analysis_cubit.dart';
import 'package:turbo_disc_golf/state/video_form_analysis_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

const String _hasSeenFormAnalysisEducationKey = 'hasSeenFormAnalysisEducation';

/// V2 Form Analysis Recording Screen with "Stage" liquid glass design.
/// Features layered glass panels with tips in back, action in front.
class FormAnalysisRecordingScreenV2 extends StatefulWidget {
  static const String routeName = '/form-analysis-recording-v2';
  static const String screenName = 'Form Analysis Recording V2';

  const FormAnalysisRecordingScreenV2({
    super.key,
    required this.topViewPadding,
  });

  final double topViewPadding;

  @override
  State<FormAnalysisRecordingScreenV2> createState() =>
      _FormAnalysisRecordingScreenV2State();
}

class _FormAnalysisRecordingScreenV2State
    extends State<FormAnalysisRecordingScreenV2> {
  bool _showingTransition = false;
  VideoFormAnalysisComplete? _pendingResults;
  late final LoggingServiceBase _logger;

  final ValueNotifier<double> _loaderSpeedNotifier = ValueNotifier<double>(1.0);
  final ValueNotifier<double> _brainOpacityNotifier = ValueNotifier<double>(
    1.0,
  );

  CameraAngle _selectedCameraAngle = CameraAngle.side;
  Handedness? _selectedHandedness;

  // Debug test videos
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
  ];

  String _selectedTestVideoPath = 'assets/test_videos/joe_example_throw_2.mov';

  @override
  void initState() {
    super.initState();

    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': FormAnalysisRecordingScreenV2.screenName,
    });
    _logger.logScreenImpression('FormAnalysisRecordingScreenV2');

    // Auto-show tips education panel on first visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeEducation();
    });
  }

  @override
  void dispose() {
    _loaderSpeedNotifier.dispose();
    _brainOpacityNotifier.dispose();
    super.dispose();
  }

  Future<void> _checkFirstTimeEducation() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool hasSeenEducation =
        prefs.getBool(_hasSeenFormAnalysisEducationKey) ?? false;

    if (!hasSeenEducation && mounted) {
      await _showFormAnalysisEducation();
      await prefs.setBool(_hasSeenFormAnalysisEducationKey, true);
    }
  }

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
      child: BlocProvider<VideoFormAnalysisCubit>(
        create: (context) => VideoFormAnalysisCubit(),
        child: BlocBuilder<VideoFormAnalysisCubit, VideoFormAnalysisState>(
          builder: (context, state) {
            final Color foregroundColor = SenseiColors.darkGray;

            final bool isLoadingOrAnalyzing =
                state is VideoFormAnalysisRecording ||
                state is VideoFormAnalysisValidating ||
                state is VideoFormAnalysisAnalyzing;

            final bool hideAppBar = isLoadingOrAnalyzing || _showingTransition;

            return Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true,
              appBar: hideAppBar
                  ? null
                  : GenericAppBar(
                      topViewPadding: MediaQuery.of(context).viewPadding.top,
                      title: 'Form analysis',
                      titleStyle: GoogleFonts.exo2(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.5,
                        color: SenseiColors.gray[700],
                      ),
                      hasBackButton: false,
                      backgroundColor: Colors.transparent,
                      foregroundColor: foregroundColor,
                      rightWidget: IconButton(
                        icon: Icon(Icons.close, color: foregroundColor),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _logger.track('Close Recording Screen Button Tapped');
                          Navigator.pop(context);
                        },
                      ),
                    ),
              body: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: AnimatedParticleBackground(
                      isProcessing: isLoadingOrAnalyzing || _showingTransition,
                    ),
                  ),
                  Positioned.fill(
                    child:
                        BlocConsumer<
                          VideoFormAnalysisCubit,
                          VideoFormAnalysisState
                        >(
                          listener: (context, state) {
                            if (state is VideoFormAnalysisComplete &&
                                !_showingTransition) {
                              setState(() {
                                _showingTransition = true;
                                _pendingResults = state;
                              });
                              if (state.poseAnalysisWarning != null) {
                                _showPoseAnalysisWarning(
                                  context,
                                  state.poseAnalysisWarning!,
                                );
                              }
                            }
                          },
                          builder: (context, state) {
                            if (_showingTransition && _pendingResults != null) {
                              return AnalysisCompletionTransition(
                                speedMultiplierNotifier: _loaderSpeedNotifier,
                                brainOpacityNotifier: _brainOpacityNotifier,
                                onComplete: () {
                                  setState(() {
                                    _showingTransition = false;
                                    _brainOpacityNotifier.value = 1.0;
                                  });
                                },
                                child: AnalysisResultsView(
                                  result: _pendingResults!.result,
                                  poseAnalysis: _pendingResults!.poseAnalysis,
                                  topViewPadding: widget.topViewPadding,
                                ),
                              );
                            }
                            return _buildContent(context, state);
                          },
                        ),
                  ),
                  if (isLoadingOrAnalyzing || _showingTransition)
                    Positioned.fill(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ValueListenableBuilder<double>(
                              valueListenable: _brainOpacityNotifier,
                              builder: (context, opacity, child) {
                                return Opacity(opacity: opacity, child: child);
                              },
                              child: AtomicNucleusLoader(
                                key: const ValueKey(
                                  'persistent-analysis-loader',
                                ),
                                speedMultiplierNotifier: _loaderSpeedNotifier,
                              ),
                            ),
                            const SizedBox(height: 32),
                            CyclingAnalysisText(
                              brainOpacityNotifier: _brainOpacityNotifier,
                              shouldShow: !_showingTransition,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, VideoFormAnalysisState state) {
    if (state is VideoFormAnalysisInitial) {
      return _buildStageLayout(context);
    } else if (state is VideoFormAnalysisRecording ||
        state is VideoFormAnalysisValidating ||
        state is VideoFormAnalysisAnalyzing) {
      return const SizedBox.shrink();
    } else if (state is VideoFormAnalysisComplete) {
      return AnalysisResultsView(
        result: state.result,
        poseAnalysis: state.poseAnalysis,
        topViewPadding: widget.topViewPadding,
      );
    } else if (state is VideoFormAnalysisError) {
      return _buildErrorView(context, state.message, state.session);
    }
    return const SizedBox.shrink();
  }

  Widget _buildStageLayout(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: widget.topViewPadding + 60,
        bottom: autoBottomPadding(context),
      ),
      child: Column(
        children: [
          _buildTipsCard(context),
          const SizedBox(height: 16),
          Expanded(child: _buildActionCard(context)),
          // if (kDebugMode &&
          //     locator.get<FeatureFlagService>().showFormAnalysisTestButton)
          _buildDebugSection(context),
        ],
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _logger.track('Tips Card Tapped');
        _showFormAnalysisEducation();
      },
      child: LiquidGlassCard(
        opacity: 0.7,
        blurSigma: 32,
        borderOpacity: 0.5,
        accentColor: const Color(0xFF137e66),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTipsHeader(context),
            const SizedBox(height: 16),
            _buildTipsList(context),
            const SizedBox(height: 20),
            _buildTapForMoreHint(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Tips',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: SenseiColors.darkGray,
            fontSize: 18,
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: SenseiColors.gray[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.help_outline,
            size: 14,
            color: SenseiColors.gray[400],
          ),
        ),
      ],
    );
  }

  Widget _buildTipsList(BuildContext context) {
    return Column(
      children: addRunSpacing(
        [
          _buildTipRow(
            context,
            icon: Icons.fullscreen,
            title: 'Full body in frame',
          ),
          _buildTipRow(
            context,
            icon: Icons.videocam_outlined,
            title: 'Start recording before x-step',
          ),
          _buildTipRow(
            context,
            icon: Icons.arrow_right_alt,
            title: 'End after disc release',
          ),
        ],
        runSpacing: 14,
        axis: Axis.vertical,
      ),
    );
  }

  Widget _buildTipRow(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF137e66).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(icon, size: 18, color: const Color(0xFF137e66)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: SenseiColors.darkGray,
              fontSize: 14,
            ),
          ),
        ),
        Icon(
          Icons.check_circle,
          size: 18,
          color: const Color(0xFF137e66).withValues(alpha: 0.7),
        ),
      ],
    );
  }

  Widget _buildTapForMoreHint(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.touch_app_outlined, size: 14, color: SenseiColors.gray[400]),
        const SizedBox(width: 4),
        Text(
          'Tap for detailed tips',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: SenseiColors.gray[400],
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context) {
    final VideoFormAnalysisCubit cubit =
        BlocProvider.of<VideoFormAnalysisCubit>(context);
    final FeatureFlagService flags = locator.get<FeatureFlagService>();

    return LiquidGlassCard(
      opacity: 0.70,
      blurSigma: 36,
      borderOpacity: 0.5,
      accentColor: const Color(0xFF137e66),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHandednessSelector(context),
          const SizedBox(height: 12),
          Expanded(child: _buildSelectVideoButton(context, cubit, flags)),
        ],
      ),
    );
  }

  Widget _buildHandednessSelector(BuildContext context) {
    final String displayLabel = _selectedHandedness?.badgeLabel ?? 'Auto';

    // Colors matching the handedness selection panel
    const Color tealPrimary = Color(0xFF137e66);
    const Color tealLight = Color(0xFF1A9E80);
    const Color purplePrimary = Color(0xFF7B5B9A);
    const Color purpleLight = Color(0xFF9C7AB8);
    const Color bluePrimary = Color(0xFF4A7FC1);
    const Color blueLight = Color(0xFF6B9AD8);

    // Get colors based on selection
    final (Color color1, Color color2) = switch (_selectedHandedness) {
      null => (tealPrimary, tealLight), // Auto
      Handedness.left => (purplePrimary, purpleLight), // Lefty
      Handedness.right => (bluePrimary, blueLight), // Righty
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Throwing hand',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: SenseiColors.gray[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            final HandednessSelectionResult? result =
                await HandednessSelectionPanel.show(context);
            if (result != null && mounted) {
              setState(() => _selectedHandedness = result.handedness);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [color1, color2],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color1.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: _selectedHandedness == null
                          ? const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 18,
                            )
                          : Transform.flip(
                              flipX: _selectedHandedness == Handedness.left,
                              child: const AssetImageIcon(
                                'assets/form_icons/side_view_backhand_clear.png',
                                size: 20,
                                fit: BoxFit.contain,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      displayLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectVideoButton(
    BuildContext context,
    VideoFormAnalysisCubit cubit,
    FeatureFlagService flags,
  ) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();

        if (flags.showCameraAngleSelectionDialog) {
          if (!mounted) return;
          final CameraAngle? selectedAngle =
              await CameraAngleSelectionPanel.show(context);
          if (selectedAngle == null || !mounted) return;
          setState(() => _selectedCameraAngle = selectedAngle);
          _logger.track(
            'Import Video Button Tapped',
            properties: {
              'camera_angle': selectedAngle.name,
              'handedness': _selectedHandedness?.name ?? 'auto',
              'version': 'v2_stage',
            },
          );
          if (!mounted) return;
          cubit.importVideo(
            throwType: ThrowTechnique.backhand,
            cameraAngle: selectedAngle,
            handedness: _selectedHandedness,
          );
        } else {
          _logger.track(
            'Import Video Button Tapped',
            properties: {
              'camera_angle': _selectedCameraAngle.name,
              'handedness': _selectedHandedness?.name ?? 'auto',
              'version': 'v2_stage',
            },
          );
          cubit.importVideo(
            throwType: ThrowTechnique.backhand,
            cameraAngle: _selectedCameraAngle,
            handedness: _selectedHandedness,
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 56),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF137e66), Color(0xFF1A9E80)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF137e66).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFF137e66).withValues(alpha: 0.15),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_rounded, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              'Select video',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugSection(BuildContext context) {
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

  List<({String path, String name, CameraAngle angle})>
  _getFilteredTestVideos() {
    return _testVideos
        .where((video) => video.angle == _selectedCameraAngle)
        .toList();
  }

  Widget _buildTestVideoSelector() {
    final List<({String path, String name, CameraAngle angle})>
    availableVideos = _getFilteredTestVideos();

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

  void _showPoseAnalysisWarning(BuildContext context, String message) {
    locator.get<ToastService>().show(
      message: message,
      type: ToastType.warning,
      duration: const Duration(seconds: 5),
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    String message,
    dynamic session,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 24),
            Text(
              'Analysis failed',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: SenseiColors.darkGray,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: SenseiColors.gray[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF137e66),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _logger.track('Try Again Button Tapped');
                BlocProvider.of<VideoFormAnalysisCubit>(context).reset();
              },
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
