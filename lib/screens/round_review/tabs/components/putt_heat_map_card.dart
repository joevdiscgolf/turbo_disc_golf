import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/components/putt_heat_map_painter.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';

class PuttHeatMapCard extends StatelessWidget {
  final DGRound round;

  const PuttHeatMapCard({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    final statsService = RoundStatisticsService(round);
    final puttAttempts = statsService.getPuttAttempts();

    if (puttAttempts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filter putts by distance
    final c1Putts = puttAttempts.where((p) => (p['distance'] as double) <= 33).toList();
    final c2Putts = puttAttempts.where((p) => (p['distance'] as double) > 33).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Putt Location Heat Maps',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(context, 'Made', const Color(0xFF4CAF50)),
                const SizedBox(width: 24),
                _buildLegendItem(context, 'Missed', const Color(0xFFFF7A7A)),
              ],
            ),
            const SizedBox(height: 12),

            // Circle 1 Heat Map
            if (c1Putts.isNotEmpty) ...[
              Text(
                'Circle 1 (10-33 ft)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 350,
                child: CustomPaint(
                  painter: PuttHeatMapPainter(
                    puttAttempts: c1Putts,
                    rangeStart: 10,
                    rangeEnd: 33,
                  ),
                  child: Container(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${c1Putts.length} putt${c1Putts.length == 1 ? '' : 's'} in Circle 1',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            if (c1Putts.isNotEmpty && c2Putts.isNotEmpty) const SizedBox(height: 16),

            // Circle 2 Heat Map
            if (c2Putts.isNotEmpty) ...[
              Text(
                'Circle 2 (33-66 ft)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 350,
                child: CustomPaint(
                  painter: PuttHeatMapPainter(
                    puttAttempts: c2Putts,
                    rangeStart: 33,
                    rangeEnd: 66,
                  ),
                  child: Container(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${c2Putts.length} putt${c2Putts.length == 1 ? '' : 's'} in Circle 2',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 8),
            Text(
              'Positions are approximate.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
