import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Empty state shown in pro reference area when no checkpoint has ever been selected.
///
/// Displays a placeholder with a hint to scrub to a position.
class ProReferenceEmptyState extends StatelessWidget {
  const ProReferenceEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Subtle gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    SenseiColors.gray[800]!.withValues(alpha: 0.3),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          // Centered hint overlay
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Person silhouette icon
                  Icon(
                    Icons.person_outline_rounded,
                    size: 48,
                    color: SenseiColors.gray[600],
                  ),
                  const SizedBox(height: 16),
                  // Scrubber icon with arrows
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_rounded,
                        size: 14,
                        color: SenseiColors.gray[500],
                      ),
                      Container(
                        width: 60,
                        height: 3,
                        decoration: BoxDecoration(
                          color: SenseiColors.gray[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: SenseiColors.gray[500],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: SenseiColors.gray[500],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Hint text
                  Text(
                    'Scrub to a position',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: SenseiColors.gray[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Pro reference badge
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Pro reference',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
