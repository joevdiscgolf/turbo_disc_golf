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
import 'package:turbo_disc_golf/screens/test_roast_screen.dart';
import 'package:turbo_disc_golf/state/form_analysis_history_cubit.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';
import 'package:turbo_disc_golf/utils/navigation_helpers.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Form Analysis tab mode takes precedence
    if (useFormAnalysisTab) {
      return _buildWithFormAnalysisTabs(context);
    }
    if (!useBottomNavigationBar) {
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
            color: TurbColors.senseiBlue,
          ),
          hasBackButton: false,
          rightWidget: _buildSettingsButton(context),
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
    final String appBarTitle = _selectedIndex == 0 ? 'ScoreSensei' : 'Form Coach';

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
                  color: TurbColors.senseiBlue,
                )
              : null,
          hasBackButton: false,
          rightWidget: _buildRightWidget(context),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            RoundHistoryScreen(
              bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
            ),
            FormAnalysisHistoryScreen(
              bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
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
              ? _buildSettingsButton(context)
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
            const TestRoastScreen(),
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

  Widget? _buildRightWidget(BuildContext context) {
    if (_selectedIndex == 0) {
      return _buildSettingsButton(context);
    } else if (_selectedIndex == 1 && kDebugMode) {
      return _buildDeleteButton(context);
    }
    return null;
  }

  Widget _buildSettingsButton(BuildContext context) {
    return Center(
      child: IconButton(
        icon: const Icon(Icons.settings, size: 24),
        onPressed: () {
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
          HapticFeedback.lightImpact();
          _showDeleteConfirmation(context);
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final FormAnalysisHistoryCubit historyCubit =
                  locator.get<FormAnalysisHistoryCubit>();
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
