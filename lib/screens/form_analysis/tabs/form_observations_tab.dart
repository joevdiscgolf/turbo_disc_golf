import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/arm_speed_chart_card.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/form_observations_v2_view.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/observation_category_section.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/observation_segment_player.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/arm_speed_data.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_response_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observations.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observations_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/observation_enums.dart';
import 'package:turbo_disc_golf/models/feature_flags/feature_flag.dart';
import 'package:turbo_disc_golf/models/handedness.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Flag to control whether to use FormObservationsV2 (named keys) or v1 (list-based)
const bool kUseFormObservationsV2 = true;

class FormObservationsTab extends StatefulWidget {
  static const String screenName = 'Form Observations';

  const FormObservationsTab({
    super.key,
    required this.analysis,
    this.topPadding = 0,
  });

  final FormAnalysisResponseV2 analysis;

  /// Top padding for the content (e.g., for app bar spacing).
  final double topPadding;

  @override
  State<FormObservationsTab> createState() => _FormObservationsTabState();
}

class _FormObservationsTabState extends State<FormObservationsTab>
    with AutomaticKeepAliveClientMixin {
  late final LoggingServiceBase _logger;
  FormObservation? _activeObservation;

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': FormObservationsTab.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('FormObservationsTab');
  }

  FormObservations? get _observationsV1 => widget.analysis.formObservations;
  FormObservationsV2? get _observationsV2 => widget.analysis.formObservationsV2;
  ArmSpeedData? get _armSpeed => widget.analysis.armSpeed;
  CameraAngle get _cameraAngle => widget.analysis.analysisResults.cameraAngle;
  bool get _isRearAngle => _cameraAngle == CameraAngle.rear;
  bool get _showArmSpeed =>
      locator.get<FeatureFlagService>().getBool(FeatureFlag.showArmSpeed);

  /// Returns true if there are observations available (checks v2 or v1 based on flag)
  bool get _hasObservations {
    if (kUseFormObservationsV2) {
      return _observationsV2 != null && _observationsV2!.isNotEmpty;
    }
    return _observationsV1 != null && _observationsV1!.isNotEmpty;
  }

  /// Returns observations grouped by category (from v1 only - v2 uses its own widget)
  Map<ObservationCategory, List<FormObservation>> get _observationsByCategory {
    return _observationsV1?.byCategory ?? {};
  }

  void _handleObservationTap(FormObservation observation) {
    _logger.track(
      'Observation Card Tapped',
      properties: {
        'observation_id': observation.observationId,
        'observation_name': observation.observationName,
        'category': observation.category.value,
        'severity': observation.severity.value,
        'has_segment': observation.hasVideoSegment,
      },
    );

    final String? videoUrl = widget.analysis.videoMetadata.skeletonVideoUrl;
    if (videoUrl != null && observation.hasVideoSegment) {
      _showSegmentPlayer(observation);
    }
  }

  void _showSegmentPlayer(FormObservation observation) {
    _logger.track(
      'Modal Opened',
      properties: {
        'modal_type': 'bottom_sheet',
        'modal_name': 'Observation Segment Player',
        'observation_id': observation.observationId,
        'has_segment': observation.hasVideoSegment,
      },
    );

    setState(() {
      _activeObservation = observation;
    });

    // Calculate fps from video metadata
    final double fps = widget.analysis.videoMetadata.videoDurationSeconds > 0
        ? widget.analysis.videoMetadata.totalFrames /
              widget.analysis.videoMetadata.videoDurationSeconds
        : 30.0;

    final bool isLeftHanded =
        widget.analysis.analysisResults.detectedHandedness == Handedness.left;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ObservationSegmentPlayer(
          observation: observation,
          videoUrl: widget.analysis.videoMetadata.skeletonVideoUrl!,
          fps: fps,
          isLeftHanded: isLeftHanded,
        );
      },
    ).then((_) {
      setState(() {
        _activeObservation = null;
      });
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Show specific empty state for rear angle (observations not supported)
    if (_isRearAngle) {
      return _buildRearAngleEmptyState();
    }

    final bool hasArmSpeed = _armSpeed != null && _showArmSpeed;

    if (!_hasObservations && !hasArmSpeed) {
      return _buildEmptyState();
    }

    return _buildObservationsList();
  }

  Widget _buildRearAngleEmptyState() {
    const Color accentColor = Color(0xFF6366F1); // Indigo accent

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SenseiColors.gray[50]!,
            Colors.white,
            SenseiColors.gray[50]!,
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: widget.topPadding,
          left: 32,
          right: 32,
          bottom: 32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Concentric circles icon section
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withValues(alpha: 0.1),
                    accentColor.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.1),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.videocam_outlined,
                    size: 40,
                    color: accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Title
            Text(
              'Side view only',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: SenseiColors.darkGray,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Description
            Text(
              'Form observations are currently only available for side angle videos.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: SenseiColors.gray[500],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(
          top: widget.topPadding + 32,
          left: 32,
          right: 32,
          bottom: 32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_off_outlined,
              size: 48,
              color: SenseiColors.gray[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No observations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: SenseiColors.gray[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Form observations will appear here when detected during analysis.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: SenseiColors.gray[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservationsList() {
    // Use v2 widget when flag is enabled
    if (kUseFormObservationsV2 && _observationsV2 != null) {
      return _buildV2ObservationsList();
    }
    return _buildV1ObservationsList();
  }

  Widget _buildV2ObservationsList() {
    return ListView(
      padding: EdgeInsets.only(
        top: widget.topPadding + 4,
        left: 16,
        right: 16,
        bottom: 132,
      ),
      children: [
        // Overall score card at the top
        _buildOverallScoreCard(),
        const SizedBox(height: 16),
        // Arm speed chart (collapsible)
        if (_armSpeed != null && _showArmSpeed) ...[
          ArmSpeedChartCard(armSpeedData: _armSpeed!),
          const SizedBox(height: 24),
        ],
        // V2 observations view with all keys rendered
        FormObservationsV2View(
          observations: _observationsV2!,
          onObservationTap: _handleObservationTap,
          activeObservationId: _activeObservation?.observationId,
        ),
      ],
    );
  }

  Widget _buildOverallScoreCard() {
    final int scorePercent = (_observationsV2!.overallScore * 100).round();
    final Color scoreColor = _getScoreColor(scorePercent);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SenseiColors.gray[100]!),
        boxShadow: defaultCardBoxShadow(),
      ),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scoreColor.withValues(alpha: 0.15),
                  scoreColor.withValues(alpha: 0.08),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$scorePercent',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Label and count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall form score',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: SenseiColors.gray[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_observationsV2!.observations.length} observations analyzed',
                  style: TextStyle(
                    fontSize: 13,
                    color: SenseiColors.gray[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int scorePercent) {
    if (scorePercent >= 80) {
      return const Color(0xFF059669); // Darker green for contrast
    } else if (scorePercent >= 60) {
      return const Color(0xFFD97706); // Darker amber for contrast
    } else {
      return const Color(0xFFDC2626); // Darker red for contrast
    }
  }

  Widget _buildV1ObservationsList() {
    final Map<ObservationCategory, List<FormObservation>> byCategory =
        _observationsByCategory;

    return ListView(
      padding: EdgeInsets.only(
        top: widget.topPadding + 4,
        left: 16,
        right: 16,
        bottom: 132,
      ),
      children: [
        // Arm speed chart at the top
        if (_armSpeed != null && _showArmSpeed) ...[
          ArmSpeedChartCard(armSpeedData: _armSpeed!),
          const SizedBox(height: 24),
        ],
        // Observation categories
        ...byCategory.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: ObservationCategorySection(
              category: entry.key,
              observations: entry.value,
              onObservationTap: _handleObservationTap,
              activeObservationId: _activeObservation?.observationId,
            ),
          );
        }),
      ],
    );
  }
}
