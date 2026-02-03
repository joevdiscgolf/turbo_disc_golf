import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/asset_image_icon.dart';

/// Toggle for switching between video+skeleton and skeleton-only views.
/// Matches the styling of ViewModeToggle for consistency.
class VideoSkeletonToggle extends StatelessWidget {
  const VideoSkeletonToggle({
    super.key,
    required this.showSkeletonOnly,
    required this.onChanged,
  });

  final bool showSkeletonOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          // Animated sliding pill
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: showSkeletonOnly
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  width: (constraints.maxWidth - 3) / 2,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Buttons on top
          Row(
            children: [
              Expanded(
                child: _ToggleButton(
                  label: 'Overlay',
                  icon: Icons.videocam_outlined,
                  isSelected: !showSkeletonOnly,
                  onTap: () => onChanged(false),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: _ToggleButton(
                  label: 'Skeleton',
                  imageAsset:
                      'assets/form_icons/white_skeleton_heisman_icon.png',
                  isSelected: showSkeletonOnly,
                  onTap: () => onChanged(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    this.icon,
    this.imageAsset,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData? icon;
  final String? imageAsset;
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? const Color(0xFF111827)
                    : const Color(0xFF9CA3AF),
              )
            else if (imageAsset != null)
              AssetImageIcon(
                imageAsset!,
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
