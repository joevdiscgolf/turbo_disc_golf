import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/models/shot_detail.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/models/throw_type_stats.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/shared/components/shot_shape_card.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';

/// Detail screen showing shot shape breakdown for a specific throw type
class ThrowTypeDetailScreen extends StatefulWidget {
  static const String screenName = 'Throw Type Detail';
  static const String routeName = '/throw-type-detail';

  const ThrowTypeDetailScreen({
    super.key,
    required this.throwType,
    required this.overallStats,
    required this.shotShapeStats,
    required this.overallShotDetails,
    required this.shotShapeDetails,
  });

  final String throwType;
  final ThrowTypeStats overallStats;
  final List<ShotShapeStats> shotShapeStats;
  final List<ShotDetail> overallShotDetails;
  final Map<String, List<ShotDetail>> shotShapeDetails;

  @override
  State<ThrowTypeDetailScreen> createState() => _ThrowTypeDetailScreenState();
}

class _ThrowTypeDetailScreenState extends State<ThrowTypeDetailScreen>
    with TickerProviderStateMixin {
  bool _isOverallExpanded = false;
  late AnimationController _overallAnimationController;
  final Map<String, bool> _shotShapeExpanded = {};
  final Map<String, AnimationController> _shotShapeAnimationControllers = {};
  late final LoggingServiceBase _logger;

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': ThrowTypeDetailScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('ThrowTypeDetailScreen');

    // Initialize overall animation controller - start collapsed
    _overallAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Initialize animation controllers for shot shapes - start collapsed
    for (final shape in widget.shotShapeStats) {
      _shotShapeAnimationControllers[shape.shapeName] = AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    _overallAnimationController.dispose();
    for (final controller in _shotShapeAnimationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: GenericAppBar(
        topViewPadding: MediaQuery.of(context).viewPadding.top,
        title: widget.overallStats.displayName,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ThrowStatsCard(
            title: widget.overallStats.displayName,
            shotDetails: widget.overallShotDetails,
            averageDistance: widget.overallStats.averageThrowDistance?.round(),
            isExpanded: _isOverallExpanded,
            animationController: _overallAnimationController,
            showThrowTechnique: false,
            useLandingSpotAbbreviations: false,
            onToggleExpand: () {
              setState(() {
                _isOverallExpanded = !_isOverallExpanded;
              });
              if (_isOverallExpanded) {
                _overallAnimationController.forward();
              } else {
                _overallAnimationController.reverse();
              }
            },
          ),
          const SizedBox(height: 16),
          if (widget.shotShapeStats.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Shot Shape Breakdown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            ...widget.shotShapeStats.map(
              (shape) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ThrowStatsCard(
                  title: shape.displayName,
                  shotDetails: widget.shotShapeDetails[shape.shapeName] ?? [],
                  isExpanded: _shotShapeExpanded[shape.shapeName] ?? false,
                  animationController: _shotShapeAnimationControllers[shape.shapeName]!,
                  showThrowTechnique: false,
                  useLandingSpotAbbreviations: false,
                  onToggleExpand: () {
                    setState(() {
                      _shotShapeExpanded[shape.shapeName] =
                          !(_shotShapeExpanded[shape.shapeName] ?? false);
                    });
                    final controller = _shotShapeAnimationControllers[shape.shapeName];
                    if (controller != null) {
                      if (_shotShapeExpanded[shape.shapeName] ?? false) {
                        controller.forward();
                      } else {
                        controller.reverse();
                      }
                    }
                  },
                ),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.insights_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No shot shape data available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
