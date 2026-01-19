import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DriveViewMode {
  cards,
  radar,
}

class ViewModeToggle extends StatelessWidget {
  const ViewModeToggle({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  final DriveViewMode selectedMode;
  final ValueChanged<DriveViewMode> onModeChanged;

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
              label: 'Cards',
              icon: Icons.view_module,
              isSelected: selectedMode == DriveViewMode.cards,
              onTap: () => onModeChanged(DriveViewMode.cards),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: _ToggleButton(
              label: 'Radar',
              icon: Icons.radar,
              isSelected: selectedMode == DriveViewMode.radar,
              onTap: () => onModeChanged(DriveViewMode.radar),
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
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? const Color(0xFF111827)
                  : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                    color: isSelected
                        ? const Color(0xFF111827)
                        : const Color(0xFF6B7280),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
