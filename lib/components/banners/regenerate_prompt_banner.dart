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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // "X left" indicator in top right
          if (regenerationsRemaining != null)
            Positioned(
              top: -4,
              right: 0,
              child: Text(
                '$regenerationsRemaining left',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          // Main content row
          Row(
            children: [
              const Icon(
                Icons.edit_note,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildRegenerateButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegenerateButton() {
    final bool isDisabled = isLoading || !_canRegenerate;

    return OutlinedButton(
      onPressed: isDisabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              onRegenerate();
            },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(
          color: Colors.white.withValues(alpha: isDisabled ? 0.4 : 1.0),
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              _canRegenerate ? 'Regenerate' : 'Limit reached',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
    );
  }
}
