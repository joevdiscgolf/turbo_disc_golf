import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/score_detail/score_detail_screen.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/drives_detail_screen.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/mistakes_detail/mistakes_detail_screen.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/putt_detail/putting_detail_screen.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';

/// Shared navigation helper for story renderers (v1 and v2)
/// Handles navigation from stat cards to detail screens
class StoryNavigationHelper {
  /// Maps card ID to detail screen widget and title
  static ({Widget screen, String title})? getDetailScreenForCardId(
    String cardId,
    DGRound round,
  ) {
    // Handle parameterized cards - no specific detail screen yet
    if (cardId.startsWith('DISC_PERFORMANCE:') ||
        cardId.startsWith('HOLE_TYPE:')) {
      return null;
    }

    // Remove suffixes like _CIRCLE or _BAR if present
    String baseCardId = cardId;
    if (cardId.endsWith('_CIRCLE') || cardId.endsWith('_BAR')) {
      baseCardId = cardId.substring(0, cardId.lastIndexOf('_'));
    }

    switch (baseCardId) {
      // Putting cards -> Putting detail screen
      case 'C1X_PUTTING':
      case 'C2_PUTTING':
        return (screen: PuttingDetailScreen(round: round), title: 'Putting');

      // Driving cards -> Driving detail screen
      case 'FAIRWAY_HIT':
      case 'C1_IN_REG':
      case 'OB_RATE':
      case 'PARKED':
        return (screen: DrivesDetailScreen(round: round), title: 'Driving');

      // Scoring cards -> Score detail screen
      case 'BIRDIES':
      case 'BIRDIE_RATE':
      case 'BOGEY_RATE':
      case 'PAR_RATE':
      case 'SCORING':
      case 'EAGLES':
      case 'PARS':
        return (screen: ScoreDetailScreen(round: round), title: 'Scores');

      // Mistakes card -> Mistakes detail screen
      case 'MISTAKES':
        return (screen: MistakesDetailScreen(round: round), title: 'Mistakes');

      // Throw type and shot shape -> Drives tab
      case 'THROW_TYPE_COMPARISON':
      case 'SHOT_SHAPE_BREAKDOWN':
        return (screen: DrivesDetailScreen(round: round), title: 'Driving');

      // Performance tracking cards -> Scores
      case 'BOUNCE_BACK':
      case 'HOT_STREAK':
      case 'FLOW_STATE':
        return (screen: ScoreDetailScreen(round: round), title: 'Scores');

      default:
        return null;
    }
  }

  /// Navigate to detail screen for the given card ID
  static void navigateToDetailScreen(
    BuildContext context,
    String cardId,
    DGRound round,
  ) {
    final detailScreen = getDetailScreenForCardId(cardId, round);
    if (detailScreen == null) {
      debugPrint('No detail screen configured for card ID: $cardId');
      return;
    }

    if (!context.mounted) return;

    final Widget screenWithAppBar = StoryDetailScreenWrapper(
      title: detailScreen.title,
      child: detailScreen.screen,
    );

    if (locator
        .get<FeatureFlagService>()
        .useCustomPageTransitionsForRoundReview) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              screenWithAppBar,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade + scale animation for card expansion effect
            const begin = 0.92;
            const end = 1.0;
            const curve = Curves.easeInOut;

            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            final scaleAnimation = animation.drive(tween);

            final fadeAnimation = animation.drive(CurveTween(curve: curve));

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(scale: scaleAnimation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else {
      Navigator.of(
        context,
      ).push(CupertinoPageRoute(builder: (context) => screenWithAppBar));
    }
  }
}

/// Detail Screen Wrapper for story navigation
/// Provides consistent styling with gradient background and app bar
class StoryDetailScreenWrapper extends StatelessWidget {
  const StoryDetailScreenWrapper({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

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
          title: title,
          backgroundColor: Colors.transparent,
        ),
        body: child,
      ),
    );
  }
}
