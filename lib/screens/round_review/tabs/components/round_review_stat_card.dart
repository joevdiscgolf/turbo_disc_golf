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

/// Widget for displaying a stat row with label and value
class StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const StatRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying a percentage bar
class PercentageBar extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;
  final String? subtitle;

  const PercentageBar({
    super.key,
    required this.label,
    required this.percentage,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying a comparison between two stats
class ComparisonWidget extends StatelessWidget {
  final String label1;
  final String label2;
  final double value1;
  final double value2;
  final String? subtitle1;
  final String? subtitle2;
  final Color positiveColor;
  final Color negativeColor;

  const ComparisonWidget({
    super.key,
    required this.label1,
    required this.label2,
    required this.value1,
    required this.value2,
    this.subtitle1,
    this.subtitle2,
    this.positiveColor = const Color(0xFF00F5D4),
    this.negativeColor = const Color(0xFFFF7A7A),
  });

  @override
  Widget build(BuildContext context) {
    final bool firstIsBetter = value1 > value2;
    final color1 = firstIsBetter ? positiveColor : negativeColor;
    final color2 = firstIsBetter ? negativeColor : positiveColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _ComparisonItem(
              label: label1,
              value: value1,
              subtitle: subtitle1,
              color: color1,
              alignment: Alignment.centerLeft,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'VS',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: _ComparisonItem(
              label: label2,
              value: value2,
              subtitle: subtitle2,
              color: color2,
              alignment: Alignment.centerRight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonItem extends StatelessWidget {
  final String label;
  final double value;
  final String? subtitle;
  final Color color;
  final Alignment alignment;

  const _ComparisonItem({
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: alignment == Alignment.centerLeft
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Widget for displaying a metric with icon
class MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? valueColor;

  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
