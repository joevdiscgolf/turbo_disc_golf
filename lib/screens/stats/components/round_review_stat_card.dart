import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/components/custom_expandables.dart';

/// Reusable card widget for displaying statistics
class RoundReviewStatCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  final Color? accentColor;
  final Widget? expandedSection;
  final bool hasArrow;
  final Function? onPressed;

  const RoundReviewStatCard({
    super.key,
    required this.title,
    this.icon,
    required this.children,
    this.accentColor,
    this.expandedSection,
    this.hasArrow = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (expandedSection != null) {
      return CustomExpandableCard(
        expandedWidget: expandedSection!,
        cardColor: Theme.of(context).colorScheme.surface,
        horizontalPadding: 16,
        child: _mainBody(context),
      );
    } else {
      return _mainBody(context);
    }
  }

  Widget _mainBody(BuildContext context) {
    if (onPressed != null) {
      return GestureDetector(
        onTap: () {
          onPressed!();
        },
        child: _cardBody(context),
      );
    } else {
      return _cardBody(context);
    }
  }

  Widget _cardBody(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: accentColor ?? Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (hasArrow)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    FlutterRemix.arrow_right_s_line,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
