import 'package:flutter/material.dart';

/// Empty state shown in pro reference area when no checkpoint has ever been selected.
///
/// Displays a silhouette image at 10% opacity with a hint to scrub to a position.
class ProReferenceEmptyState extends StatelessWidget {
  const ProReferenceEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Silhouette at 10% opacity
        Positioned.fill(
          child: Opacity(
            opacity: 0.10,
            child: Image.asset(
              'assets/pro_references/paul_mcbeth/backhand/side/magic_silhouette.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        // Centered hint overlay
        Positioned.fill(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scrubber icon with arrows
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    Container(
                      width: 80,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[500],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Hint text
                Text(
                  'Scrub to a position',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
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
    );
  }
}
