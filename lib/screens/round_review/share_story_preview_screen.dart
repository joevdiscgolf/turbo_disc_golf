import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/story/story_highlights_share_card.dart';
import 'package:turbo_disc_golf/components/story/story_poster_share_card.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/structured_story_content.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/services/share_service.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

/// Full-screen preview of the story share card.
///
/// Displays the share card in a full-screen view with a transparent app bar
/// and a share button at the bottom.
class ShareStoryPreviewScreen extends StatefulWidget {
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
  State<ShareStoryPreviewScreen> createState() =>
      _ShareStoryPreviewScreenState();
}

class _ShareStoryPreviewScreenState extends State<ShareStoryPreviewScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareCard() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    final ShareService shareService = locator.get<ShareService>();

    final String caption =
        '\u{1F4D6} ${widget.roundTitle}\n\n${widget.round.courseName}\nShared from Turbo Disc Golf';

    final bool success = await shareService.captureAndShare(
      _shareCardKey,
      caption: caption,
      filename: 'round_story',
    );

    if (!success && mounted) {
      Clipboard.setData(ClipboardData(text: caption));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard! Ready to share.'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    if (mounted) {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).viewPadding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: GenericAppBar(
        topViewPadding: topPadding,
        title: '',
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Full-screen share card
          RepaintBoundary(
            key: _shareCardKey,
            child: _buildShareCard(),
          ),
          // Share button overlay at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildShareCard() {
    if (useStoryPosterShareCard) {
      return StoryPosterShareCard(
        round: widget.round,
        analysis: widget.analysis,
        roundTitle: widget.roundTitle,
        overview: widget.overview,
        shareableHeadline: widget.shareableHeadline,
        shareHighlightStats: widget.shareHighlightStats,
      );
    } else {
      return StoryHighlightsShareCard(
        round: widget.round,
        analysis: widget.analysis,
        roundTitle: widget.roundTitle,
        overview: widget.overview,
        shareableHeadline: widget.shareableHeadline,
        shareHighlightStats: widget.shareHighlightStats,
      );
    }
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: PrimaryButton(
          width: double.infinity,
          height: 56,
          label: 'Share my story',
          icon: Icons.ios_share,
          gradientBackground: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          loading: _isSharing,
          onPressed: _shareCard,
        ),
      ),
    );
  }
}
