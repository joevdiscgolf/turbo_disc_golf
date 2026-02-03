import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class ShareJudgmentVerdict extends StatelessWidget {
  const ShareJudgmentVerdict({super.key, required this.isGlaze});

  final bool isGlaze;

  @override
  Widget build(BuildContext context) {
    final String emoji = isGlaze ? '\u{1F369}' : '\u{1F525}';

    // Use PNG images if enabled, otherwise use text
    final FeatureFlagService flags = locator.get<FeatureFlagService>();
    if (flags.useVerdictImages) {
      final String imagePath = isGlaze
          ? 'assets/judge_tab/glazed_clear_crop_2.png'
          : 'assets/judge_tab/roasted_clear_crop_3.png';
      // PNG transparency is preserved automatically by Flutter
      return Image.asset(imagePath, height: 100, fit: BoxFit.contain);
    }

    final String verdictText = isGlaze ? 'You got glazed' : 'You got roasted';
    final TextStyle textStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w900,
      color: SenseiColors.gray[700]!,
    );

    // No drip/fire effects on share card - they overlap with the card below
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 8),
        Text(verdictText, style: textStyle),
      ],
    );
  }
}
