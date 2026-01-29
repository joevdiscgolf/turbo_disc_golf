import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/asset_image_icon.dart';

/// Gradient color scheme for the floating view toggle.
class FloatingViewToggleColors {
  const FloatingViewToggleColors({
    required this.outerGradient,
    required this.innerGradient,
    required this.shadowColor,
    required this.unselectedIconColor,
  });

  /// Blue theme (used in timeline analysis view).
  static const FloatingViewToggleColors blue = FloatingViewToggleColors(
    outerGradient: [Color(0xFF93C5FD), Color(0xFF60A5FA)],
    innerGradient: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    shadowColor: Color(0xFF3B82F6),
    unselectedIconColor: Color(0xFF1E40AF),
  );

  /// Purple theme (used in history analysis view).
  static const FloatingViewToggleColors purple = FloatingViewToggleColors(
    outerGradient: [Color(0xFFD8B4FE), Color(0xFFC084FC)],
    innerGradient: [Color(0xFF9333EA), Color(0xFF7C3AED)],
    shadowColor: Color(0xFF9333EA),
    unselectedIconColor: Color(0xFF6B21B6),
  );

  final List<Color> outerGradient;
  final List<Color> innerGradient;
  final Color shadowColor;
  final Color unselectedIconColor;
}

/// Floating skeleton/video toggle positioned at the bottom of the screen.
class FloatingViewToggle extends StatelessWidget {
  const FloatingViewToggle({
    super.key,
    required this.showSkeletonOnly,
    required this.onChanged,
    this.colors = FloatingViewToggleColors.purple,
  });

  final bool showSkeletonOnly;
  final ValueChanged<bool> onChanged;
  final FloatingViewToggleColors colors;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 32,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 112,
          height: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors.outerGradient,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: showSkeletonOnly
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 52,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors.innerGradient,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildButton(
                    icon: Icons.videocam_outlined,
                    iconSize: 22,
                    isSelected: !showSkeletonOnly,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(false);
                    },
                  ),
                  _buildButton(
                    imageAsset: 'assets/form_icons/white_skeleton_heisman_icon.png',
                    iconSize: 31,
                    isSelected: showSkeletonOnly,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(true);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    IconData? icon,
    String? imageAsset,
    required double iconSize,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        height: 44,
        child: Center(
          child: icon != null
              ? Icon(
                  icon,
                  size: iconSize,
                  color: isSelected ? Colors.white : colors.unselectedIconColor,
                )
              : AssetImageIcon(
                  imageAsset!,
                  size: iconSize,
                  color:
                      isSelected ? Colors.white : colors.unselectedIconColor,
                ),
        ),
      ),
    );
  }
}
