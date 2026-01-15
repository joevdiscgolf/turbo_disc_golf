import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/loaders/gpt_atomic_nuclear_loader.dart';

/// View showing progress during video analysis.
/// Uses a single loader instance to prevent particle animation jank.
class AnalysisProgressView extends StatelessWidget {
  const AnalysisProgressView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Single persistent loader instance across all progress messages
            const GPTAtomicNucleusLoader(key: ValueKey('analysis-loader')),
            const SizedBox(height: 32),
            // Static text instead of changing message
            Text(
              'Processing results...',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This may take a moment...',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
