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
  });

  final String title;
  final double topViewPadding;
  final Widget? rightWidget;
  final Widget? bottomWidget;
  final double? bottomWidgetHeight;
  final Color? backgroundColor;

  @override
  Size get preferredSize =>
      Size.fromHeight(56 + topViewPadding + (bottomWidgetHeight ?? 0));

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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const AppBarBackButton(size: 40),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 40, child: rightWidget),
              ],
            ),
          ),
          if (bottomWidget != null) bottomWidget!,
        ],
      ),
    );
  }
}
