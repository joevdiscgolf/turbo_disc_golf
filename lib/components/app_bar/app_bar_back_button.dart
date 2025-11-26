import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_remix/flutter_remix.dart';

class AppBarBackButton extends StatelessWidget {
  const AppBarBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size = 48,
  });

  final Function? onPressed;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Bounceable(
      child: Container(
        height: size,
        width: size,
        color: Colors.transparent,
        child: Center(
          child: Icon(
            FlutterRemix.arrow_left_s_line,
            color: color ?? Colors.black,
            size: size * 0.6,
          ),
        ),
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        if (onPressed != null) {
          onPressed!();
        } else {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
