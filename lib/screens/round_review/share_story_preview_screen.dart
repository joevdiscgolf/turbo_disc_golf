import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/share/share_preview_screen.dart';
import 'package:turbo_disc_golf/components/story/story_highlights_share_card.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/structured_story_content.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Full-screen preview of the story share card.
///
/// This is a thin wrapper around SharePreviewScreen that configures
/// the story-specific card, styling, and behavior.
class ShareStoryPreviewScreen extends StatelessWidget {
  static const String screenName = 'Share Story Preview';
  static const String routeName = '/share-story-preview';

  const ShareStoryPreviewScreen({
    super.key,
    required this.round,
    required this.analysis,
    required this.roundTitle,
    required this.overview,
    this.shareableHeadline,
    this.shareHighlightStats,
  });

  final DGRound round;
  final RoundAnalysis analysis;
  final String roundTitle;
  final String overview;
  final String? shareableHeadline;
  final List<ShareHighlightStat>? shareHighlightStats;

  @override
  Widget build(BuildContext context) {
    final String caption =
        '\u{1F4D6} $roundTitle\n\n${round.courseName}\nShared from Turbo Disc Golf';

    return SharePreviewScreen(
      screenName: ShareStoryPreviewScreen.screenName,
      cardWidget: StoryHighlightsShareCard(
        round: round,
        analysis: analysis,
        roundTitle: roundTitle,
        overview: overview,
        shareableHeadline: shareableHeadline,
        shareHighlightStats: shareHighlightStats,
      ),
      shareButtonLabel: 'Share my story',
      shareButtonGradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      shareCaption: caption,
      shareFilename: 'round_story',
      backgroundEmojis: const ['\u{1F94F}'], // Flying disc
      randomSeed: round.versionId.hashCode,
      emojiBackgroundColor: SenseiColors.gray.shade100,
    );
  }
}
