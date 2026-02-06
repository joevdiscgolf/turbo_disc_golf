import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// A reusable footer widget for form screens with a primary action button.
/// Used by CreateCourseScreen, CreateLayoutScreen, and similar form-based screens.
class FormFooter extends StatelessWidget {
  const FormFooter({
    super.key,
    required this.label,
    required this.canSave,
    required this.onPressed,
    this.loading = false,
  });

  /// The button label text
  final String label;

  /// Whether the save/submit action is enabled
  final bool canSave;

  /// Callback when the button is pressed
  final VoidCallback onPressed;

  /// Whether to show a loading indicator on the button
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: PrimaryButton(
        width: double.infinity,
        height: 56,
        label: label,
        loading: loading,
        gradientBackground: canSave
            ? const [Color(0xFF137e66), Color(0xFF1a9f7f)]
            : null,
        backgroundColor: canSave
            ? Colors.transparent
            : SenseiColors.gray.shade200,
        labelColor: canSave ? Colors.white : SenseiColors.gray.shade400,
        fontSize: 18,
        disabled: !canSave,
        onPressed: onPressed,
      ),
    );
  }
}
