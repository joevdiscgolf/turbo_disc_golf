import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/measurement_gauge.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/split_comparison_card.dart';
import 'package:turbo_disc_golf/components/form_analysis/pill_button_group.dart';
import 'package:turbo_disc_golf/components/form_analysis/severity_badge.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/crop_metadata.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/observation_enums.dart';
import 'package:turbo_disc_golf/models/feature_flags/feature_flag.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart'
    show defaultCardBoxShadow;
import 'package:turbo_disc_golf/locator.dart';

/// Modal for viewing observation details with split comparison and frame slider
class ObservationSegmentPlayer extends StatefulWidget {
  const ObservationSegmentPlayer({
    super.key,
    required this.observation,
    required this.videoUrl,
    this.fps = 30.0,
    this.isLeftHanded = false,
    this.totalFrames,
  });

  final FormObservation observation;
  final String videoUrl;
  final double fps;

  /// Whether the user is left-handed (flips pro comparison horizontally)
  final bool isLeftHanded;

  /// Total frames in the video (for clamping bounds)
  final int? totalFrames;

  @override
  State<ObservationSegmentPlayer> createState() =>
      _ObservationSegmentPlayerState();
}

class _ObservationSegmentPlayerState extends State<ObservationSegmentPlayer> {
  final SplitComparisonController _videoController =
      SplitComparisonController();
  final ValueNotifier<bool> _isScrubbingNotifier = ValueNotifier(false);

  int _currentFrame = 0;
  int _startFrame = 0;
  int _endFrame = 0;
  bool _hasSegment = false;

  /// Whether video is currently playing
  bool _isPlaying = true;

  /// Whether video was playing before scrubbing started
  bool _wasPlayingBeforeScrub = true;

  /// Current playback mode (loop or boomerang)
  PlaybackMode _playbackMode = PlaybackMode.boomerang;

  /// Current playback speed
  double _playbackSpeed = 0.25;

  /// Available playback speeds
  static const List<double> _availableSpeeds = [0.25, 0.5, 1.0];

  @override
  void initState() {
    super.initState();
    // Initialize frame range from observation using msBeforeEvent/msAfterEvent if available
    _calculateFrameRange();
    _currentFrame = _startFrame;
    _hasSegment = _endFrame > _startFrame;
  }

  /// Calculates start and end frames based on timing data and playback speed.
  /// Uses msBeforeEvent/msAfterEvent if available.
  /// The ms values represent real-time playback duration - at any speed,
  /// it takes exactly ms_before_event milliseconds to reach the key frame.
  /// At slower speeds, fewer frames are shown to maintain the same real-time duration.
  void _calculateFrameRange() {
    final int keyFrame = widget.observation.timing.frameNumber;
    final int? msBeforeEvent = widget.observation.timing.msBeforeEvent;
    final int? msAfterEvent = widget.observation.timing.msAftervent;

    // If we have ms timing data, calculate frames scaled by playback speed
    if (msBeforeEvent != null || msAfterEvent != null) {
      // Calculate frames: frames = (ms / 1000) * fps * speed
      // At slower speeds, we show fewer frames to keep real-time duration constant
      // Example: 640ms at 30fps
      //   - At 1x: 19.2 frames, takes 640ms real time
      //   - At 0.25x: 4.8 frames, takes 640ms real time (slower playback)
      final int framesBefore = msBeforeEvent != null
          ? ((msBeforeEvent / 1000) * widget.fps * _playbackSpeed).round()
          : 0;
      final int framesAfter = msAfterEvent != null
          ? ((msAfterEvent / 1000) * widget.fps * _playbackSpeed).round()
          : 0;

      _startFrame = keyFrame - framesBefore;
      _endFrame = keyFrame + framesAfter;
    } else {
      // Fall back to deprecated startFrame/endFrame if available
      _startFrame = widget.observation.timing.startFrame ?? keyFrame;
      _endFrame = widget.observation.timing.endFrame ?? keyFrame;
    }

    // Clamp to video bounds
    _clampFramesToBounds();
  }

  /// Clamps start and end frames to valid video bounds
  void _clampFramesToBounds() {
    final int maxFrame = widget.totalFrames ?? _endFrame;

    _startFrame = _startFrame.clamp(0, maxFrame);
    _endFrame = _endFrame.clamp(0, maxFrame);

    // Ensure start <= end
    if (_startFrame > _endFrame) {
      _startFrame = _endFrame;
    }
  }

  @override
  void dispose() {
    _isScrubbingNotifier.dispose();
    super.dispose();
  }

  void _onFrameChanged(int currentFrame, int startFrame, int endFrame) {
    if (mounted && !_isScrubbingNotifier.value) {
      final int clampedFrame = currentFrame.clamp(startFrame, endFrame);
      // Only rebuild if values actually changed
      if (_currentFrame != clampedFrame) {
        setState(() {
          _currentFrame = clampedFrame;
        });
      }
    }
  }

  void _onPlayStateChanged(bool isPlaying) {
    if (mounted) {
      setState(() {
        _isPlaying = isPlaying;
      });
    }
  }

  void _onSliderChanged(double value) {
    final int frame = value.round();
    setState(() {
      _currentFrame = frame;
    });
    _videoController.seekToFrame(frame);
  }

  void _onSliderStart(double value) {
    _wasPlayingBeforeScrub = _isPlaying;
    _isScrubbingNotifier.value = true;
    _videoController.pause();
  }

  void _onSliderEnd(double value) {
    _isScrubbingNotifier.value = false;
    // Only resume if was playing before scrubbing
    if (_wasPlayingBeforeScrub) {
      _videoController.play();
    }
  }

  void _togglePlayPause() {
    _videoController.togglePlayPause();
  }

  void _togglePlaybackMode() {
    setState(() {
      _playbackMode = _playbackMode == PlaybackMode.loop
          ? PlaybackMode.boomerang
          : PlaybackMode.loop;
    });
    _videoController.setPlaybackMode(_playbackMode);
  }

  void _changePlaybackSpeed(double speed) {
    if (_playbackSpeed == speed) return;

    HapticFeedback.selectionClick();

    // Store old frame range to detect changes
    final int oldStartFrame = _startFrame;
    final int oldEndFrame = _endFrame;

    setState(() {
      _playbackSpeed = speed;
      // Recalculate frame range based on new speed
      _calculateFrameRange();
      _hasSegment = _endFrame > _startFrame;
      // Clamp current frame to new range
      _currentFrame = _currentFrame.clamp(_startFrame, _endFrame);
    });

    // Update video controller
    _videoController.setPlaybackSpeed(speed);

    // Update frame range if it changed
    if (_startFrame != oldStartFrame || _endFrame != oldEndFrame) {
      _videoController.updateFrameRange(_startFrame, _endFrame);
      // Seek to start of new range
      _videoController.seekToFrame(_startFrame);
    }
  }

  /// Returns crop metadata if the feature flag is enabled and metadata exists
  CropMetadata? _getCropMetadata() {
    final bool useCropZoom = locator.get<FeatureFlagService>().getBool(
      FeatureFlag.useObservationCropZoom,
    );
    if (!useCropZoom) return null;
    return widget.observation.cropMetadata;
  }

  @override
  Widget build(BuildContext context) {
    // Use 90% of screen height like select_course_panel pattern
    final double screenHeight = MediaQuery.of(context).size.height;
    final double panelHeight = screenHeight * 0.9;

    return Container(
      height: panelHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                // User video (pro comparison hidden for now)
                SplitComparisonCard(
                  observation: widget.observation,
                  userVideoUrl: widget.videoUrl,
                  fps: widget.fps,
                  onFrameChanged: _onFrameChanged,
                  onPlayStateChanged: _onPlayStateChanged,
                  isScrubbingNotifier: _isScrubbingNotifier,
                  controller: _videoController,
                  showProComparison: false,
                  isLeftHanded: widget.isLeftHanded,
                  cropMetadata: _getCropMetadata(),
                  initialPlaybackSpeed: _playbackSpeed,
                  initialStartFrame: _startFrame,
                  initialEndFrame: _endFrame,
                  totalFrames: widget.totalFrames,
                ),

                // Frame slider (only show if there's a segment range)
                if (_hasSegment) ...[
                  const SizedBox(height: 12),
                  _buildFrameSlider(),
                ],
                const SizedBox(height: 16),

                // Show either measurement comparison or detected indicator
                if (widget.observation.measurement != null) ...[
                  MeasurementComparisonRow(
                    measurement: widget.observation.measurement!,
                    proMeasurement:
                        widget.observation.proReference?.proMeasurement,
                    proName: widget.observation.proReference?.proName,
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  _buildQualitativeIndicator(),
                  const SizedBox(height: 16),
                ],

                // Coaching content
                _buildCoachingSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrameSlider() {
    const double controlHeight = 36.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SenseiColors.gray[100]!),
        boxShadow: defaultCardBoxShadow(),
      ),
      child: Column(
        children: [
          // Slider (full width)
          _buildSliderWithMarker(),
          const SizedBox(height: 12),
          // Controls row: Play/Pause | Speed Pills | Mode Pills
          Row(
            children: [
              // Play/pause button
              _buildPlayPauseButton(),
              const SizedBox(width: 12),
              // Speed pills
              Expanded(
                child: PillButtonGroup(
                  height: controlHeight,
                  isDark: false,
                  hideBorder: false,
                  buttons: _availableSpeeds
                      .map(
                        (speed) => PillButtonData(
                          label: speed == 1.0 ? '1x' : speed.toString(),
                          isSelected: _playbackSpeed == speed,
                          onTap: () => _changePlaybackSpeed(speed),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              // Mode pills
              Expanded(
                child: PillButtonGroup(
                  height: controlHeight,
                  isDark: false,
                  hideBorder: false,
                  buttons: [
                    PillButtonData(
                      label: '↻',
                      isSelected: _playbackMode == PlaybackMode.loop,
                      onTap: _togglePlaybackMode,
                    ),
                    PillButtonData(
                      label: '⇄',
                      isSelected: _playbackMode == PlaybackMode.boomerang,
                      onTap: _togglePlaybackMode,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderWithMarker() {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        activeTrackColor: SenseiColors.cleanAccentColor,
        inactiveTrackColor: SenseiColors.gray[200],
        thumbColor: SenseiColors.cleanAccentColor,
        overlayColor: SenseiColors.cleanAccentColor.withValues(alpha: 0.2),
      ),
      child: Slider(
        value: _currentFrame.toDouble().clamp(
          _startFrame.toDouble(),
          _endFrame.toDouble(),
        ),
        min: _startFrame.toDouble(),
        max: _endFrame.toDouble(),
        onChanged: _onSliderChanged,
        onChangeStart: _onSliderStart,
        onChangeEnd: _onSliderEnd,
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    const double buttonSize = 36.0;

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SenseiColors.cleanAccentColor,
            SenseiColors.cleanAccentColorDark,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: defaultCardBoxShadow(),
      ),
      child: IconButton(
        onPressed: _togglePlayPause,
        icon: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
        ),
        iconSize: 22,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Main header with title and close button
          PanelHeader(
            title: widget.observation.observationName,
            onClose: () => Navigator.of(context).pop(),
          ),
          // Info row with category, type badge, and severity badge
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Row(
              children: [
                Text(
                  widget.observation.category.displayName,
                  style: TextStyle(fontSize: 12, color: SenseiColors.gray[500]),
                ),
                const SizedBox(width: 8),
                _buildTypeBadge(widget.observation.observationType),
                const Spacer(),
                if (widget.observation.severity != ObservationSeverity.none)
                  SeverityBadge(
                    severity: widget.observation.severity.displayName
                        .toLowerCase(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(ObservationType type) {
    final (Color color, String label) = switch (type) {
      ObservationType.positive => (const Color(0xFF10B981), 'Strength'),
      ObservationType.negative => (const Color(0xFFEF4444), 'Improve'),
      ObservationType.neutral => (SenseiColors.gray[500]!, 'Info'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildQualitativeIndicator() {
    final bool isPositive =
        widget.observation.observationType == ObservationType.positive;
    final Color color = isPositive
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final IconData icon = isPositive ? Icons.check_circle : Icons.error;
    final String label = isPositive ? 'Good form detected' : 'Issue detected';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SenseiColors.gray[100]!),
        boxShadow: defaultCardBoxShadow(),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.observation.coaching.summary,
                  style: TextStyle(
                    fontSize: 13,
                    color: SenseiColors.gray[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // What's happening
        _buildCoachingCard(
          icon: Icons.info_outline,
          title: "What's happening",
          content: widget.observation.coaching.explanation,
          color: SenseiColors.gray[600]!,
        ),

        // Pro comparison note (if available)
        if (widget.observation.proReference?.comparisonNote != null) ...[
          const SizedBox(height: 12),
          _buildCoachingCard(
            icon: Icons.compare_arrows,
            title: 'Pro comparison',
            content: widget.observation.proReference!.comparisonNote!,
            color: const Color(0xFF10B981),
          ),
        ],

        // How to fix
        if (widget.observation.coaching.fixSuggestion != null) ...[
          const SizedBox(height: 12),
          _buildCoachingCard(
            icon: Icons.lightbulb_outline,
            title: 'How to fix',
            content: widget.observation.coaching.fixSuggestion!,
            color: const Color(0xFF3B82F6),
          ),
        ],

        // Drill suggestion
        if (widget.observation.coaching.drillSuggestion != null) ...[
          const SizedBox(height: 12),
          _buildCoachingCard(
            icon: Icons.sports,
            title: 'Practice drill',
            content: widget.observation.coaching.drillSuggestion!,
            color: const Color(0xFF8B5CF6),
          ),
        ],
      ],
    );
  }

  Widget _buildCoachingCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SenseiColors.gray[100]!),
        boxShadow: defaultCardBoxShadow(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SenseiColors.gray[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: SenseiColors.gray[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
