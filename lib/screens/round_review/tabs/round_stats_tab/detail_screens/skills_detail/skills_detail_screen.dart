import 'dart:math';

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/skills_analysis_service.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';

class SkillsDetailScreen extends StatelessWidget {
  static const String screenName = 'Skills Detail';

  const SkillsDetailScreen({super.key, required this.round});

  final DGRound round;

  @override
  Widget build(BuildContext context) {
    // Track screen impression
    WidgetsBinding.instance.addPostFrameCallback((_) {
      locator.get<LoggingService>().track(
        'Screen Impression',
        properties: {
          'screen_name': SkillsDetailScreen.screenName,
          'screen_class': 'SkillsDetailScreen',
        },
      );
    });

    final SkillsAnalysisService service = SkillsAnalysisService();
    final SkillsAnalysis analysis = service.getSkillsAnalysis(round);

    return Container(
      color: const Color(0xFFF8F9FA),
      child: ListView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 80,
        ),
        children: [
          // Overall score card
          _OverallScoreCard(overallScore: analysis.overallScore),
          const SizedBox(height: 16),

          // Spider chart card
          _SkillsSpiderChartCard(analysis: analysis),
          const SizedBox(height: 16),

          // Individual skill breakdowns
          _SkillBreakdownCard(skill: analysis.backhandDriving),
          const SizedBox(height: 8),
          _SkillBreakdownCard(skill: analysis.forehandDriving),
          const SizedBox(height: 8),
          _SkillBreakdownCard(skill: analysis.approaching),
          const SizedBox(height: 8),
          _SkillBreakdownCard(skill: analysis.putting),
          const SizedBox(height: 8),
          _SkillBreakdownCard(skill: analysis.mentalFocus),
        ],
      ),
    );
  }
}

class _OverallScoreCard extends StatelessWidget {
  const _OverallScoreCard({required this.overallScore});

  final double overallScore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Overall Skills Score',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '${overallScore.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF137e66),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Average across all skills',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillsSpiderChartCard extends StatelessWidget {
  const _SkillsSpiderChartCard({required this.analysis});

  final SkillsAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skills Overview',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1,
              child:
                  locator
                      .get<FeatureFlagService>()
                      .useHeroAnimationsForRoundReview
                  ? Hero(
                      tag: 'skills_spider_chart',
                      child: _SkillsSpiderChart(analysis: analysis),
                    )
                  : _SkillsSpiderChart(analysis: analysis),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillsSpiderChart extends StatelessWidget {
  const _SkillsSpiderChart({required this.analysis});

  final SkillsAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SkillsSpiderChartPainter(skills: analysis.allSkills),
    );
  }
}

class _SkillsSpiderChartPainter extends CustomPainter {
  _SkillsSpiderChartPainter({required this.skills});

  final List<SkillScore> skills;

  static const Color gridColor = Color(0xFFE0E0E0);
  static const Color dataColor = Color(0xFF137e66);
  static const Color dataFillColor = Color(0x33137e66);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width, size.height) / 2 * 0.7;
    final int numSkills = skills.length;

    // Draw grid circles
    _drawGridCircles(canvas, center, radius);

    // Draw axes
    _drawAxes(canvas, center, radius, numSkills);

    // Draw labels
    _drawLabels(canvas, center, radius, numSkills);

    // Draw data polygon
    _drawDataPolygon(canvas, center, radius, numSkills);
  }

  void _drawGridCircles(Canvas canvas, Offset center, double radius) {
    final Paint gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw 5 concentric circles at 20%, 40%, 60%, 80%, 100%
    for (int i = 1; i <= 5; i++) {
      final double currentRadius = radius * (i / 5);
      canvas.drawCircle(center, currentRadius, gridPaint);
    }
  }

  void _drawAxes(Canvas canvas, Offset center, double radius, int numSkills) {
    final Paint axisPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < numSkills; i++) {
      final double angle = (2 * pi / numSkills) * i - (pi / 2);
      final double x = center.dx + radius * cos(angle);
      final double y = center.dy + radius * sin(angle);

      canvas.drawLine(center, Offset(x, y), axisPaint);
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double radius, int numSkills) {
    for (int i = 0; i < numSkills; i++) {
      final double angle = (2 * pi / numSkills) * i - (pi / 2);
      final double labelRadius = radius * 1.2;
      final double x = center.dx + labelRadius * cos(angle);
      final double y = center.dy + labelRadius * sin(angle);

      final String label = skills[i].skillName;
      final String percentage = '${skills[i].percentage.toStringAsFixed(0)}%';

      final TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();

      final TextPainter percentagePainter = TextPainter(
        text: TextSpan(
          text: percentage,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: dataColor,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      percentagePainter.layout();

      // Position label
      double labelX = x - labelPainter.width / 2;
      double labelY = y - labelPainter.height / 2;

      // Adjust for corner positions
      if (angle < -pi / 4 && angle > -3 * pi / 4) {
        // Top
        labelY -= 10;
      } else if (angle > pi / 4 && angle < 3 * pi / 4) {
        // Bottom
        labelY += 10;
      }

      labelPainter.paint(canvas, Offset(labelX, labelY));

      // Paint percentage below label
      final double percentageX = x - percentagePainter.width / 2;
      final double percentageY = labelY + labelPainter.height + 2;
      percentagePainter.paint(canvas, Offset(percentageX, percentageY));
    }
  }

  void _drawDataPolygon(
    Canvas canvas,
    Offset center,
    double radius,
    int numSkills,
  ) {
    final Path dataPath = Path();
    final List<Offset> points = [];

    // Calculate points
    for (int i = 0; i < numSkills; i++) {
      final double angle = (2 * pi / numSkills) * i - (pi / 2);
      final double percentage = skills[i].percentage / 100;
      final double pointRadius = radius * percentage;
      final double x = center.dx + pointRadius * cos(angle);
      final double y = center.dy + pointRadius * sin(angle);

      points.add(Offset(x, y));

      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }

    dataPath.close();

    // Draw filled polygon
    final Paint fillPaint = Paint()
      ..color = dataFillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    // Draw polygon outline
    final Paint strokePaint = Paint()
      ..color = dataColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(dataPath, strokePaint);

    // Draw points
    final Paint pointPaint = Paint()
      ..color = dataColor
      ..style = PaintingStyle.fill;

    for (final Offset point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(_SkillsSpiderChartPainter oldDelegate) {
    return oldDelegate.skills != skills;
  }
}

class _SkillBreakdownCard extends StatelessWidget {
  const _SkillBreakdownCard({required this.skill});

  final SkillScore skill;

  Color get _color {
    if (skill.skillName == 'Backhand Driving') {
      return const Color(0xFF137e66);
    } else if (skill.skillName == 'Forehand Driving') {
      return const Color(0xFF4CAF50);
    } else if (skill.skillName == 'Approaching') {
      return const Color(0xFF2196F3);
    } else if (skill.skillName == 'Putting') {
      return const Color(0xFFFFA726);
    } else {
      return const Color(0xFF9C27B0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  skill.skillName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${skill.percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: skill.percentage / 100,
                minHeight: 8,
                backgroundColor: _color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(_color),
              ),
            ),
            if (skill.maxValue > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${skill.rawValue.toStringAsFixed(0)} / ${skill.maxValue.toStringAsFixed(0)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
