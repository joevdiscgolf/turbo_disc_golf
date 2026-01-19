import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';

class FlowStateCard extends StatelessWidget {
  final FlowStateAnalysis flowAnalysis;
  final int totalHoles;

  const FlowStateCard({
    super.key,
    required this.flowAnalysis,
    required this.totalHoles,
  });

  @override
  Widget build(BuildContext context) {
    if (!flowAnalysis.hasFlowStates) {
      return _buildNoFlowState(context);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              const Text('🌊', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flow State',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'In the zone',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Coverage percentage badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${flowAnalysis.flowPercentage.toStringAsFixed(0)}% coverage',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Visual timeline
          _buildFlowTimeline(context),

          // Flow triggers section
          if (flowAnalysis.flowTriggers.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildFlowTriggers(context),
          ],

          // Flow periods detail
          if (flowAnalysis.flowPeriods.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildFlowPeriods(context),
          ],
        ],
      ),
    );
  }

  Widget _buildNoFlowState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Flow States Detected',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            flowAnalysis.insights.isNotEmpty
                ? flowAnalysis.insights.first
                : 'String together 4+ consistent holes with high shot quality to enter flow state.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFlowTimeline(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Round Timeline',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: CustomPaint(
            size: Size(MediaQuery.of(context).size.width - 64, 40),
            painter: FlowTimelinePainter(
              flowPeriods: flowAnalysis.flowPeriods,
              totalHoles: totalHoles,
              colorScheme: Theme.of(context).colorScheme,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hole 1',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Hole $totalHoles',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFlowTriggers(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt, color: Color(0xFFFFB800), size: 18),
            const SizedBox(width: 8),
            Text(
              'Flow Triggers',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: flowAnalysis.flowTriggers.map((trigger) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFFB800), width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: Color(0xFFFFB800), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    trigger,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFlowPeriods(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Flow Periods',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        ...flowAnalysis.flowPeriods.map((period) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildFlowPeriodCard(context, period),
          );
        }),
      ],
    );
  }

  Widget _buildFlowPeriodCard(BuildContext context, FlowStatePeriod period) {
    final Color qualityColor = _getQualityColor(period.flowQuality);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F5E9), Color(0xFFF1F8F4)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: qualityColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: qualityColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  period.flowQuality,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  period.label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${period.duration} holes',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPeriodStat(
                context,
                'Shot Quality',
                '${period.shotQualityRate.toStringAsFixed(0)}%',
              ),
              const SizedBox(width: 16),
              _buildPeriodStat(context, 'Birdies', '${period.birdieCount}'),
              const SizedBox(width: 16),
              _buildPeriodStat(context, 'Mistakes', '${period.mistakeCount}'),
            ],
          ),
          if (period.commonDiscs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...period.commonDiscs.map((disc) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      disc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
                ...period.commonTechniques.map((tech) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tech,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _getQualityColor(String quality) {
    switch (quality) {
      case 'Elite':
        return const Color(0xFF4CAF50);
      case 'Strong':
        return const Color(0xFF9D4EDD);
      case 'Moderate':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF757575);
    }
  }
}

/// Custom painter for the flow state timeline
class FlowTimelinePainter extends CustomPainter {
  final List<FlowStatePeriod> flowPeriods;
  final int totalHoles;
  final ColorScheme colorScheme;

  FlowTimelinePainter({
    required this.flowPeriods,
    required this.totalHoles,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint baseLinePaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.5)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final Paint flowPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Draw base timeline
    final double y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), baseLinePaint);

    // Draw flow periods
    for (final FlowStatePeriod period in flowPeriods) {
      final double startX = ((period.startHole - 1) / totalHoles) * size.width;
      final double endX = (period.endHole / totalHoles) * size.width;

      canvas.drawLine(Offset(startX, y), Offset(endX, y), flowPaint);
    }

    // Draw hole markers at start and end only
    final Paint markerPaint = Paint()
      ..color = colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;

    // Start marker
    canvas.drawLine(Offset(0, y - 10), Offset(0, y + 10), markerPaint);

    // End marker
    canvas.drawLine(
      Offset(size.width, y - 10),
      Offset(size.width, y + 10),
      markerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
