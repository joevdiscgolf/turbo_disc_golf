import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/judgment/judgment_share_card.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/services/share_service.dart';

/// Full-screen preview of the judgment share card.
///
/// Displays the share card in a full-screen view with a transparent app bar
/// and a share button at the bottom.
class ShareJudgmentPreviewScreen extends StatefulWidget {
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
  State<ShareJudgmentPreviewScreen> createState() =>
      _ShareJudgmentPreviewScreenState();
}

class _ShareJudgmentPreviewScreenState
    extends State<ShareJudgmentPreviewScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareCard() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    final ShareService shareService = locator.get<ShareService>();

    final String emoji = widget.isGlaze ? '\u{1F369}' : '\u{1F525}';
    final String caption =
        '$emoji ${widget.headline}\n\n${widget.round.courseName}\nShared from Turbo Disc Golf';

    final bool success = await shareService.captureAndShare(
      _shareCardKey,
      caption: caption,
      filename: 'judgment_${widget.isGlaze ? 'glaze' : 'roast'}',
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
            child: JudgmentShareCard(
              isGlaze: widget.isGlaze,
              headline: widget.headline,
              tagline: widget.tagline,
              round: widget.round,
              analysis: widget.analysis,
              highlightStats: widget.highlightStats,
            ),
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

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: PrimaryButton(
          width: double.infinity,
          height: 56,
          label: widget.isGlaze ? 'Share my glaze' : 'Share my roast',
          icon: Icons.ios_share,
          gradientBackground: widget.isGlaze
              ? const [Color(0xFF137e66), Color(0xFF1a9f7f)]
              : const [Color(0xFFFF6B6B), Color(0xFFFF8A8A)],
          loading: _isSharing,
          onPressed: _shareCard,
        ),
      ),
    );
  }
}
