import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/components/custom_markdown_content.dart';

class SummaryTab extends StatelessWidget {
  final DGRound round;

  const SummaryTab({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (round.aiSummary != null && round.aiSummary!.isNotEmpty) ...[
            Row(
              children: [
                Image.asset(
                  'assets/mascots/turbo_mascot.png',
                  width: 60,
                  height: 60,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Here\'s what I noticed about your round!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CustomMarkdownContent(data: round.aiSummary!),
              ),
            ),
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No AI summary available for this round',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI summaries are generated automatically for new rounds',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
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
