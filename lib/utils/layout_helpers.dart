import 'package:flutter/material.dart';

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
