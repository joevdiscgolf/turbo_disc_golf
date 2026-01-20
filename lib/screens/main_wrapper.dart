import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/form_analysis/form_analysis_history_screen.dart';
import 'package:turbo_disc_golf/screens/round_history/round_history_screen.dart';
import 'package:turbo_disc_golf/screens/settings/settings_screen.dart';
import 'package:turbo_disc_golf/screens/stats/stats_screen.dart';
import 'package:turbo_disc_golf/screens/test_ai_summary_screen.dart';
import 'package:turbo_disc_golf/screens/test_image_parsing_screen.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/state/form_analysis_history_cubit.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/utils/navigation_helpers.dart';

class MainWrapper extends StatefulWidget {
  static const String screenName = 'Main Wrapper';

  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  late final LoggingServiceBase _logger;
  int _selectedIndex = 0;

  // Tab names for form analysis tab mode
  static const List<String> _formAnalysisTabNames = ['Rounds', 'Form Coach'];
  // Tab names for bottom navigation mode
  static const List<String> _bottomNavTabNames = [
    'Rounds',
    'Stats',
    'Test AI',
    'Test Image',
    'Test Roast',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': MainWrapper.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('MainWrapper');
  }

  void _onItemTapped(int index) {
    final FeatureFlagService flags = locator.get<FeatureFlagService>();
    final List<String> tabNames = flags.useFormAnalysisTab
        ? _formAnalysisTabNames
        : _bottomNavTabNames;

    final String previousTabName = tabNames[_selectedIndex];
    final String newTabName = tabNames[index];

    _logger.track(
      'Tab Changed',
      properties: {
        'tab_index': index,
        'tab_name': newTabName,
        'previous_tab_index': _selectedIndex,
        'previous_tab_name': previousTabName,
      },
    );

    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final FeatureFlagService flags = locator.get<FeatureFlagService>();

    // Form Analysis tab mode takes precedence
    if (flags.useFormAnalysisTab) {
      return _buildWithFormAnalysisTabs(context);
    }
    if (!flags.useBottomNavigationBar) {
      return _buildRoundHistoryOnly(context);
    }
    return _buildWithBottomNavigation(context);
  }

  Widget _buildRoundHistoryOnly(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEEE8F5),
            Color(0xFFECECEE),
            Color(0xFFE8F4E8),
            Color(0xFFEAE8F0),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GenericAppBar(
          topViewPadding: MediaQuery.of(context).viewPadding.top,
          title: 'ScoreSensei',
          titleIcon: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/icon/app_icon_clear_bg.png',
              width: 28,
              height: 28,
            ),
          ),
          titleStyle: GoogleFonts.exo2(
            fontSize: 20,
            fontWeight: FontWeight.w700, // SemiBold/Bold
            fontStyle: FontStyle.italic, // optional sporty slant
            letterSpacing: 0.5,
            color: SenseiColors.senseiBlue,
          ),
          hasBackButton: false,
          leftWidget: _buildSettingsButton(
            context,
            RoundHistoryScreen.screenName,
          ),
        ),
        body: RoundHistoryScreen(
          bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
        ),
      ),
    );
  }

  /// Build MainWrapper with Form Analysis tab alongside Round History.
  /// Shows 2 tabs: Rounds and Form Coach.
  Widget _buildWithFormAnalysisTabs(BuildContext context) {
    final String appBarTitle = _selectedIndex == 0
        ? 'ScoreSensei'
        : 'Form Coach';

    return BlocProvider<FormAnalysisHistoryCubit>.value(
      value: locator.get<FormAnalysisHistoryCubit>(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEEE8F5),
              Color(0xFFECECEE),
              Color(0xFFE8F4E8),
              Color(0xFFEAE8F0),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: GenericAppBar(
            topViewPadding: MediaQuery.of(context).viewPadding.top,
            title: appBarTitle,
            titleIcon: _selectedIndex == 0
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/icon/app_icon_clear_bg.png',
                      width: 28,
                      height: 28,
                    ),
                  )
                : null,
            titleStyle: _selectedIndex == 0
                ? GoogleFonts.exo2(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                    color: SenseiColors.senseiBlue,
                  )
                : null,
            hasBackButton: false,
            leftWidget: _buildLeftWidget(context),
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              RoundHistoryScreen(
                bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
              ),
              FormAnalysisHistoryScreen(
                bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
                topViewPadding: MediaQuery.of(context).viewPadding.top,
              ),
            ],
          ),
          bottomNavigationBar: Theme(
            data: Theme.of(context).copyWith(
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              backgroundColor: const Color(0xFFFFFFFF).withValues(alpha: 0.95),
              selectedItemColor: Colors.blue,
              unselectedItemColor: const Color(0xFF6B7280),
              selectedLabelStyle: const TextStyle(fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              showSelectedLabels: true,
              showUnselectedLabels: true,
              enableFeedback: false,
              items: const [
                BottomNavigationBarItem(
                  icon: Text('🥏', style: TextStyle(fontSize: 20)),
                  label: 'Rounds',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.school, size: 24),
                  label: 'Form Coach',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWithBottomNavigation(BuildContext context) {
    String appBarTitle;
    switch (_selectedIndex) {
      case 0:
        appBarTitle = 'ScoreSensei';
        break;
      case 1:
        appBarTitle = 'Add round';
        break;
      case 2:
        appBarTitle = 'Stats';
        break;
      case 3:
        appBarTitle = 'Test AI summary';
        break;
      case 4:
        appBarTitle = 'Test image parsing';
        break;
      case 5:
        appBarTitle = 'Test roast';
        break;
      case 6:
        appBarTitle = 'Settings';
      default:
        appBarTitle = 'ScoreSensei';
    }

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
          title: appBarTitle,
          titleIcon: _selectedIndex == 0
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/icon/app_icon_clear_bg.png',
                    width: 28,
                    height: 28,
                  ),
                )
              : null,
          hasBackButton: false,
          leftWidget: _selectedIndex == 0
              ? _buildSettingsButton(context, RoundHistoryScreen.screenName)
              : null,
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            RoundHistoryScreen(
              bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
            ),
            // const RecordRoundScreen(),
            const StatsScreen(),
            const TestAiSummaryScreen(),
            const TestImageParsingScreen(),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xFFFFFFFF).withValues(alpha: 0.95),
          selectedItemColor: const Color(0xFFB8E986),
          unselectedItemColor: const Color(0xFF6B7280),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.play_arrow),
              label: 'Rounds',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology),
              label: 'Test AI',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.image_search),
              label: 'Test image',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_fire_department),
              label: 'Test roast',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }

  Widget? _buildLeftWidget(BuildContext context) {
    if (_selectedIndex == 0) {
      return _buildSettingsButton(context, RoundHistoryScreen.screenName);
    } else if (_selectedIndex == 1) {
      if (kDebugMode) {
        return _buildDeleteButton(context);
      }
      // When Form Analysis tab is selected
      return _buildSettingsButton(
        context,
        FormAnalysisHistoryScreen.screenName,
      );
    }
    return null;
  }

  Widget _buildSettingsButton(BuildContext context, String currentScreenName) {
    return Center(
      child: IconButton(
        icon: const Icon(Icons.person, size: 24),
        onPressed: () {
          // Track analytics with dynamic screen name
          _logger.track(
            'Settings Button Tapped',
            properties: {
              'screen_name': currentScreenName,
              'button_location': 'Header',
            },
          );

          HapticFeedback.lightImpact();
          pushCupertinoRoute(context, const SettingsScreen());
        },
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return Center(
      child: IconButton(
        icon: const Icon(Icons.delete_forever, size: 24),
        onPressed: () {
          _logger.track('Delete All Analyses Button Tapped');
          HapticFeedback.lightImpact();
          _showDeleteConfirmation(context);
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    _logger.track(
      'Modal Opened',
      properties: {
        'modal_type': 'dialog',
        'modal_name': 'Delete All Analyses Confirmation',
      },
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete All Analysis Data?'),
        content: const Text(
          'This will permanently delete:\n\n'
          '• All form analysis records\n'
          '• All Cloud Storage images\n'
          '• Cannot be undone\n\n'
          'DEBUG MODE ONLY',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _logger.track('Delete All Analyses Cancelled');
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _logger.track('Delete All Analyses Confirmed');
              Navigator.pop(dialogContext);
              final FormAnalysisHistoryCubit historyCubit = locator
                  .get<FormAnalysisHistoryCubit>();
              historyCubit.deleteAllAnalyses();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );
  }
}
