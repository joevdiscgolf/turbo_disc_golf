import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Default elevation for cards with drop shadow
const double defaultCardElevation = 2.0;

/// Default shadow color for cards
Color get defaultCardShadowColor => Colors.black.withValues(alpha: 0.3);

/// Default card shape with rounded corners
ShapeBorder defaultCardShape({double borderRadius = 12.0}) {
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(borderRadius),
  );
}

/// Default card box shadow for use in BoxDecoration
/// Returns a `List<BoxShadow>` matching the default card elevation style
List<BoxShadow> defaultCardBoxShadow() {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
}

List<Widget> addRunSpacing(
  List<Widget> children, {
  double runSpacing = 8,
  Axis axis = Axis.horizontal,
}) {
  final Widget spacerWidget = axis == Axis.horizontal
      ? SizedBox(width: runSpacing)
      : SizedBox(height: runSpacing);
  final List<Widget> spacedChildren = [];
  for (int i = 0; i < children.length; i++) {
    spacedChildren.add(children[i]);
    if (i < children.length - 1) {
      spacedChildren.add(spacerWidget);
    }
  }
  return spacedChildren;
}

List<Widget> addDividers(
  List<Widget> children, {
  double horizontalPadding = 0,
  double verticalPadding = 0,
  bool includeLastDivider = false,
  double height = 1,
  double thickness = 1,
  bool darkDivider = false,
  Axis axis = Axis.horizontal,
  Color? dividerColor,
}) {
  List<Widget> withDividers = [];
  for (int i = 0; i < children.length; i++) {
    withDividers.add(children[i]);

    final int numDividers = includeLastDivider
        ? children.length
        : children.length - 1;

    final Color color =
        dividerColor ??
        (darkDivider ? SenseiColors.gray[100]! : SenseiColors.gray[100]!);

    if (i < numDividers) {
      withDividers.add(
        Center(
          child: axis == Axis.horizontal
              ? Divider(
                  color: color,
                  thickness: thickness,
                  height: height,
                  endIndent: horizontalPadding,
                  indent: horizontalPadding,
                )
              : VerticalDivider(
                  color: color,
                  thickness: thickness,
                  width: 1,
                  indent: verticalPadding,
                  endIndent: verticalPadding,
                ),
        ),
      );
    }
  }
  return withDividers;
}

double autoBottomPadding(BuildContext context) {
  return MediaQuery.of(context).viewPadding.bottom > 0
      ? MediaQuery.of(context).viewPadding.bottom
      : 12;
}
