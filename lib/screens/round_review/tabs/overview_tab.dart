import 'dart:math';

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/utils/putting_constants.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/course_tab/components/score_kpi_card.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/services/round_analysis/mistakes_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/psych_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/putting_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/widgets/circular_stat_indicator.dart';
import 'package:turbo_disc_golf/components/custom_markdown_content.dart';

class OverviewTab extends StatefulWidget {
  final DGRound round;
  final TabController? tabController;

  const OverviewTab({super.key, required this.round, this.tabController});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  late RoundParser _roundParser;

  @override
  void initState() {
    super.initState();
    _roundParser = locator.get<RoundParser>();
    _roundParser.setRound(widget.round);
  }

  void _navigateToTab(int tabIndex) {
    if (widget.tabController != null) {
      widget.tabController!.animateTo(tabIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        ScoreKPICard(round: widget.round, roundParser: _roundParser),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ScorecardCard(
            round: widget.round,
            onTap: () => _navigateToTab(1), // Course tab
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _DrivingStatsCard(
            round: widget.round,
            onTap: () => _navigateToTab(3), // Drives tab
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _PuttingStatsCard(
            round: widget.round,
            onTap: () => _navigateToTab(4), // Putting tab
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _MistakesCard(
            round: widget.round,
            onTap: () => _navigateToTab(6), // Mistakes tab
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _MentalGameCard(
            round: widget.round,
            onTap: () => _navigateToTab(7), // Psych tab
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _DiscUsageCard(
            round: widget.round,
            onTap: () => _navigateToTab(5), // Discs tab
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _AICoachCard(
            round: widget.round,
            onTap: () => _navigateToTab(8), // Summary tab
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _AIRoastCard(
            round: widget.round,
            onTap: () => _navigateToTab(10), // Roast tab
          ),
        ),
      ],
    );
  }
}

// Scorecard Card
class _ScorecardCard extends StatelessWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const _ScorecardCard({required this.round, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '📋 Scorecard',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              _buildCompactScorecard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactScorecard() {
    // Split into two rows (first 9, second 9)
    final int halfLength = (round.holes.length / 2).ceil();
    final List<DGHole> firstNine = round.holes.take(halfLength).toList();
    final List<DGHole> secondNine = round.holes.skip(halfLength).toList();

    return Column(
      children: [
        _buildScoreRow(firstNine),
        const SizedBox(height: 12),
        _buildScoreRow(secondNine),
      ],
    );
  }

  Widget _buildScoreRow(List<DGHole> holes) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: holes.map((hole) {
        final int score = hole.holeScore;
        final int scoreToPar = hole.relativeHoleScore;
        final Color color = scoreToPar == 0
            ? const Color(0xFFF5F5F5)
            : scoreToPar < 0
            ? const Color(0xFF137e66)
            : const Color(0xFFFF7A7A);
        final bool isPar = scoreToPar == 0;

        return Expanded(
          child: Column(
            children: [
              Text(
                '${hole.number}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              isPar
                  ? Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    )
                  : Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                      child: Center(
                        child: Text(
                          '$score',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Driving Stats Card
class _DrivingStatsCard extends StatelessWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const _DrivingStatsCard({required this.round, this.onTap});

  Map<String, dynamic> _calculateDrivingStats() {
    final RoundStatisticsService statsService = RoundStatisticsService(round);
    final dynamic coreStats = statsService.getCoreStats();

    return {
      'fairwayPct': coreStats.fairwayHitPct,
      'c1InRegPct': coreStats.c1InRegPct,
      'obPct': coreStats.obPct,
      'parkedPct': coreStats.parkedPct,
      'hasData': round.holes.isNotEmpty,
    };
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> stats = _calculateDrivingStats();
    final bool hasData = stats['hasData'] as bool;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '🎯 Driving',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircularStatIndicator(
                    label: 'C1 in Reg',
                    percentage: hasData ? stats['c1InRegPct'] as double : 0.0,
                    color: const Color(0xFF137e66),
                    size: 70,
                    shouldAnimate: true,
                    shouldGlow: true,
                  ),
                  CircularStatIndicator(
                    label: 'Fairway',
                    percentage: hasData ? stats['fairwayPct'] as double : 0.0,
                    color: const Color(0xFF4CAF50),
                    size: 70,
                    shouldAnimate: true,
                    shouldGlow: true,
                  ),
                  CircularStatIndicator(
                    label: 'OB',
                    percentage: hasData ? stats['obPct'] as double : 0.0,
                    color: const Color(0xFFFF7A7A),
                    size: 70,
                    shouldAnimate: true,
                    shouldGlow: true,
                  ),
                  CircularStatIndicator(
                    label: 'Parked',
                    percentage: hasData ? stats['parkedPct'] as double : 0.0,
                    color: const Color(0xFFFFA726),
                    size: 70,
                    shouldAnimate: true,
                    shouldGlow: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Putting Stats Card
class _PuttingStatsCard extends StatelessWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const _PuttingStatsCard({required this.round, this.onTap});

  Map<String, dynamic> _calculatePuttingStats() {
    int c1Attempts = 0;
    int c1Makes = 0;
    int c1xAttempts = 0;
    int c1xMakes = 0;
    int c2Attempts = 0;
    int c2Makes = 0;
    int totalPutts = 0;
    int totalMakes = 0;
    int scrambles = 0;
    int scrambleAttempts = 0;
    final List<bool> allPutts = [];

    for (final DGHole hole in round.holes) {
      for (final DiscThrow discThrow in hole.throws) {
        if (discThrow.purpose == ThrowPurpose.putt) {
          totalPutts++;
          final double? distance = discThrow.distanceFeetBeforeThrow
              ?.toDouble();
          final bool made = discThrow.landingSpot == LandingSpot.inBasket;
          allPutts.add(made);
          if (made) totalMakes++;

          if (distance != null) {
            // C1 stats (0-33 ft)
            if (distance >= c1MinDistance && distance <= c1MaxDistance) {
              c1Attempts++;
              if (made) c1Makes++;
            }

            // C1X stats (11-33 ft)
            if (distance >= c1xMinDistance && distance <= c1xMaxDistance) {
              c1xAttempts++;
              if (made) c1xMakes++;
            }

            // C2 stats (33-66 ft)
            if (distance > c2MinDistance && distance <= c2MaxDistance) {
              c2Attempts++;
              if (made) c2Makes++;
            }
          }
        }
      }

      // Scramble: saved par or better after missing fairway on drive
      if (hole.throws.isNotEmpty) {
        final DiscThrow drive = hole.throws.first;
        final bool missedFairway =
            drive.landingSpot == LandingSpot.offFairway ||
            drive.landingSpot == LandingSpot.outOfBounds;

        if (missedFairway) {
          scrambleAttempts++;
          if (hole.relativeHoleScore <= 0) {
            scrambles++;
          }
        }
      }
    }

    final double c1Pct = c1Attempts > 0 ? (c1Makes / c1Attempts * 100) : 0;
    final double c1xPct = c1xAttempts > 0 ? (c1xMakes / c1xAttempts * 100) : 0;
    final double c2Pct = c2Attempts > 0 ? (c2Makes / c2Attempts * 100) : 0;
    final double scramblePct = scrambleAttempts > 0
        ? (scrambles / scrambleAttempts * 100)
        : 0;

    return {
      'c1Makes': c1Makes,
      'c1Attempts': c1Attempts,
      'c1Pct': c1Pct,
      'c1xMakes': c1xMakes,
      'c1xAttempts': c1xAttempts,
      'c1xPct': c1xPct,
      'c2Makes': c2Makes,
      'c2Attempts': c2Attempts,
      'c2Pct': c2Pct,
      'totalPutts': totalPutts,
      'totalMakes': totalMakes,
      'scramblePct': scramblePct,
      'hasData': totalPutts > 0,
      'allPutts': allPutts,
    };
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> stats = _calculatePuttingStats();
    final bool hasData = stats['hasData'] as bool;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '🥏 Putting',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              // Compact stat indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CompactStatIndicator(
                    label: 'C1',
                    percentage: hasData ? stats['c1Pct'] as double : 0.0,
                    makes: stats['c1Makes'] as int,
                    attempts: stats['c1Attempts'] as int,
                    color: const Color(0xFF137e66),
                  ),
                  _CompactStatIndicator(
                    label: 'C1X',
                    percentage: hasData ? stats['c1xPct'] as double : 0.0,
                    makes: stats['c1xMakes'] as int,
                    attempts: stats['c1xAttempts'] as int,
                    color: const Color(0xFF4CAF50),
                  ),
                  _CompactStatIndicator(
                    label: 'C2',
                    percentage: hasData ? stats['c2Pct'] as double : 0.0,
                    makes: stats['c2Makes'] as int,
                    attempts: stats['c2Attempts'] as int,
                    color: const Color(0xFF2196F3),
                  ),
                ],
              ),
              if (hasData) ...[
                const SizedBox(height: 16),
                // Side-by-side heat maps
                Row(
                  children: [
                    Expanded(
                      child: _CompactHeatMap(showCircle1: true, round: round),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CompactHeatMap(showCircle1: false, round: round),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${stats['totalMakes']}/${stats['totalPutts']} putts made',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Compact stat indicator for overview
class _CompactStatIndicator extends StatelessWidget {
  const _CompactStatIndicator({
    required this.label,
    required this.percentage,
    required this.makes,
    required this.attempts,
    required this.color,
  });

  final String label;
  final double percentage;
  final int makes;
  final int attempts;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$makes/$attempts',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// Compact heat map with dots and animation
class _CompactHeatMap extends StatefulWidget {
  const _CompactHeatMap({
    required this.showCircle1,
    required this.round,
  });

  final bool showCircle1;
  final DGRound round;

  @override
  State<_CompactHeatMap> createState() => _CompactHeatMapState();
}

class _CompactHeatMapState extends State<_CompactHeatMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PuttingAnalysisService puttingService = locator.get<PuttingAnalysisService>();
    final List<Map<String, dynamic>> allPutts = puttingService.getPuttAttempts(widget.round);

    // Filter putts by circle
    final List<Map<String, dynamic>> putts = allPutts.where((putt) {
      final double? distance = putt['distance'] as double?;
      if (distance == null) return false;

      if (widget.showCircle1) {
        return distance <= c1MaxDistance;
      } else {
        return distance > c2MinDistance && distance <= c2MaxDistance;
      }
    }).toList();

    return Column(
      children: [
        Text(
          widget.showCircle1 ? 'C1' : 'C2',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: _CompactHeatMapPainter(
                  showCircle1: widget.showCircle1,
                  putts: putts,
                  animationValue: _animation.value,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Painter for compact heat map with dots
class _CompactHeatMapPainter extends CustomPainter {
  _CompactHeatMapPainter({
    required this.showCircle1,
    required this.putts,
    this.animationValue = 1.0,
  });

  final bool showCircle1;
  final List<Map<String, dynamic>> putts;
  final double animationValue;

  // Same colors as full heat map
  static const List<Color> segmentColors = [
    Color(0xFFE8F5E9), // Very light green
    Color(0xFFF1F8F0), // Extra light green (weaker)
    Colors.white, // White
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.width / 2;

    // Define circle radii
    final double basketRadius = maxRadius * 0.05;
    final double circle1InnerRadius = maxRadius * 0.15;
    final double circle1OuterRadiusSmall = maxRadius * 0.5;
    final double outerRadius = maxRadius;

    // Paint for filled circles
    final Paint closestSegmentPaint = Paint()
      ..color = segmentColors[0]
      ..style = PaintingStyle.fill;

    final Paint middleSegmentPaint = Paint()
      ..color = segmentColors[1]
      ..style = PaintingStyle.fill;

    final Paint farthestSegmentPaint = Paint()
      ..color = segmentColors[2]
      ..style = PaintingStyle.fill;

    // Paint for circle outlines
    final Paint strokePaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    if (showCircle1) {
      // Circle 1 visualization
      canvas.drawCircle(center, outerRadius, farthestSegmentPaint);

      final double segment2Radius =
          circle1InnerRadius + (outerRadius - circle1InnerRadius) * (2 / 3);
      canvas.drawCircle(center, segment2Radius, middleSegmentPaint);

      final double segment1Radius =
          circle1InnerRadius + (outerRadius - circle1InnerRadius) * (1 / 3);
      canvas.drawCircle(center, segment1Radius, closestSegmentPaint);

      canvas.drawCircle(center, outerRadius, strokePaint);
      canvas.drawCircle(center, segment2Radius, strokePaint);
      canvas.drawCircle(center, segment1Radius, strokePaint);

      final Paint basketPaint = Paint()
        ..color = Colors.grey[400]!
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, basketRadius, basketPaint);
    } else {
      // Circle 2 visualization
      canvas.drawCircle(center, outerRadius, farthestSegmentPaint);

      final double c2Segment2Radius =
          circle1OuterRadiusSmall +
          (outerRadius - circle1OuterRadiusSmall) * (2 / 3);
      canvas.drawCircle(center, c2Segment2Radius, middleSegmentPaint);

      final double c2Segment1Radius =
          circle1OuterRadiusSmall +
          (outerRadius - circle1OuterRadiusSmall) * (1 / 3);
      canvas.drawCircle(center, c2Segment1Radius, closestSegmentPaint);

      canvas.drawCircle(center, circle1OuterRadiusSmall, farthestSegmentPaint);

      // Add hash pattern to Circle 1 area
      _drawHashPattern(
        canvas,
        center,
        circle1OuterRadiusSmall,
        Colors.grey[300]!,
      );

      canvas.drawCircle(center, c2Segment2Radius, strokePaint);
      canvas.drawCircle(center, c2Segment1Radius, strokePaint);
      canvas.drawCircle(center, circle1OuterRadiusSmall, strokePaint);
      canvas.drawCircle(center, outerRadius, strokePaint);

      final Paint basketPaint = Paint()
        ..color = Colors.grey[400]!
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, basketRadius, basketPaint);
    }

    // Draw putt dots - same logic as full heat map
    const double angularSpacing = 0.2;

    // Add order index to each putt
    final List<Map<String, dynamic>> puttsWithIndex = [];
    for (int idx = 0; idx < putts.length; idx++) {
      final Map<String, dynamic> putt = putts[idx];
      final double? distance = putt['distance'] as double?;
      if (distance == null) continue;

      final Map<String, dynamic> puttWithIndex = Map<String, dynamic>.from(putt);
      puttWithIndex['orderIndex'] = idx;
      puttsWithIndex.add(puttWithIndex);
    }

    // Group putts by distance buckets
    final Map<int, List<Map<String, dynamic>>> buckets = {};

    for (var putt in puttsWithIndex) {
      final double distance = putt['distance'] as double;
      final int bucketKey = (distance / 2).floor();
      buckets.putIfAbsent(bucketKey, () => []).add(putt);
    }

    final int totalDots = puttsWithIndex.length;

    // Process each bucket and arrange dots symmetrically
    for (var bucket in buckets.values) {
      final int count = bucket.length;
      const double baseAngle = pi / 2;

      for (int i = 0; i < count; i++) {
        final Map<String, dynamic> putt = bucket[i];
        final int orderIndex = putt['orderIndex'] as int;
        final double distance = putt['distance'] as double;
        final bool made = putt['made'] as bool? ?? false;

        // Calculate when this dot appears
        final double dotAppearTime = (orderIndex / totalDots) * 0.85;

        if (animationValue < dotAppearTime) continue;

        // Calculate bounce animation
        final double bounceTime = (animationValue - dotAppearTime) / 0.15;
        final double dotBounceProgress = bounceTime.clamp(0.0, 1.0);

        double bounceScale;
        if (dotBounceProgress <= 0.5) {
          bounceScale = dotBounceProgress * 3.0;
        } else {
          bounceScale = 1.5 - (dotBounceProgress - 0.5) * 1.0;
        }

        if (dotBounceProgress >= 1.0) {
          bounceScale = 1.0;
        }

        // Use green for made putts, red for missed putts
        final Paint dotPaint = Paint()
          ..color = made ? const Color(0xFF4CAF50) : const Color(0xFFEF5350)
          ..style = PaintingStyle.fill;

        // Calculate exact radius based on distance
        double radius;
        if (showCircle1) {
          radius =
              circle1InnerRadius +
              (distance / c1MaxDistance) * (outerRadius - circle1InnerRadius);
        } else {
          final double normalizedDistance = (distance - c2MinDistance) / c1MaxDistance;
          radius =
              circle1OuterRadiusSmall +
              normalizedDistance * (outerRadius - circle1OuterRadiusSmall);
        }

        // Calculate angle offset for symmetrical arrangement
        double angleOffset;
        if (count % 2 == 1) {
          final int centerIndex = count ~/ 2;
          angleOffset = (i - centerIndex) * angularSpacing;
        } else {
          final double centerOffset = count / 2 - 0.5;
          angleOffset = (i - centerOffset) * angularSpacing;
        }

        final double angle = baseAngle + angleOffset;

        // Calculate position
        final double x = center.dx + radius * cos(angle);
        final double y = center.dy + radius * sin(angle);

        // Draw with expand-then-shrink scale effect (smaller dots for compact view)
        canvas.drawCircle(Offset(x, y), 2.5 * bounceScale, dotPaint);
      }
    }
  }

  void _drawHashPattern(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final Paint hashPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.save();

    final Path path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(path);

    const double spacing = 6.0;
    final double diameter = radius * 2;
    final int numLines = (diameter * 1.414 / spacing).ceil();

    for (int i = -numLines; i <= numLines; i++) {
      final double offset = i * spacing;
      canvas.drawLine(
        Offset(center.dx - diameter + offset, center.dy - diameter),
        Offset(center.dx + diameter + offset, center.dy + diameter),
        hashPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CompactHeatMapPainter oldDelegate) {
    return oldDelegate.showCircle1 != showCircle1 ||
        oldDelegate.putts != putts ||
        oldDelegate.animationValue != animationValue;
  }
}

// Disc Usage Card
class _DiscUsageCard extends StatelessWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const _DiscUsageCard({required this.round, this.onTap});

  Map<String, dynamic> _calculateDiscStats() {
    final Map<String, int> discCounts = {};
    final Map<String, int> discC1InReg = {};
    final Map<String, int> discC1Attempts = {};
    int totalThrows = 0;

    for (final DGHole hole in round.holes) {
      for (int i = 0; i < hole.throws.length; i++) {
        final DiscThrow discThrow = hole.throws[i];
        final String discName =
            discThrow.disc?.name ?? discThrow.discName ?? 'Unknown';

        // Skip unknown discs
        if (discName == 'Unknown') continue;

        totalThrows++;
        discCounts[discName] = (discCounts[discName] ?? 0) + 1;

        // Track C1 in regulation (first throw that lands in C1)
        if (i == 0) {
          discC1Attempts[discName] = (discC1Attempts[discName] ?? 0) + 1;
          if (discThrow.landingSpot == LandingSpot.parked ||
              discThrow.landingSpot == LandingSpot.circle1 ||
              discThrow.landingSpot == LandingSpot.inBasket) {
            discC1InReg[discName] = (discC1InReg[discName] ?? 0) + 1;
          }
        }
      }
    }

    // Calculate C1 in Reg percentage for each disc
    final Map<String, double> discC1Percentages = {};
    for (final discName in discCounts.keys) {
      final int attempts = discC1Attempts[discName] ?? 0;
      final int makes = discC1InReg[discName] ?? 0;
      discC1Percentages[discName] = attempts > 0
          ? (makes / attempts * 100)
          : 0.0;
    }

    // Sort by C1 in Reg % (primary), then by throw count (secondary)
    final List<MapEntry<String, double>> sortedDiscs =
        discC1Percentages.entries.toList()..sort((a, b) {
          final c1Comparison = b.value.compareTo(a.value);
          if (c1Comparison != 0) return c1Comparison;
          return (discCounts[b.key] ?? 0).compareTo(discCounts[a.key] ?? 0);
        });

    // Get top 3 discs
    final List<Map<String, dynamic>> topDiscs = sortedDiscs.take(3).map((
      entry,
    ) {
      return {
        'name': entry.key,
        'c1InRegPct': entry.value,
        'throwCount': discCounts[entry.key] ?? 0,
      };
    }).toList();

    return {
      'topDiscs': topDiscs,
      'totalThrows': totalThrows,
      'uniqueDiscs': discCounts.length,
      'hasData': totalThrows > 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> stats = _calculateDiscStats();
    final bool hasData = stats['hasData'] as bool;
    final List<Map<String, dynamic>> topDiscs =
        stats['topDiscs'] as List<Map<String, dynamic>>;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '💿 Top Discs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              if (!hasData)
                const Text(
                  'No disc data available',
                  style: TextStyle(color: Colors.grey),
                )
              else ...[
                const Text(
                  'By C1 in Regulation %',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                if (topDiscs.isNotEmpty)
                  ...topDiscs.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final Map<String, dynamic> disc = entry.value;
                    final String discName = disc['name'] as String;
                    final double c1InRegPct = disc['c1InRegPct'] as double;
                    final int throwCount = disc['throwCount'] as int;
                    final String medal = index == 0
                        ? '🥇'
                        : index == 1
                        ? '🥈'
                        : '🥉';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(medal, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              discName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF137e66,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${c1InRegPct.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF137e66),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$throwCount×',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Mistakes Card
class _MistakesCard extends StatelessWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const _MistakesCard({required this.round, this.onTap});

  Color _getColorForIndex(int index) {
    final List<Color> colors = [
      const Color(0xFFFF7A7A), // Red for top mistake
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFFA726), // Orange
      const Color(0xFF66BB6A), // Green
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final MistakesAnalysisService mistakesService = locator
        .get<MistakesAnalysisService>();
    final int totalMistakes = mistakesService.getTotalMistakesCount(round);
    final List<dynamic> mistakeTypes = mistakesService.getMistakeTypes(round);

    // Filter out mistakes with count > 0 and take top 3
    final List<dynamic> topMistakes = mistakeTypes
        .where((mistake) => mistake.count > 0)
        .take(3)
        .toList();

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '⚠️ Mistakes Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              if (totalMistakes == 0)
                const Text(
                  'No mistakes detected - perfect round!',
                  style: TextStyle(color: Colors.grey),
                )
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$totalMistakes',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF7A7A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'mistakes',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                if (topMistakes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...topMistakes.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final dynamic mistake = entry.value;
                    final int maxCount = topMistakes.first.count;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < topMistakes.length - 1 ? 12 : 0,
                      ),
                      child: _buildBarItem(
                        context,
                        label: mistake.label,
                        count: mistake.count,
                        maxCount: maxCount,
                        color: _getColorForIndex(index),
                      ),
                    );
                  }),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarItem(
    BuildContext context, {
    required String label,
    required int count,
    required int maxCount,
    required Color color,
  }) {
    final double barWidth = maxCount > 0 ? count / maxCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            // Background bar
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Foreground bar (actual value)
            FractionallySizedBox(
              widthFactor: barWidth,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: count > 0
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Mental Game Card
class _MentalGameCard extends StatelessWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const _MentalGameCard({required this.round, this.onTap});

  String _getHotStreakInsight(double percentage) {
    if (percentage > 75) {
      return 'You thrive on momentum!';
    } else if (percentage > 50) {
      return 'Good momentum player.';
    } else if (percentage > 25) {
      return 'Moderate momentum.';
    } else {
      return 'Build momentum together.';
    }
  }

  String _getTiltMeterInsight(double percentage) {
    if (percentage == 0) {
      return 'Ice in your veins 🧊';
    } else if (percentage < 20) {
      return 'Excellent composure!';
    } else if (percentage < 40) {
      return 'Moderate tilt control.';
    } else {
      return 'High tilt. Take a breath.';
    }
  }

  String _getBounceBackInsight(double percentage) {
    if (percentage > 60) {
      return 'Excellent recovery!';
    } else if (percentage > 40) {
      return 'Solid bounce-back.';
    } else if (percentage > 20) {
      return 'Room to grow.';
    } else {
      return 'Practice recovering.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final PsychAnalysisService psychService = locator
        .get<PsychAnalysisService>();
    final psychStats = psychService.getPsychStats(round);

    // Check if we have enough data
    final bool hasData = psychStats.mentalProfile != 'Insufficient Data';

    // Get key transition stats
    final ScoringTransition? birdieTransition =
        psychStats.transitionMatrix['Birdie'];
    final ScoringTransition? bogeyTransition =
        psychStats.transitionMatrix['Bogey'];

    final double hotStreakEnergy = birdieTransition?.toBirdiePercent ?? 0.0;
    final double tiltMeter = bogeyTransition?.bogeyOrWorsePercent ?? 0.0;
    final double bounceBack = psychStats.bounceBackRate;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '🧠 Mental Game',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              if (!hasData)
                const Text(
                  'Play at least 3 holes to see your mental game analysis.',
                  style: TextStyle(color: Colors.grey),
                )
              else ...[
                _buildCompactMoodRow(
                  context,
                  emoji: '🔥',
                  label: 'Hot Streak',
                  percentage: hotStreakEnergy,
                  insight: _getHotStreakInsight(hotStreakEnergy),
                  color: const Color(0xFFFF6B35),
                ),
                const SizedBox(height: 8),
                _buildCompactMoodRow(
                  context,
                  emoji: '😡',
                  label: 'Tilt Meter',
                  percentage: tiltMeter,
                  insight: _getTiltMeterInsight(tiltMeter),
                  color: const Color(0xFFD32F2F),
                ),
                const SizedBox(height: 8),
                _buildCompactMoodRow(
                  context,
                  emoji: '💪',
                  label: 'Bounce-Back',
                  percentage: bounceBack,
                  insight: _getBounceBackInsight(bounceBack),
                  color: const Color(0xFF4CAF50),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactMoodRow(
    BuildContext context, {
    required String emoji,
    required String label,
    required double percentage,
    required String insight,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '➜ $insight',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// AI Coach Card
class _AICoachCard extends StatelessWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const _AICoachCard({required this.round, this.onTap});

  String _truncateMarkdown(String content, int maxChars) {
    // First, try to get the first paragraph or two
    final List<String> lines = content.split('\n');
    final StringBuffer preview = StringBuffer();
    int charCount = 0;

    for (final String line in lines) {
      // Skip headers for preview
      if (line.trim().startsWith('#')) continue;

      final String trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (charCount + trimmed.length > maxChars) {
        // If we already have some content, stop here
        if (preview.isNotEmpty) break;

        // Otherwise, truncate this line
        final int remaining = maxChars - charCount;
        if (remaining > 50) {
          preview.writeln('${trimmed.substring(0, remaining)}...');
        }
        break;
      }

      preview.writeln(trimmed);
      charCount += trimmed.length;

      // Stop after we have a good amount of content
      if (charCount > maxChars * 0.8) break;
    }

    return preview.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSummary =
        round.aiSummary != null && round.aiSummary!.content.isNotEmpty;
    final String? preview = hasSummary
        ? _truncateMarkdown(round.aiSummary!.content, 200)
        : null;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '🤖 AI Insights',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              if (hasSummary && preview != null && preview.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 100),
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: CustomMarkdownContent(
                        data: preview,
                        bodyPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to read full analysis',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ] else
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'AI-powered analysis and coaching advice',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// AI Roast Card
class _AIRoastCard extends StatelessWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const _AIRoastCard({required this.round, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '🔥 AI Roast',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'AI roast coming soon...',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
