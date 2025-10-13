import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
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
    final c1Putts = puttAttempts
        .where((p) => (p['distance'] as double) <= 33)
        .toList();
    final c2Putts = puttAttempts
        .where((p) => (p['distance'] as double) > 33)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Putt Location Heat Maps',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),

        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(context, 'Made', const Color(0xFF4CAF50)),
              const SizedBox(width: 24),
              _buildLegendItem(context, 'Missed', const Color(0xFFFF7A7A)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // PageView with heat maps
        SizedBox(
          height: 400,
          child: PageView(
            physics: const ClampingScrollPhysics(),
            padEnds: false,
            controller: PageController(viewportFraction: 0.9),
            children: [
              if (c1Putts.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(left: 16),
                  child: _buildHeatMapCard(
                    context,
                    0,
                    'Circle 1 (10-33 ft)',
                    c1Putts,
                    10,
                    33,
                    PuttingCircle.circle1,
                  ),
                ),
              if (c2Putts.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(right: 16),
                  child: _buildHeatMapCard(
                    context,
                    c1Putts.isEmpty ? 0 : 1,
                    'Circle 2 (33-66 ft)',
                    c2Putts,
                    33,
                    66,
                    PuttingCircle.circle2,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Positions are approximate.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildHeatMapCard(
    BuildContext context,
    int index,
    String title,
    List<Map<String, dynamic>> putts,
    double rangeStart,
    double rangeEnd,
    PuttingCircle circle,
  ) {
    return Container(
      margin: EdgeInsets.only(right: index == 0 ? 12 : 0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: CustomPaint(
                painter: PuttHeatMapPainter(
                  puttAttempts: putts,
                  rangeStart: rangeStart,
                  rangeEnd: rangeEnd,
                  circle: circle,
                ),
                child: Container(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${putts.length} putt${putts.length == 1 ? '' : 's'}',
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
