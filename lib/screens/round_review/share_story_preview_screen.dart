import 'dart:math';

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
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/share_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_type.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Full-screen preview of the story share card.
///
/// Displays the share card in a full-screen view with a transparent app bar
/// and a share button at the bottom.
class ShareStoryPreviewScreen extends StatefulWidget {
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
  State<ShareStoryPreviewScreen> createState() =>
      _ShareStoryPreviewScreenState();
}

class _ShareStoryPreviewScreenState extends State<ShareStoryPreviewScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isSharing = false;
  late final LoggingServiceBase _logger;

  int get _randomSeed => widget.round.versionId.hashCode;

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': ShareStoryPreviewScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('ShareStoryPreviewScreen');
  }

  Future<void> _shareCard() async {
    if (_isSharing) return;

    _logger.track('Share Story Button Tapped');

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
        body: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Stack(
            children: [
              BackgroundEmojisLayer(randomSeed: _randomSeed),
              Container(
                height: double.infinity,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: autoBottomPadding(context),
                ),
                child: Column(
                  children: [
                    // Full-screen share card
                    Expanded(
                      child: RepaintBoundary(
                        key: _shareCardKey,
                        child: _buildShareCard(),
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildShareButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareCard() {
    if (locator.get<FeatureFlagService>().useStoryPosterShareCard) {
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

  Widget _buildShareButton() {
    return PrimaryButton(
      width: double.infinity,
      height: 56,
      label: 'Share my story',
      icon: Icons.ios_share,
      gradientBackground: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      loading: _isSharing,
      onPressed: _shareCard,
    );
  }
}

class BackgroundEmojisLayer extends StatelessWidget {
  const BackgroundEmojisLayer({super.key, required this.randomSeed});

  final int randomSeed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SenseiColors.gray.shade100,
      height: double.infinity,
      width: double.infinity,
      child: Stack(children: _buildBackgroundEmojis(context)),
    );
  }

  /// Builds random background emojis
  List<Widget> _buildBackgroundEmojis(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    final Random random = Random(randomSeed);
    const String bgEmoji = '\u{1F94F}'; // Flying disc emoji
    final List<Widget> emojis = [];

    const int cols = 6;
    const int rows = 10;

    final double cellWidth = screenWidth / cols;
    final double cellHeight = screenHeight / rows;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final double offsetX = 0.1 + random.nextDouble() * 0.8;
        final double offsetY = 0.1 + random.nextDouble() * 0.8;

        final double left = col * cellWidth + offsetX * cellWidth;
        final double top = row * cellHeight + offsetY * cellHeight;

        final double rotation = (random.nextDouble() - 0.5) * 1.2;
        final double opacity = 0.05 + random.nextDouble() * 0.06;
        final double size = 14 + random.nextDouble() * 10;

        emojis.add(
          Positioned(
            top: top,
            left: left,
            child: Transform.rotate(
              angle: rotation,
              child: Opacity(
                opacity: opacity,
                child: Text(bgEmoji, style: TextStyle(fontSize: size)),
              ),
            ),
          ),
        );
      }
    }

    return emojis;
  }
}
