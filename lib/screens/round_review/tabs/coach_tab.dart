import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';

class CoachTab extends StatelessWidget {
  final DGRound round;

  const CoachTab({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.merge_type,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Coaching is now in the Summary tab!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We\'ve combined analysis and coaching into one unified AI insights experience. Check out the Summary tab for both what happened and what to work on!',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      // Switch to Summary tab (index 7)
                      DefaultTabController.of(context).animateTo(7);
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Go to Summary'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
