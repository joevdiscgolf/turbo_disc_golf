import 'package:flutter/cupertino.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// A data class representing an action in the action sheet
class ActionSheetAction {
  const ActionSheetAction({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;
}

/// A reusable CupertinoActionSheet with consistent styling across the app.
///
/// Features:
/// - Title and message display
/// - Destructive action (red text)
/// - Optional additional actions (blue text)
/// - Cancel button (blue text)
/// - Proper iOS-style appearance
class CustomCupertinoActionSheet extends StatelessWidget {
  const CustomCupertinoActionSheet({
    super.key,
    required this.title,
    this.message,
    required this.destructiveActionLabel,
    required this.onDestructiveActionPressed,
    this.additionalActions,
    this.cancelActionLabel = 'Cancel',
    required this.onCancelPressed,
  });

  final String title;
  final String? message;
  final String destructiveActionLabel;
  final Function() onDestructiveActionPressed;

  /// Optional additional actions displayed between destructive and cancel
  final List<ActionSheetAction>? additionalActions;

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
              style: TextStyle(color: SenseiColors.gray.shade500),
            )
          : null,
      actions: [
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: onDestructiveActionPressed,
          child: Text(destructiveActionLabel),
        ),
        if (additionalActions != null)
          ...additionalActions!.map(
            (action) => CupertinoActionSheetAction(
              isDestructiveAction: action.isDestructive,
              onPressed: action.onPressed,
              child: Text(action.label),
            ),
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
