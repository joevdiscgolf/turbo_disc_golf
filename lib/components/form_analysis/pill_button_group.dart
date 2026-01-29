import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Data class for a single pill button in a pill button group.
class PillButtonData {
  const PillButtonData({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
}

/// A group of pill-style toggle buttons with rounded corners and borders.
///
/// This widget displays a horizontal row of buttons with:
/// - Rounded border on the group container
/// - Dividers between buttons
/// - Selected/unselected states with different backgrounds
/// - Proper clipping to respect border radius
class PillButtonGroup extends StatelessWidget {
  const PillButtonGroup({
    super.key,
    required this.buttons,
    required this.isDark,
    this.height,
    this.hideBorder = false,
  });

  final List<PillButtonData> buttons;
  final double? height;
  final bool isDark;
  final bool hideBorder;

  // Dark Slate Overlay colors
  static const Color _darkTrackActive = Color(0xFF06B6D4);

  // Clean Sport Minimal colors
  static const Color _cleanAccentColor = Color(0xFF3B82F6);
  static const Color _cleanTextColor = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    final Color selectedBg = isDark ? _darkTrackActive : _cleanAccentColor;
    final Color selectedText = Colors.white;
    final Color unselectedBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white;
    final Color unselectedText = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : _cleanTextColor.withValues(alpha: 0.7);
    final Color borderColor = SenseiColors.gray[100]!;
    final Color dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : SenseiColors.gray[100]!;
    final double radius = height != null ? 12 : 16;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: hideBorder ? null : Border.all(color: borderColor, width: 1),
        boxShadow: defaultCardBoxShadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            if (i > 0) Container(width: 1, color: dividerColor),
            Expanded(
              child: _PillButton(
                data: buttons[i],
                selectedBg: selectedBg,
                selectedText: selectedText,
                unselectedBg: unselectedBg,
                unselectedText: unselectedText,
                isFirst: i == 0,
                isLast: i == buttons.length - 1,
                radius: radius,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single pill button within a pill button group.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.data,
    required this.selectedBg,
    required this.selectedText,
    required this.unselectedBg,
    required this.unselectedText,
    required this.isFirst,
    required this.isLast,
    required this.radius,
  });

  final PillButtonData data;
  final Color selectedBg;
  final Color selectedText;
  final Color unselectedBg;
  final Color unselectedText;
  final bool isFirst;
  final bool isLast;
  final double radius;

  @override
  Widget build(BuildContext context) {
    BorderRadius? borderRadius;
    if (isFirst && isLast) {
      borderRadius = BorderRadius.circular(radius);
    } else if (isFirst) {
      borderRadius = BorderRadius.only(
        topLeft: Radius.circular(radius),
        bottomLeft: Radius.circular(radius),
      );
    } else if (isLast) {
      borderRadius = BorderRadius.only(
        topRight: Radius.circular(radius),
        bottomRight: Radius.circular(radius),
      );
    }

    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: data.isSelected ? selectedBg : unselectedBg,
          borderRadius: borderRadius,
        ),
        child: Text(
          data.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: data.isSelected ? FontWeight.w600 : FontWeight.w500,
            color: data.isSelected ? selectedText : unselectedText,
          ),
        ),
      ),
    );
  }
}
