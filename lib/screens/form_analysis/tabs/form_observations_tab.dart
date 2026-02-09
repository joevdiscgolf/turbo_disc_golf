import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/observation_category_section.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/observation_segment_player.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/arm_speed_chart_card.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_response_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observations.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/observation_enums.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/arm_speed_data.dart';
import 'package:turbo_disc_golf/models/feature_flags/feature_flag.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

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

  FormObservations? get _observations => widget.analysis.formObservations;
  ArmSpeedData? get _armSpeed => widget.analysis.armSpeed;
  CameraAngle get _cameraAngle => widget.analysis.analysisResults.cameraAngle;
  bool get _isRearAngle => _cameraAngle == CameraAngle.rear;
  bool get _showArmSpeed =>
      locator.get<FeatureFlagService>().getBool(FeatureFlag.showArmSpeed);

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

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ObservationSegmentPlayer(
          observation: observation,
          videoUrl: widget.analysis.videoMetadata.skeletonVideoUrl!,
          fps: fps,
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

    final bool hasObservations =
        _observations != null && _observations!.isNotEmpty;
    final bool hasArmSpeed = _armSpeed != null && _showArmSpeed;

    if (!hasObservations && !hasArmSpeed) {
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
    final Map<ObservationCategory, List<FormObservation>> byCategory =
        _observations?.byCategory ?? {};

    return ListView(
      padding: EdgeInsets.only(
        top: widget.topPadding + 4,
        left: 16,
        right: 16,
        bottom: 16,
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
