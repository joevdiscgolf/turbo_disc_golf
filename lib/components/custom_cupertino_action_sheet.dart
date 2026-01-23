import 'package:flutter/cupertino.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// A reusable CupertinoActionSheet with consistent styling across the app.
///
/// Features:
/// - Title and message display
/// - Destructive action (red text)
/// - Cancel button (blue text)
/// - Proper iOS-style appearance
class CustomCupertinoActionSheet extends StatelessWidget {
  const CustomCupertinoActionSheet({
    super.key,
    required this.title,
    this.message,
    required this.destructiveActionLabel,
    required this.onDestructiveActionPressed,
    this.cancelActionLabel = 'Cancel',
    required this.onCancelPressed,
  });

  final String title;
  final String? message;
  final String destructiveActionLabel;
  final Function() onDestructiveActionPressed;
  final String cancelActionLabel;
  final Function() onCancelPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: Text(
        title,
        textAlign: TextAlign.center,
      ),
      message: message != null
          ? Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(color: SenseiColors.gray.shade50),
            )
          : null,
      actions: [
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: onDestructiveActionPressed,
          child: Text(destructiveActionLabel),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: onCancelPressed,
        child: Text(
          cancelActionLabel,
          style: const TextStyle(color: CupertinoColors.systemBlue),
        ),
      ),
    );
  }
}
