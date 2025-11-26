import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/screens/round_history/round_history_screen.dart';
import 'package:turbo_disc_golf/screens/stats/stats_screen.dart';
import 'package:turbo_disc_golf/screens/test_ai_summary_screen.dart';
import 'package:turbo_disc_golf/screens/test_image_parsing_screen.dart';
import 'package:turbo_disc_golf/screens/test_roast_screen.dart';

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
    String appBarTitle;
    switch (_selectedIndex) {
      case 0:
        appBarTitle = 'Round History';
        break;
      case 1:
        appBarTitle = 'Add Round';
        break;
      case 2:
        appBarTitle = 'Stats';
        break;
      case 3:
        appBarTitle = 'Test AI Summary';
        break;
      case 4:
        appBarTitle = 'Test Image Parsing';
        break;
      case 5:
        appBarTitle = 'Test Roast';
        break;
      default:
        appBarTitle = 'Round History';
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
          hasBackButton: false,
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
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.add_circle),
            //   label: 'Add Round',
            // ),
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
              label: 'Test Image',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_fire_department),
              label: 'Test Roast',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
