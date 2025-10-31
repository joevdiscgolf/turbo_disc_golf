import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

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
        (darkDivider ? TurbColors.gray[100]! : TurbColors.gray[100]!);

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
              : VerticalDivider(color: color, thickness: thickness, width: 1),
        ),
      );
    }
  }
  return withDividers;
}
