import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Elegant full-screen error state for AI generation failures.
/// Used by Story and Judgment tabs when content generation fails.
class GenerationErrorState extends StatelessWidget {
  final String title;
  final String? errorMessage;
  final VoidCallback onRetry;
  final Color accentColor;
  final IconData icon;

  const GenerationErrorState({
    super.key,
    required this.title,
    this.errorMessage,
    required this.onRetry,
    this.accentColor = const Color(0xFFEF4444),
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SenseiColors.gray[50]!,
            Colors.white,
            SenseiColors.gray[50]!,
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: autoBottomPadding(context),
        ),
        child: Column(
          children: [
            const Spacer(flex: 2),
            _buildIconSection(),
            const SizedBox(height: 32),
            _buildTextSection(context),
            const Spacer(flex: 2),
            _buildRetryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildIconSection() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.1),
            accentColor.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor.withValues(alpha: 0.1),
          ),
          child: Icon(icon, size: 40, color: accentColor),
        ),
      ),
    );
  }

  Widget _buildTextSection(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: SenseiColors.darkGray,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (errorMessage != null && errorMessage!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: SenseiColors.gray[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: SenseiColors.gray[500],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatErrorMessage(errorMessage!),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SenseiColors.gray[600],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Please check your connection and try again',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: SenseiColors.gray[400]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatErrorMessage(String message) {
    // Remove "Failed to generate story: " or similar prefixes for cleaner display
    String formatted = message
        .replaceFirst(RegExp(r'^Failed to generate \w+:\s*'), '')
        .replaceFirst(RegExp(r'^Exception:\s*'), '');

    // Capitalize first letter
    if (formatted.isNotEmpty) {
      formatted = formatted[0].toUpperCase() + formatted.substring(1);
    }

    return formatted;
  }

  Widget _buildRetryButton() {
    return PrimaryButton(
      width: double.infinity,
      height: 56,
      label: 'Try again',
      icon: Icons.refresh_rounded,
      gradientBackground: [accentColor.withValues(alpha: 0.9), accentColor],
      onPressed: onRetry,
    );
  }
}
