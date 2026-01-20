import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';

/// Generic education panel that can display educational content in a modal bottom sheet.
/// Flexible content structure to support various types of educational materials.
class EducationPanel extends StatelessWidget {
  const EducationPanel({
    super.key,
    required this.title,
    required this.contentBuilder,
    this.bottomViewPadding = 0,
    this.accentColor = const Color(0xFF7E57C2),
    this.buttonLabel = 'Got it!',
    this.modalName = 'Education Panel',
  });

  final String title;
  final Widget Function(BuildContext context) contentBuilder;
  final double bottomViewPadding;
  final Color accentColor;
  final String buttonLabel;
  final String modalName;

  /// Shows this panel as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required Widget Function(BuildContext context) contentBuilder,
    Color accentColor = const Color(0xFF7E57C2),
    String buttonLabel = 'Got it!',
    String modalName = 'Education Panel',
  }) async {
    // Track modal opened
    locator.get<LoggingService>().track('Modal Opened', properties: {
      'modal_type': 'bottom_sheet',
      'modal_name': modalName,
    });

    HapticFeedback.lightImpact();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EducationPanel(
        title: title,
        contentBuilder: contentBuilder,
        bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
        accentColor: accentColor,
        buttonLabel: buttonLabel,
        modalName: modalName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title header without close button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ) ??
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  contentBuilder(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildBottomButton(context),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + bottomViewPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: PrimaryButton(
        label: buttonLabel,
        width: double.infinity,
        height: 56,
        backgroundColor: accentColor,
        labelColor: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
