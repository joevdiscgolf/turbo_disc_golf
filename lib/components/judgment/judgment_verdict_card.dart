import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Animated verdict card that reveals the judgment result.
///
/// Features a scale-in animation with bounce effect and themed styling.
class JudgmentVerdictCard extends StatelessWidget {
  const JudgmentVerdictCard({
    super.key,
    required this.isGlaze,
    required this.headline,
    this.animate = true,
  });

  /// Whether this is a glaze (true) or roast (false).
  final bool isGlaze;

  /// The headline text (e.g., "Foxwood's New Overlord").
  final String headline;

  /// Whether to animate the card entrance.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = isGlaze
        ? const Color(0xFF2196F3)
        : const Color(0xFFFF6B6B);
    final Color darkColor = isGlaze
        ? const Color(0xFF1565C0)
        : const Color(0xFFD32F2F);

    Widget card = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.15),
            primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Icon
          isGlaze
              ? const Text(
                  '\u{1F369}', // Donut emoji
                  style: TextStyle(fontSize: 48),
                )
              : Icon(
                  Icons.local_fire_department,
                  size: 48,
                  color: primaryColor,
                ),
          const SizedBox(width: 16),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headline,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isGlaze
                      ? 'Excessive compliments incoming...'
                      : 'Brutal honesty incoming...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: darkColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!animate) {
      return card;
    }

    // Animate with scale and bounce
    return card
        .animate()
        .scale(
          duration: const Duration(milliseconds: 400),
          begin: const Offset(0.0, 0.0),
          end: const Offset(1.0, 1.0),
          curve: Curves.elasticOut,
        )
        .fadeIn(
          duration: const Duration(milliseconds: 200),
        );
  }
}

/// Large verdict announcement that appears during the celebrating phase.
class JudgmentVerdictAnnouncement extends StatelessWidget {
  const JudgmentVerdictAnnouncement({
    super.key,
    required this.isGlaze,
  });

  final bool isGlaze;

  @override
  Widget build(BuildContext context) {
    final Color color = isGlaze
        ? const Color(0xFFFFD700)
        : const Color(0xFFFF6B6B);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon with glow
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: isGlaze
              ? const Text(
                  '\u{1F369}', // Donut emoji
                  style: TextStyle(fontSize: 80),
                )
              : Icon(
                  Icons.local_fire_department,
                  size: 80,
                  color: color,
                ),
        )
            .animate()
            .scale(
              duration: const Duration(milliseconds: 500),
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
              curve: Curves.elasticOut,
            ),
        const SizedBox(height: 24),
        // Text announcement
        Text(
          isGlaze ? 'YOU GOT GLAZED!' : 'YOU GOT ROASTED!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: color,
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 20,
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: const Duration(milliseconds: 300))
            .slideY(
              duration: const Duration(milliseconds: 400),
              begin: 0.3,
              end: 0,
              curve: Curves.easeOut,
            ),
      ],
    );
  }
}
