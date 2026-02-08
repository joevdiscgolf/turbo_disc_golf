import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/observation_category_section.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/observation_segment_player.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/wrist_speed_chart_card.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_response_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observations.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/observation_enums.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/wrist_speed_data.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class FormObservationsTab extends StatefulWidget {
  static const String screenName = 'Form Observations';

  const FormObservationsTab({
    super.key,
    required this.analysis,
    required this.videoUrl,
    this.skeletonVideoUrl,
  });

  final FormAnalysisResponseV2 analysis;
  final String? videoUrl;

  /// URL for skeleton overlay video (preferred for observations)
  final String? skeletonVideoUrl;

  @override
  State<FormObservationsTab> createState() => _FormObservationsTabState();
}

class _FormObservationsTabState extends State<FormObservationsTab> {
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
  WristSpeedData? get _wristSpeed => widget.analysis.wristSpeed;

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

    if (widget.videoUrl != null && observation.hasVideoSegment) {
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
        // Prefer skeleton overlay video for observations
        final String effectiveVideoUrl =
            widget.skeletonVideoUrl ?? widget.videoUrl!;
        return ObservationSegmentPlayer(
          observation: observation,
          videoUrl: effectiveVideoUrl,
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
  Widget build(BuildContext context) {
    final bool hasObservations = _observations != null && _observations!.isNotEmpty;
    final bool hasWristSpeed = _wristSpeed != null;

    if (!hasObservations && !hasWristSpeed) {
      return _buildEmptyState();
    }

    return _buildObservationsList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
      padding: const EdgeInsets.all(16),
      children: [
        // Wrist speed chart at the top
        if (_wristSpeed != null) ...[
          WristSpeedChartCard(wristSpeedData: _wristSpeed!),
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
