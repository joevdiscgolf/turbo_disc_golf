import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/judgment/judgment_share_card.dart';
import 'package:turbo_disc_golf/components/judgment/share_judgment/share_judgment_verdict.dart';
import 'package:turbo_disc_golf/components/share/share_preview_screen.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';

/// Full-screen preview of the judgment share card.
///
/// This is a thin wrapper around SharePreviewScreen that configures
/// the judgment-specific card, styling, and behavior.
class ShareJudgmentPreviewScreen extends StatelessWidget {
  static const String screenName = 'Share Judgment Preview';
  static const String routeName = '/share-judgment-preview';

  const ShareJudgmentPreviewScreen({
    super.key,
    required this.isGlaze,
    required this.headline,
    required this.tagline,
    required this.round,
    required this.analysis,
    required this.highlightStats,
  });

  final bool isGlaze;
  final String headline;
  final String tagline;
  final DGRound round;
  final RoundAnalysis analysis;
  final List<String> highlightStats;

  @override
  Widget build(BuildContext context) {
    final String emoji = isGlaze ? '\u{1F369}' : '\u{1F525}';
    final String caption =
        '$emoji $headline\n\n${round.courseName}\nShared from Turbo Disc Golf';

    return SharePreviewScreen(
      screenName: ShareJudgmentPreviewScreen.screenName,
      cardWidget: JudgmentShareCard(
        isGlaze: isGlaze,
        headline: headline,
        tagline: tagline,
        round: round,
        analysis: analysis,
        highlightStats: highlightStats,
      ),
      headerWidget: ShareJudgmentVerdict(isGlaze: isGlaze),
      shareButtonLabel: isGlaze ? 'Share my glaze' : 'Share my roast',
      shareButtonGradient: isGlaze
          ? const [Color(0xFF137e66), Color(0xFF1a9f7f)]
          : const [Color(0xFFFF6B6B), Color(0xFFFF8A8A)],
      shareCaption: caption,
      shareFilename: 'judgment_${isGlaze ? 'glaze' : 'roast'}',
      backgroundEmojis: [emoji],
      randomSeed: round.versionId.hashCode,
      analyticsProperties: {'is_glaze': isGlaze},
    );
  }
}
