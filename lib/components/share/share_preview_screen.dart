import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/share/offscreen_capture_target.dart';
import 'package:turbo_disc_golf/components/share/share_branding_footer.dart';
import 'package:turbo_disc_golf/components/share/shareable_composite.dart';
import 'package:turbo_disc_golf/components/share/share_screen_emoji_background.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/share_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_type.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// A generic share preview screen that displays a shareable card.
///
/// This component handles the common layout, share functionality, and
/// analytics for all share preview screens in the app.
class SharePreviewScreen extends StatefulWidget {
  const SharePreviewScreen({
    super.key,
    required this.screenName,
    required this.cardWidget,
    required this.shareButtonLabel,
    required this.shareButtonGradient,
    required this.shareCaption,
    required this.shareFilename,
    required this.backgroundEmojis,
    this.headerWidget,
    this.randomSeed,
    this.backgroundColor = Colors.white,
    this.emojiBackgroundColor,
    this.analyticsProperties,
  });

  /// Screen name for analytics tracking
  final String screenName;

  /// The share card widget to display (should be a pure component)
  final Widget cardWidget;

  /// Label for the share button
  final String shareButtonLabel;

  /// Gradient colors for the share button
  final List<Color> shareButtonGradient;

  /// Caption text to share with the image
  final String shareCaption;

  /// Filename for the shared image
  final String shareFilename;

  /// List of emojis to display in the background
  final List<String> backgroundEmojis;

  /// Optional header widget to display above the card
  final Widget? headerWidget;

  /// Optional seed for deterministic emoji placement
  final int? randomSeed;

  /// Background color of the screen
  final Color backgroundColor;

  /// Background color behind the emojis (defaults to transparent)
  final Color? emojiBackgroundColor;

  /// Additional analytics properties to track
  final Map<String, dynamic>? analyticsProperties;

  @override
  State<SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends State<SharePreviewScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isSharing = false;
  late final LoggingServiceBase _logger;

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': widget.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression(widget.screenName);
  }

  Future<void> _shareCard() async {
    if (_isSharing) return;

    // Track share button tap with optional additional properties
    final Map<String, dynamic> trackingProperties = {
      if (widget.analyticsProperties != null) ...widget.analyticsProperties!,
    };

    _logger.track(
      'Share Button Tapped',
      properties: trackingProperties.isNotEmpty ? trackingProperties : null,
    );

    setState(() => _isSharing = true);

    final ShareService shareService = locator.get<ShareService>();

    final bool success = await shareService.captureAndShare(
      _shareCardKey,
      caption: widget.shareCaption,
      filename: widget.shareFilename,
    );

    if (!success && mounted) {
      Clipboard.setData(ClipboardData(text: widget.shareCaption));
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
        backgroundColor: widget.backgroundColor,
        extendBodyBehindAppBar: true,
        appBar: GenericAppBar(
          topViewPadding: topPadding,
          title: '',
          hasBackButton: false,
          backgroundColor: Colors.transparent,
          rightWidget: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () {
              HapticFeedback.lightImpact();
              _logger.track('Close Share Preview Button Tapped');
              Navigator.pop(context);
            },
          ),
        ),
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            // Visible emoji background for preview
            ShareScreenEmojiBackground(
              emojis: widget.backgroundEmojis,
              randomSeed: widget.randomSeed,
              backgroundColor:
                  widget.emojiBackgroundColor ?? Colors.transparent,
            ),
            // Visible content for preview - shows what the shared image will look like
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: autoBottomPadding(context),
                top: topPadding + 24,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: _buildPreviewCard(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildShareButton(),
                ],
              ),
            ),
            // Off-screen capture target for generating share image
            OffscreenCaptureTarget(
              captureKey: _shareCardKey,
              child: ShareableComposite(
                backgroundColor: widget.backgroundColor,
                backgroundWidget: widget.backgroundEmojis.isNotEmpty
                    ? ShareableEmojiBackground(
                        emojis: widget.backgroundEmojis,
                        randomSeed: widget.randomSeed,
                      )
                    : null,
                headerWidget: widget.headerWidget,
                contentWidget: widget.cardWidget,
                footerWidget: const ShareBrandingFooter(),
                footerSpacing: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a preview that matches the full-screen aspect ratio of the shared image.
  /// This shows users exactly what the captured image will look like.
  Widget _buildPreviewCard(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double aspectRatio = screenSize.width / screenSize.height;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background emojis (same as captured image)
            if (widget.backgroundEmojis.isNotEmpty)
              ShareableEmojiBackground(
                emojis: widget.backgroundEmojis,
                randomSeed: widget.randomSeed,
              ),
            // Centered content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.headerWidget != null) ...[
                      widget.headerWidget!,
                      const SizedBox(height: 12),
                    ],
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: widget.cardWidget,
                    ),
                    const SizedBox(height: 8),
                    const ShareBrandingFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    return PrimaryButton(
      width: double.infinity,
      height: 56,
      label: widget.shareButtonLabel,
      icon: Icons.ios_share,
      gradientBackground: widget.shareButtonGradient,
      loading: _isSharing,
      onPressed: _shareCard,
    );
  }
}
