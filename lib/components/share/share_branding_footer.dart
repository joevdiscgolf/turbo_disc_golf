import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Branding footer for share images.
///
/// Displays the ScoreSensei logo with a glow effect and the app name
/// in a prominent, branded style. Used at the bottom of shareable composites.
class ShareBrandingFooter extends StatelessWidget {
  const ShareBrandingFooter({
    super.key,
    this.logoSize = 40,
    this.fontSize = 24,
  });

  final double logoSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/icon/app_icon_clear_bg.png',
          height: logoSize,
          width: logoSize,
          // color: Colors.black,
          colorBlendMode: BlendMode.srcIn,
        ),
        const SizedBox(width: 4),
        Text(
          'ScoreSensei',
          style: GoogleFonts.exo2(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.5,
            color: SenseiColors.gray.shade600,
          ),
        ),
      ],
    );
  }
}
