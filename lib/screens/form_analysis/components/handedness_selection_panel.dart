import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/asset_image_icon.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/models/handedness.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Panel for selecting handedness (auto, lefty, or righty).
/// Displayed as a bottom sheet with card options.
/// Returns null for auto-detect, or the selected Handedness.
class HandednessSelectionPanel extends StatelessWidget {
  const HandednessSelectionPanel({super.key, required this.onSelected});

  final Function(Handedness? handedness) onSelected;

  /// Shows the panel as a modal bottom sheet.
  /// Returns a [HandednessSelectionResult] if a selection was made,
  /// or null if dismissed without selection.
  static Future<HandednessSelectionResult?> show(BuildContext context) {
    return showModalBottomSheet<HandednessSelectionResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => HandednessSelectionPanel(
        onSelected: (handedness) =>
            Navigator.pop(context, HandednessSelectionResult(handedness)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PanelConstants.panelBorderRadius),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: autoBottomPadding(context),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildHandednessCard(
                          context: context,
                          handedness: Handedness.left,
                          label: 'Lefty',
                          color1: const Color(0xFF7B1FA2),
                          color2: const Color(0xFF9C27B0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHandednessCard(
                          context: context,
                          handedness: Handedness.right,
                          label: 'Righty',
                          color1: const Color(0xFF1976D2),
                          color2: const Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildAutoCard(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Throwing hand',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHandednessCard({
    required BuildContext context,
    required Handedness handedness,
    required String label,
    required Color color1,
    required Color color2,
  }) {
    final bool isLefty = handedness == Handedness.left;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onSelected(handedness);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color1, color2],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color1.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Transform.flip(
              flipX: isLefty,
              child: const AssetImageIcon(
                'assets/form_icons/side_view_backhand_clear.png',
                size: 80,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onSelected(null);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00897B), Color(0xFF26A69A)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00897B).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              'Auto-detect',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Result wrapper to distinguish between "auto selected" (handedness is null)
/// and "dismissed without selection" (the show() method returns null).
class HandednessSelectionResult {
  const HandednessSelectionResult(this.handedness);

  /// The selected handedness, or null for auto-detect.
  final Handedness? handedness;
}
