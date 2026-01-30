import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/judgment/judgment_share_card.dart';
import 'package:turbo_disc_golf/components/judgment/judgment_verdict_card.dart';
import 'package:turbo_disc_golf/components/judgment/share_judgment/share_judgment_emoji_bg.dart';
import 'package:turbo_disc_golf/components/judgment/share_judgment/share_judgment_verdict.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/share_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_type.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Full-screen preview of the judgment share card.
///
/// Displays the share card in a full-screen view with a transparent app bar
/// and a share button at the bottom.
class ShareJudgmentPreviewScreen extends StatefulWidget {
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
  State<ShareJudgmentPreviewScreen> createState() =>
      _ShareJudgmentPreviewScreenState();
}

class _ShareJudgmentPreviewScreenState
    extends State<ShareJudgmentPreviewScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isSharing = false;
  late final LoggingServiceBase _logger;

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': ShareJudgmentPreviewScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('ShareJudgmentPreviewScreen');
  }

  Future<void> _shareCard() async {
    if (_isSharing) return;

    _logger.track(
      'Share Judgment Button Tapped',
      properties: {'is_glaze': widget.isGlaze},
    );

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
      locator.get<ToastService>().show(
        message: 'Copied to clipboard! Ready to share.',
        type: ToastType.success,
        duration: const Duration(seconds: 2),
        icon: Icons.check,
        iconSize: 18,
      );
    }

    if (mounted) {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).viewPadding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        appBar: GenericAppBar(
          topViewPadding: topPadding,
          title: '',
          backgroundColor: Colors.transparent,
        ),
        body: Stack(
          children: [
            ShareJudgmentEmojiBg(isGlaze: widget.isGlaze),
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: autoBottomPadding(context),
                top: MediaQuery.of(context).viewPadding.top + 24,
              ),
              child: Column(
                children: [
                  // Full-screen share card
                  ShareJudgmentVerdict(isGlaze: widget.isGlaze),
                  const SizedBox(height: 8),
                  Expanded(
                    child: FittedBox(
                      child: JudgmentShareCard(
                        isGlaze: widget.isGlaze,
                        headline: widget.headline,
                        tagline: widget.tagline,
                        round: widget.round,
                        analysis: widget.analysis,
                        highlightStats: widget.highlightStats,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBottomBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return PrimaryButton(
      width: double.infinity,
      height: 56,
      label: widget.isGlaze ? 'Share my glaze' : 'Share my roast',
      icon: Icons.ios_share,
      gradientBackground: widget.isGlaze
          ? const [Color(0xFF137e66), Color(0xFF1a9f7f)]
          : const [Color(0xFFFF6B6B), Color(0xFFFF8A8A)],
      loading: _isSharing,
      onPressed: _shareCard,
    );
  }
}
