import 'dart:math' as math;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class SpinnerButton extends StatefulWidget {
  const SpinnerButton({
    super.key,
    this.height = 32,
    this.width,
    this.disabled = false,
    this.repeat = true,
    required this.onPressed,
    required this.title,
    this.iconData,
    this.iconColor = TurbColors.darkGray,
    this.iconSize = 16,
    this.backgroundColor = TurbColors.blue,
    this.shadowColor,
    this.textSize = 14,
    this.textColor = TurbColors.darkGray,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  final double height;
  final double? width;
  final Function onPressed;
  final String title;
  final IconData? iconData;
  final Color iconColor;
  final double iconSize;
  final Color backgroundColor;
  final Color? shadowColor;
  final double textSize;
  final Color textColor;
  final EdgeInsetsGeometry? padding;
  final bool disabled;
  final bool repeat;

  @override
  State<SpinnerButton> createState() => _SpinnerButtonState();
}

class _SpinnerButtonState extends State<SpinnerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _rotation;
  late bool _repeat;

  @override
  void initState() {
    _repeat = widget.repeat;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    final CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.decelerate,
    );
    _rotation =
        Tween<double>(begin: 0, end: 2 * math.pi).animate(curvedAnimation)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && _repeat) {
              _animationController.forward(from: 0);
            }
          });

    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _repeat = widget.repeat;
    return Bounceable(
      onTap: () {
        HapticFeedback.lightImpact();
        if (!widget.disabled) {
          _animationController.forward(from: 0);
          widget.onPressed();
        }
      },
      child: Container(
        height: widget.height,
        width: widget.width,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.disabled
              ? TurbColors.gray[100]
              : widget.backgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _rotation,
              builder: (BuildContext context, Widget? child) =>
                  Transform.rotate(
                    angle: _rotation.value,
                    child: Icon(
                      FlutterRemix.refresh_line,
                      size: widget.iconSize,
                      color: widget.iconColor,
                    ),
                  ),
            ),
            const SizedBox(width: 8),
            AutoSizeText(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: widget.disabled ? TurbColors.white : widget.textColor,
                fontSize: widget.textSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
