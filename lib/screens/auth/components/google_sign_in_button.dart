import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/svg_icon.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/icons.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: TurbColors.gray[300]!, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(48),
          ),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SvgIcon(
              assetPath: SvgIcons.google,
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: TurbColors.gray[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
