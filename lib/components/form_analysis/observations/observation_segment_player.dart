import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/measurement_gauge.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/split_comparison_card.dart';
import 'package:turbo_disc_golf/components/form_analysis/severity_badge.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/observation_enums.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart' show defaultCardBoxShadow;

/// Modal for viewing observation details with split comparison and frame slider
class ObservationSegmentPlayer extends StatefulWidget {
  const ObservationSegmentPlayer({
    super.key,
    required this.observation,
    required this.videoUrl,
    this.fps = 30.0,
  });

  final FormObservation observation;
  final String videoUrl;
  final double fps;

  @override
  State<ObservationSegmentPlayer> createState() =>
      _ObservationSegmentPlayerState();
}

class _ObservationSegmentPlayerState extends State<ObservationSegmentPlayer> {
  final SplitComparisonController _videoController = SplitComparisonController();
  final ValueNotifier<bool> _isScrubbingNotifier = ValueNotifier(false);

  int _currentFrame = 0;
  int _startFrame = 0;
  int _endFrame = 0;
  bool _hasSegment = false;

  /// Whether video is currently playing
  bool _isPlaying = true;

  /// Whether video was playing before scrubbing started
  bool _wasPlayingBeforeScrub = true;

  @override
  void initState() {
    super.initState();
    // Initialize frame range from observation
    _startFrame = widget.observation.timing.startFrame ??
        widget.observation.timing.frameNumber;
    _endFrame = widget.observation.timing.endFrame ??
        widget.observation.timing.frameNumber;
    _currentFrame = _startFrame;
    _hasSegment = _endFrame > _startFrame;
  }

  @override
  void dispose() {
    _isScrubbingNotifier.dispose();
    super.dispose();
  }

  void _onFrameChanged(int currentFrame, int startFrame, int endFrame) {
    if (mounted && !_isScrubbingNotifier.value) {
      setState(() {
        _currentFrame = currentFrame.clamp(startFrame, endFrame);
        _startFrame = startFrame;
        _endFrame = endFrame;
        _hasSegment = endFrame > startFrame;
      });
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
                // Split video comparison
                SplitComparisonCard(
                  observation: widget.observation,
                  userVideoUrl: widget.videoUrl,
                  fps: widget.fps,
                  onFrameChanged: _onFrameChanged,
                  onPlayStateChanged: _onPlayStateChanged,
                  isScrubbingNotifier: _isScrubbingNotifier,
                  controller: _videoController,
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
    final int totalFrames = _endFrame - _startFrame;
    final int relativeFrame = _currentFrame - _startFrame;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SenseiColors.gray[100]!),
        boxShadow: defaultCardBoxShadow(),
      ),
      child: Column(
        children: [
          // Slider row with play/pause button
          Row(
            children: [
              // Play/pause button
              _buildPlayPauseButton(),
              const SizedBox(width: 8),
              // Slider
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 16),
                    activeTrackColor: SenseiColors.gray[700],
                    inactiveTrackColor: SenseiColors.gray[200],
                    thumbColor: SenseiColors.gray[700],
                    overlayColor: SenseiColors.gray[700]!.withValues(alpha: 0.2),
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
                ),
              ),
            ],
          ),
          // Frame labels
          Padding(
            padding: const EdgeInsets.only(left: 44, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Frame ${relativeFrame + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: SenseiColors.gray[600],
                  ),
                ),
                Text(
                  'of ${totalFrames + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    color: SenseiColors.gray[400],
                  ),
                ),
              ],
            ),
          ),
        ],
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
                  style: TextStyle(
                    fontSize: 12,
                    color: SenseiColors.gray[500],
                  ),
                ),
                const SizedBox(width: 8),
                _buildTypeBadge(widget.observation.observationType),
                const Spacer(),
                if (widget.observation.severity != ObservationSeverity.none)
                  SeverityBadge(
                    severity:
                        widget.observation.severity.displayName.toLowerCase(),
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
    final Color color =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
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
            child: Icon(
              icon,
              size: 22,
              color: color,
            ),
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
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
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
