import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({super.key, this.onPressed});

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
            Icon(
              FlutterRemix.apple_fill,
              color: TurbColors.gray[700],
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Apple',
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
