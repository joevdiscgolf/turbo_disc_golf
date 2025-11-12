import 'package:flutter/material.dart';

class BottomSheetPanel extends StatelessWidget {
  const BottomSheetPanel({
    super.key,
    required this.child,
    this.fullScreen = false,
  });

  final Widget child;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final double panelHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        minHeight: fullScreen ? panelHeight : 200,
        maxHeight: panelHeight,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: fullScreen ? MediaQuery.of(context).padding.top : 8,
          bottom: 48,
        ),
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [child],
        ),
      ),
    );
  }
}
