import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/putt_detail/models/putt_attempt.dart';

/// Widget showing the list of putt attempts with their context
class PuttDetailsList extends StatelessWidget {
  const PuttDetailsList({
    required this.puttAttempts,
    super.key,
  });

  final List<PuttAttempt> puttAttempts;

  @override
  Widget build(BuildContext context) {
    if (puttAttempts.isEmpty) {
      return Text(
        'No putts found',
        style: TextStyle(fontSize: 13, color: const Color(0xFF6B7280)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: puttAttempts.map((putt) => _PuttDetailRow(putt: putt)).toList(),
    );
  }
}

class _PuttDetailRow extends StatelessWidget {
  const _PuttDetailRow({required this.putt});

  final PuttAttempt putt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Hole number circle with made/missed color
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: putt.made ? const Color(0xFF4CAF50) : const Color(0xFFFF7A7A),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${putt.holeNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Distance · putt type (e.g., "15 ft · birdie putt")
          Expanded(
            child: Text(
              '${putt.distance.toStringAsFixed(0)} ft · ${putt.puttFor.puttDescription}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          // Made/Missed pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: putt.made
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                  : const Color(0xFFFF7A7A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              putt.made ? 'Made' : 'Missed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: putt.made ? const Color(0xFF4CAF50) : const Color(0xFFFF7A7A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
