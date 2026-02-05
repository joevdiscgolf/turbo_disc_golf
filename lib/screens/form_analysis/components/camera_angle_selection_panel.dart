import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/asset_image_icon.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Panel for selecting camera angle (side or rear view).
/// Displayed as a bottom sheet with card options.
class CameraAngleSelectionPanel extends StatelessWidget {
  const CameraAngleSelectionPanel({super.key, required this.onSelected});

  final Function(CameraAngle angle) onSelected;

  // Colors matching history card badges
  static const Color _sidePrimary = Color(0xFF1976D2);
  static const Color _sideLight = Color(0xFF2196F3);
  static const Color _rearPrimary = Color(0xFF00897B);
  static const Color _rearLight = Color(0xFF26A69A);

  /// Shows the panel as a modal bottom sheet.
  static Future<CameraAngle?> show(BuildContext context) {
    return showModalBottomSheet<CameraAngle>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CameraAngleSelectionPanel(
        onSelected: (angle) => Navigator.pop(context, angle),
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
            child: Row(
              children: [
                Expanded(
                  child: _buildAngleCard(
                    context: context,
                    angle: CameraAngle.side,
                    label: 'Side',
                    color1: _sidePrimary,
                    color2: _sideLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAngleCard(
                    context: context,
                    angle: CameraAngle.rear,
                    label: 'Rear',
                    color1: _rearPrimary,
                    color2: _rearLight,
                  ),
                ),
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
            'Camera angle',
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

  Widget _buildAngleCard({
    required BuildContext context,
    required CameraAngle angle,
    required String label,
    required Color color1,
    required Color color2,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onSelected(angle);
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
            AssetImageIcon(
              angle == CameraAngle.side
                  ? 'assets/form_icons/side_view_backhand_clear.png'
                  : 'assets/form_icons/rear_view_backhand_clear.png',
              size: 80,
              fit: BoxFit.contain,
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
}
