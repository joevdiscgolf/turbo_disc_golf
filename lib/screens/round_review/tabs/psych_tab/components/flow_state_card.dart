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
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9D4EDD), Color(0xFF7B2CBF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flow State',
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      'In the zone',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              // Flow score badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getScoreGradient(flowAnalysis.overallFlowScore),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${flowAnalysis.overallFlowScore.toStringAsFixed(0)}/100',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Visual timeline
          _buildFlowTimeline(context),

          const SizedBox(height: 20),

          // Stats grid
          _buildStatsGrid(context),

          // Flow triggers section
          if (flowAnalysis.flowTriggers.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildFlowTriggers(context),
          ],

          // Flow periods detail
          if (flowAnalysis.flowPeriods.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildFlowPeriods(context),
          ],

          // Insights
          if (flowAnalysis.insights.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInsights(context),
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
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: CustomPaint(
            size: Size(MediaQuery.of(context).size.width - 64, 60),
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

  Widget _buildStatsGrid(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              icon: Icons.timer,
              label: 'Flow Holes',
              value: '${flowAnalysis.totalFlowHoles}',
              color: const Color(0xFF9D4EDD),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Expanded(
            child: _buildStatItem(
              context,
              icon: Icons.percent,
              label: 'Coverage',
              value: '${flowAnalysis.flowPercentage.toStringAsFixed(0)}%',
              color: const Color(0xFF4CAF50),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Expanded(
            child: _buildStatItem(
              context,
              icon: Icons.waves,
              label: 'Periods',
              value: '${flowAnalysis.flowCount}',
              color: const Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
            Icon(
              Icons.bolt,
              color: const Color(0xFFFFB800),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Flow Triggers',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: flowAnalysis.flowTriggers.map((trigger) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB800), Color(0xFFFF8A00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    trigger,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...flowAnalysis.flowPeriods.map((period) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildFlowPeriodCard(context, period),
          );
        }),
      ],
    );
  }

  Widget _buildFlowPeriodCard(BuildContext context, FlowStatePeriod period) {
    final qualityColor = _getQualityColor(period.flowQuality);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: qualityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: qualityColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: qualityColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  period.flowQuality,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  period.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
              _buildPeriodStat(
                context,
                'Birdies',
                '${period.birdieCount}',
              ),
              const SizedBox(width: 16),
              _buildPeriodStat(
                context,
                'Mistakes',
                '${period.mistakeCount}',
              ),
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
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

  Widget _buildPeriodStat(
    BuildContext context,
    String label,
    String value,
  ) {
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildInsights(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.lightbulb,
              color: Color(0xFFFFB800),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Flow Insights',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...flowAnalysis.insights.map((insight) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9D4EDD).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 12,
                    color: Color(0xFF9D4EDD),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  List<Color> _getScoreGradient(double score) {
    if (score >= 70) {
      return [const Color(0xFF4CAF50), const Color(0xFF2E7D32)];
    } else if (score >= 50) {
      return [const Color(0xFF9D4EDD), const Color(0xFF7B2CBF)];
    } else if (score >= 30) {
      return [const Color(0xFF2196F3), const Color(0xFF1565C0)];
    } else {
      return [const Color(0xFFFF9800), const Color(0xFFE65100)];
    }
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
    final baseLinePaint = Paint()
      ..color = colorScheme.outlineVariant
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final flowPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF9D4EDD), Color(0xFF7B2CBF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final eliteFlowPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Draw base timeline
    final y = size.height / 2;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      baseLinePaint,
    );

    // Draw flow periods
    for (var period in flowPeriods) {
      final startX = ((period.startHole - 1) / totalHoles) * size.width;
      final endX = (period.endHole / totalHoles) * size.width;

      final paint = period.flowQuality == 'Elite' ? eliteFlowPaint : flowPaint;

      canvas.drawLine(
        Offset(startX, y),
        Offset(endX, y),
        paint,
      );

      // Draw glow effect for elite flow
      if (period.flowQuality == 'Elite') {
        final glowPaint = Paint()
          ..color = const Color(0xFF4CAF50).withValues(alpha: 0.3)
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawLine(
          Offset(startX, y),
          Offset(endX, y),
          glowPaint,
        );
      }
    }

    // Draw hole markers
    for (int i = 0; i <= totalHoles; i += (totalHoles >= 18 ? 3 : 2)) {
      final x = (i / totalHoles) * size.width;
      final markerPaint = Paint()
        ..color = colorScheme.onSurfaceVariant
        ..strokeWidth = 2;

      canvas.drawLine(
        Offset(x, y - 15),
        Offset(x, y + 15),
        markerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
