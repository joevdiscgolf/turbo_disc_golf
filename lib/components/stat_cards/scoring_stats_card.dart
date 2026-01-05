import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';

/// Compact scoring stats card showing score distribution
///
/// Displays scoring breakdown in a horizontal row of colored stat boxes:
/// - Eagles (gold)
/// - Birdies (green)
/// - Pars (gray)
/// - Bogeys (orange)
/// - Double+ (red)
class ScoringStatsCard extends StatefulWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const ScoringStatsCard({
    super.key,
    required this.round,
    this.onTap,
  });

  @override
  State<ScoringStatsCard> createState() => _ScoringStatsCardState();
}

class _ScoringStatsCardState extends State<ScoringStatsCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Map<String, int> _calculateScoringStats() {
    int eagles = 0;
    int birdies = 0;
    int pars = 0;
    int bogeys = 0;
    int doublePlus = 0;

    for (final hole in widget.round.holes) {
      if (hole.relativeHoleScore < -1) {
        eagles++;
      } else if (hole.relativeHoleScore == -1) {
        birdies++;
      } else if (hole.relativeHoleScore == 0) {
        pars++;
      } else if (hole.relativeHoleScore == 1) {
        bogeys++;
      } else if (hole.relativeHoleScore > 1) {
        doublePlus++;
      }
    }

    return {
      'eagles': eagles,
      'birdies': birdies,
      'pars': pars,
      'bogeys': bogeys,
      'doublePlus': doublePlus,
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final Map<String, int> stats = _calculateScoringStats();

    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (stats['eagles']! > 0)
              _buildStatBox(
                label: 'Eagles',
                count: stats['eagles']!,
                color: const Color(0xFFFFC107),
              ),
            _buildStatBox(
              label: 'Birdies',
              count: stats['birdies']!,
              color: const Color(0xFF4CAF50),
            ),
            _buildStatBox(
              label: 'Pars',
              count: stats['pars']!,
              color: const Color(0xFF9E9E9E),
            ),
            _buildStatBox(
              label: 'Bogeys',
              count: stats['bogeys']!,
              color: const Color(0xFFFFA726),
            ),
            if (stats['doublePlus']! > 0)
              _buildStatBox(
                label: 'Double+',
                count: stats['doublePlus']!,
                color: const Color(0xFFFF7A7A),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required int count,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
