import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable banner prompting the user to regenerate AI content (Story/Roast).
///
/// Shows when round data has been edited and the AI content may be outdated.
class RegeneratePromptBanner extends StatelessWidget {
  /// Callback when the regenerate button is tapped.
  final VoidCallback onRegenerate;

  /// Whether regeneration is currently in progress.
  final bool isLoading;

  /// Main title text. Defaults to "Round edited".
  final String title;

  /// Subtitle text. Defaults to "Story may be outdated".
  final String subtitle;

  /// Number of regenerations remaining (0-2). Null to hide the indicator.
  final int? regenerationsRemaining;

  const RegeneratePromptBanner({
    super.key,
    required this.onRegenerate,
    this.isLoading = false,
    this.title = 'Round edited',
    this.subtitle = 'Story may be outdated',
    this.regenerationsRemaining,
  });

  bool get _canRegenerate =>
      regenerationsRemaining == null || regenerationsRemaining! > 0;

  static const Color _backgroundColor = Color(0xFFFFF3E0); // Light amber
  static const Color _textColor = Color(0xFFE65100); // Dark orange

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: _backgroundColor,
      child: Row(
        children: [
          const Icon(
            Icons.refresh,
            color: _textColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Story outdated',
                maxLines: 1,
                style: const TextStyle(
                  color: _textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          _buildRegenerateButton(),
        ],
      ),
    );
  }

  Widget _buildRegenerateButton() {
    final bool isDisabled = isLoading || !_canRegenerate;

    return TextButton(
      onPressed: isDisabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              onRegenerate();
            },
      style: TextButton.styleFrom(
        foregroundColor: _textColor,
        backgroundColor: _textColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        disabledForegroundColor: _textColor.withValues(alpha: 0.4),
      ),
      child: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_textColor),
              ),
            )
          : Text(
              _canRegenerate ? 'Regenerate' : 'Limit reached',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
