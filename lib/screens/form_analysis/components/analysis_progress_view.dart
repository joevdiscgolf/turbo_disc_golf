import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/components/loaders/atomic_nucleus_loader.dart';
import 'package:turbo_disc_golf/components/loaders/gpt_atomic_nucleus_loader.dart';
import 'package:turbo_disc_golf/components/loaders/gpt_atomic_nucleus_loader_v2.dart';

/// View showing progress during video analysis.
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
            _buildAnimatedIcon(),
            const SizedBox(height: 32),
            Text(
              message,
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

  Widget _buildAnimatedIcon() {
    return const GPTAtomicNucleusLoader();
    // return const GPTAtomicNucleusLoaderV2();
    // return const AtomicNucleusLoader(
    //   size: 240,
    //   particleCount: 3, // 3 particles per orbit = 6 total
    // );
  }
}
