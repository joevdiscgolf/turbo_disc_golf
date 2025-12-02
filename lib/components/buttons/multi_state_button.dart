import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

enum ButtonState { normal, loading, success, retry }

class MultiStateButton extends StatelessWidget {
  const MultiStateButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.iconData,
    this.height = 50,
    this.width,
    this.backgroundColor = Colors.blue,
    this.iconColor = Colors.white,
    this.textColor = Colors.white,
    this.textSize = 16,
    this.fontWeight = FontWeight.normal,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    this.shadowColor,
    this.borderColor,
    this.borderRadius = 24,
    this.buttonState = ButtonState.normal,
    this.disabled = false,
    this.underline = false,
  });

  final String title;
  final Function onPressed;
  final IconData? iconData;
  final double height;
  final double? width;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final Color? shadowColor;
  final Color? borderColor;
  final double textSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final ButtonState buttonState;
  final bool disabled;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    return Bounceable(
      onTap: () {
        if (!disabled) {
          HapticFeedback.lightImpact();
          onPressed();
        }
      },
      child: Container(
        height: height,
        width: width,
        padding: padding,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 2),
              color: shadowColor ?? Colors.transparent,
              blurRadius: 2,
              spreadRadius: 0,
            ),
          ],
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: _getBorderColor(), width: 1),
          color: disabled ? TurbColors.gray[100] : backgroundColor,
        ),
        child: _buildChild(context),
      ),
    );
  }

  Widget _buildChild(BuildContext context) {
    switch (buttonState) {
      case ButtonState.normal:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (iconData != null) ...[
              Icon(iconData, color: iconColor, size: 20),
              const SizedBox(width: 10),
            ],
            AutoSizeText(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: disabled ? Colors.white : textColor,
                fontSize: textSize,
                decoration: underline ? TextDecoration.underline : null,
                fontWeight: fontWeight,
              ),
              maxLines: 1,
            ),
          ],
        );
      case ButtonState.loading:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: FittedBox(child: CircularProgressIndicator(color: textColor)),
        );
      case ButtonState.success:
        return SizedBox(
          height: 16,
          width: 16,
          child: FittedBox(
            child: Icon(FlutterRemix.check_line, color: textColor, size: 16),
          ),
        );
      case ButtonState.retry:
        return SizedBox(
          height: 16,
          width: 16,
          child: FittedBox(
            child: Icon(FlutterRemix.restart_line, color: textColor, size: 16),
          ),
        );
    }
  }

  Color _getBorderColor() {
    if (disabled) {
      return TurbColors.gray[100]!;
    } else if (borderColor != null) {
      return borderColor!;
    } else {
      return Colors.transparent;
    }
  }
}
