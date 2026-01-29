import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/asset_image_icon.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';

/// Dialog for selecting camera angle (side or rear view).
/// Tapping a button immediately selects it and calls onSelected.
class CameraAngleSelectionDialog extends StatelessWidget {
  const CameraAngleSelectionDialog({super.key, required this.onSelected});

  final Function(CameraAngle angle) onSelected;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Camera angle',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildAngleCard(
                      context: context,
                      angle: CameraAngle.side,
                      label: 'Side',
                      color1: const Color(0xFF1976D2),
                      color2: const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAngleCard(
                      context: context,
                      angle: CameraAngle.rear,
                      label: 'Rear',
                      color1: const Color(0xFF00897B),
                      color2: const Color(0xFF26A69A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
        Navigator.pop(context);
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
