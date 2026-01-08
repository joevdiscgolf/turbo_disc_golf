import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PanelHeader extends StatelessWidget {
  const PanelHeader({
    super.key,
    required this.title,
    this.onClose,
    this.subtitle,
  });

  /// The main title text displayed in the header
  final String title;

  /// Optional callback when close button is tapped.
  /// If null, no close button is displayed.
  final VoidCallback? onClose;

  /// Optional subtitle text displayed below the title
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: PanelConstants.panelLeftPadding,
        right: PanelConstants.panelRightPadding,
        top: PanelConstants.panelTopPadding,
        bottom: PanelConstants.panelBottomPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: PanelConstants.getPanelTitleStyle(context)),

                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: PanelConstants.closeButtonIconSize,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              if (onClose != null) {
                onClose!();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}

abstract class PanelConstants {
  // Typography
  /// Returns the standard panel title text style using the app theme
  ///
  /// Uses headlineSmall with bold weight for optimal readability and hierarchy
  static TextStyle getPanelTitleStyle(BuildContext context) {
    return Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold) ??
        const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  }

  static const double panelLeftPadding = 16.0;

  static const double panelRightPadding = 16;

  static const double panelTopPadding = 16.0;

  static const double panelBottomPadding = 12.0;

  // Border radius
  /// Standard border radius for panel containers
  static const double panelBorderRadius = 20.0;

  // Close button
  /// Icon size for panel close buttons
  static const double closeButtonIconSize = 24.0;
}
