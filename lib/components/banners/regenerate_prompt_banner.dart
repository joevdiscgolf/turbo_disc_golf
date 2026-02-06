import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable banner prompting the user to regenerate AI content (Story/Roast).
///
/// Shows when round data has been edited and the AI content may be outdated.
class RegeneratePromptBanner extends StatelessWidget {
  const RegeneratePromptBanner({
    super.key,
    required this.onRegenerate,
    this.isLoading = false,
    required this.buttonSuffix,
    this.regenerationsRemaining,
  });

  final VoidCallback onRegenerate;

  final bool isLoading;

  final String buttonSuffix;

  final int? regenerationsRemaining;

  bool get _canRegenerate =>
      regenerationsRemaining == null || regenerationsRemaining! > 0;

  static const Color _backgroundColor = Color(0xFFEDF2F7); // Soft blue-gray
  static const Color _textColor = Color(0xFF4F46E5); // Indigo

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: _backgroundColor,
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Round updated',
                maxLines: 1,
                style: const TextStyle(
                  color: _textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _canRegenerate ? 'Regenerate $buttonSuffix' : 'Limit reached',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.refresh, size: 16),
              ],
            ),
    );
  }
}
