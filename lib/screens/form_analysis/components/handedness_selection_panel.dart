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

  // Brand colors
  static const Color _tealPrimary = Color(0xFF137e66);
  static const Color _tealLight = Color(0xFF1A9E80);
  static const Color _purplePrimary = Color(0xFF7B5B9A);
  static const Color _purpleLight = Color(0xFF9C7AB8);
  static const Color _bluePrimary = Color(0xFF4A7FC1);
  static const Color _blueLight = Color(0xFF6B9AD8);

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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PanelConstants.panelBorderRadius),
        ),
      ),
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
                        color1: _purplePrimary,
                        color2: _purpleLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildHandednessCard(
                        context: context,
                        handedness: Handedness.right,
                        label: 'Righty',
                        color1: _bluePrimary,
                        color2: _blueLight,
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Throwing hand',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[600]),
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
            colors: [_tealPrimary, _tealLight],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _tealPrimary.withValues(alpha: 0.3),
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
