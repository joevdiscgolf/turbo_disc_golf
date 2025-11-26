import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_remix/flutter_remix.dart';

class AppBarBackButton extends StatelessWidget {
  const AppBarBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.height = 40,
    this.width = 40,
  });

  final Function? onPressed;
  final Color? color;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Bounceable(
      child: Container(
        height: height,
        width: width,
        color: Colors.transparent,
        child: Center(
          child: Transform.translate(
            offset: Offset(-6, 0),
            child: Icon(
              FlutterRemix.arrow_left_s_line,
              color: color ?? Colors.black,
              size: 24,
            ),
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
