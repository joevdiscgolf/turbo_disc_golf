import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Dark grey gradient shimmer placeholder used while loading form analysis images.
class FormAnalysisShimmerPlaceholder extends StatelessWidget {
  const FormAnalysisShimmerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
          color: Colors.grey[900],
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.grey[800]!,
                  Colors.grey[700]!,
                  Colors.grey[800]!,
                ],
              ),
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.3));
  }
}
