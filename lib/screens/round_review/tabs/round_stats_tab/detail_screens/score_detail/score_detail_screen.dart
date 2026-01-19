import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/score_detail/tabs/course_tab/course_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/score_detail/tabs/scores_tab/scores_tab.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';

/// Detail screen that shows course and scores information
class ScoreDetailScreen extends StatefulWidget {
  static const String screenName = 'Score Detail';
  static const String routeName = '/score-detail';

  final DGRound round;

  const ScoreDetailScreen({super.key, required this.round});

  @override
  State<ScoreDetailScreen> createState() => _ScoreDetailScreenState();
}

class _ScoreDetailScreenState extends State<ScoreDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final LoggingServiceBase _logger;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize scoped logger
    _logger = locator.get<LoggingService>().withBaseProperties({
      'screen_name': ScoreDetailScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('ScoreDetailScreen');

    // Track tab changes
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final List<String> tabNames = ['Course', 'Scores'];
      _logger.track(
        'Score Detail Tab Changed',
        properties: {
          'tab_index': _tabController.index,
          'tab_name': tabNames[_tabController.index],
        },
      );
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEEE8F5), // Light gray with faint purple tint
            Color(0xFFECECEE), // Light gray
            Color(0xFFE8F4E8), // Light gray with faint green tint
            Color(0xFFEAE8F0), // Light gray with subtle purple
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GenericAppBar(
          topViewPadding: MediaQuery.of(context).viewPadding.top,
          title: 'Score details',
          bottomWidget: TabBar(
            controller: _tabController,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.black,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            labelPadding: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            indicatorPadding: EdgeInsets.zero,
            tabs: const [
              Tab(text: 'Course'),
              Tab(text: 'Scores'),
            ],
          ),
          bottomWidgetHeight: 48,
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            CourseTab(round: widget.round),
            ScoresTab(round: widget.round),
          ],
        ),
      ),
    );
  }
}
