import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/app_bar/app_bar_back_button.dart';

class GenericAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GenericAppBar({
    super.key,
    required this.topViewPadding,
    required this.title,
    this.rightWidget,
    this.bottomWidget,
    this.bottomWidgetHeight,
    this.backgroundColor,
    this.foregroundColor,
    this.hasBackButton = true,
  });

  final String title;
  final double topViewPadding;
  final Widget? rightWidget;
  final Widget? bottomWidget;
  final double? bottomWidgetHeight;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool hasBackButton;

  @override
  Size get preferredSize =>
      Size.fromHeight(56 + topViewPadding + (bottomWidgetHeight ?? 0));

  static const double backButtonTouchTargetWidth = 60;
  static const double rightPadding = 12;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: topViewPadding),
      height: preferredSize.height,
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 0, right: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 40,
                  width: backButtonTouchTargetWidth,
                  child: hasBackButton
                      ? AppBarBackButton(color: foregroundColor)
                      : null,
                ),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: Center(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: foregroundColor,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  width: backButtonTouchTargetWidth - rightPadding,
                  child: rightWidget,
                ),
              ],
            ),
          ),
          if (bottomWidget != null) bottomWidget!,
        ],
      ),
    );
  }
}
