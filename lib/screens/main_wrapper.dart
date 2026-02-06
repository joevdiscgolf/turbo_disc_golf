// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
// import 'package:turbo_disc_golf/components/custom_cupertino_action_sheet.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/screens/form_analysis/form_analysis_history_screen.dart';
import 'package:turbo_disc_golf/screens/round_history/round_history_screen.dart';
import 'package:turbo_disc_golf/screens/settings/settings_screen.dart';
import 'package:turbo_disc_golf/screens/stats/stats_screen.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/state/form_analysis_history_cubit.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/utils/navigation_helpers.dart';
import 'package:wiredash/wiredash.dart';

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

    // Wrap with AnnotatedRegion to ensure dark status bar icons on light background
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
      child: _buildContent(context, flags),
    );
  }

  Widget _buildContent(BuildContext context, FeatureFlagService flags) {
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
    return Scaffold(
      backgroundColor: SenseiColors.gray.shade50,
      appBar: _MainWrapperAppBar(
        topViewPadding: MediaQuery.of(context).viewPadding.top,
        titleIcon: _buildAppTitleIcon(),
        titleStyle: _buildAppTitleStyle(),
        leftWidget: _buildSettingsButton(
          context,
          RoundHistoryScreen.screenName,
        ),
        rightWidget: _buildFeedbackButton(context),
      ),
      body: RoundHistoryScreen(
        topViewPadding: MediaQuery.of(context).viewPadding.top,
        bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
      ),
    );
  }

  /// Build MainWrapper with Form Analysis tab alongside Round History.
  /// Shows 2 tabs: Rounds and Form Coach.
  Widget _buildWithFormAnalysisTabs(BuildContext context) {
    return BlocProvider<FormAnalysisHistoryCubit>.value(
      value: locator.get<FormAnalysisHistoryCubit>(),
      child: Scaffold(
        backgroundColor: SenseiColors.gray.shade50,
        appBar: _MainWrapperAppBar(
          topViewPadding: MediaQuery.of(context).viewPadding.top,
          titleIcon: _buildAppTitleIcon(),
          titleStyle: _buildAppTitleStyle(),
          leftWidget: _buildSettingsButton(
            context,
            _selectedIndex == 0
                ? RoundHistoryScreen.screenName
                : FormAnalysisHistoryScreen.screenName,
          ),
          rightWidget: _buildRightWidget(context),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            RoundHistoryScreen(
              topViewPadding: MediaQuery.of(context).viewPadding.top,
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
            items: [
              const BottomNavigationBarItem(
                icon: Text('🥏', style: TextStyle(fontSize: 20)),
                label: 'Rounds',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Text('📹', style: TextStyle(fontSize: 20)),
                    Positioned(
                      right: -12,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'beta',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                label: 'Form Coach',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
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

    return Scaffold(
      backgroundColor: SenseiColors.gray.shade50,
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
        backgroundColor: SenseiColors.gray.shade50,
        leftWidget: _selectedIndex == 0
            ? _buildSettingsButton(context, RoundHistoryScreen.screenName)
            : null,
        rightWidget: _buildFeedbackButton(context),
        rightWidgetWidth: 90,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          RoundHistoryScreen(
            topViewPadding: MediaQuery.of(context).viewPadding.top,
            bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
          ),
          // const RecordRoundScreen(),
          const StatsScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Stats'),
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
    );
  }

  Widget? _buildRightWidget(BuildContext context) {
    // Form Coach tab - show delete button in debug mode alongside feedback
    // if (_selectedIndex == 1 && kDebugMode) {
    //   return Row(
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       _buildFeedbackButton(context),
    //       const SizedBox(width: 8),
    //       _buildDeleteButton(context),
    //     ],
    //   );
    // }
    return _buildFeedbackButton(context);
  }

  Widget _buildFeedbackButton(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          _logger.track('Send Feedback Button Tapped');
          HapticFeedback.lightImpact();
          final String? uid = locator.get<AuthService>().currentUid;
          Wiredash.of(context).show(
            options: WiredashFeedbackOptions(
              collectMetaData: (metaData) => metaData..userId = uid,
            ),
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SenseiColors.gray[300]!, width: 1.5),
          ),
          child: Center(
            child: Text(
              'Feedback',
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: SenseiColors.gray[400],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppTitleIcon() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset(
        'assets/icon/app_icon_clear_bg.png',
        width: 32,
        height: 32,
      ),
    );
  }

  TextStyle _buildAppTitleStyle() {
    return GoogleFonts.exo2(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic,
      letterSpacing: -0.5,
      color: SenseiColors.gray.shade600,
    );
  }

  Widget _buildSettingsButton(BuildContext context, String currentScreenName) {
    return Center(
      child: GestureDetector(
        onTap: () {
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
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: SenseiColors.gray[400]!, width: 1.5),
          ),
          child: Center(
            child: Icon(Icons.person, size: 18, color: SenseiColors.gray[400]),
          ),
        ),
      ),
    );
  }

  // Widget _buildDeleteButton(BuildContext context) {
  //   return Center(
  //     child: IconButton(
  //       icon: const Icon(Icons.delete_forever, size: 24),
  //       onPressed: () {
  //         _logger.track('Delete All Analyses Button Tapped');
  //         HapticFeedback.lightImpact();
  //         _showDeleteConfirmation(context);
  //       },
  //     ),
  //   );
  // }

  // void _showDeleteConfirmation(BuildContext context) {
  //   _logger.track(
  //     'Modal Opened',
  //     properties: {
  //       'modal_type': 'action_sheet',
  //       'modal_name': 'Delete All Analyses Confirmation',
  //     },
  //   );

  //   showCupertinoModalPopup(
  //     context: context,
  //     builder: (dialogContext) => CustomCupertinoActionSheet(
  //       title: 'Delete all analysis data?',
  //       message:
  //           'This will permanently delete all form analysis records and Cloud Storage images. This cannot be undone. (DEBUG MODE ONLY)',
  //       destructiveActionLabel: 'Delete all',
  //       onDestructiveActionPressed: () {
  //         _logger.track('Delete All Analyses Confirmed');
  //         Navigator.pop(dialogContext);
  //         final FormAnalysisHistoryCubit historyCubit = locator
  //             .get<FormAnalysisHistoryCubit>();
  //         historyCubit.deleteAllAnalyses();
  //       },
  //       onCancelPressed: () {
  //         _logger.track('Delete All Analyses Cancelled');
  //         Navigator.pop(dialogContext);
  //       },
  //     ),
  //   );
  // }
}

class _MainWrapperAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _MainWrapperAppBar({
    required this.topViewPadding,
    required this.titleIcon,
    required this.titleStyle,
    this.leftWidget,
    this.rightWidget,
  });

  final double topViewPadding;
  final Widget titleIcon;
  final TextStyle titleStyle;
  final Widget? leftWidget;
  final Widget? rightWidget;

  static const double _appBarHeight = 48;

  @override
  Size get preferredSize => Size.fromHeight(_appBarHeight + topViewPadding);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: topViewPadding),
      height: preferredSize.height,
      color: SenseiColors.gray.shade50,
      child: Stack(
        children: [
          // Centered title (always in the middle of the screen)
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                titleIcon,
                const SizedBox(width: 8),
                Text('ScoreSensei', style: titleStyle),
              ],
            ),
          ),
          // Left and right widgets with padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left widget (aligned left)
                if (leftWidget != null)
                  leftWidget!
                else
                  const SizedBox.shrink(),
                // Spacer pushes right widget to the right
                const Spacer(),
                // Right widget (aligned right)
                if (rightWidget != null)
                  rightWidget!
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
