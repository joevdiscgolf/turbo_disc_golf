import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:turbo_disc_golf/models/camera_angle.dart';

/// A toggle widget for selecting the camera angle for form analysis.
///
/// Allows users to choose between side view and rear view camera angles.
/// Follows the same design pattern as [ViewModeToggle] for consistency.
class CameraAngleToggle extends StatelessWidget {
  const CameraAngleToggle({
    super.key,
    required this.selectedAngle,
    required this.onAngleChanged,
  });

  final CameraAngle selectedAngle;
  final ValueChanged<CameraAngle> onAngleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              label: 'Side',
              isSelected: selectedAngle == CameraAngle.side,
              onTap: () => onAngleChanged(CameraAngle.side),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: _ToggleButton(
              label: 'Rear',
              isSelected: selectedAngle == CameraAngle.rear,
              onTap: () => onAngleChanged(CameraAngle.rear),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                  color: isSelected
                      ? const Color(0xFF111827)
                      : const Color(0xFF6B7280),
                ),
          ),
        ),
      ),
    );
  }
}
