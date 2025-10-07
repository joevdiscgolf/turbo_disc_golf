import 'dart:math';

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/gpt_analysis_service.dart';

class GPTRoundSummaryTab extends StatefulWidget {
  final DGRound round;

  const GPTRoundSummaryTab({super.key, required this.round});

  @override
  GPTRoundSummaryTabState createState() => GPTRoundSummaryTabState();
}

class GPTRoundSummaryTabState extends State<GPTRoundSummaryTab> {
  late RoundAnalysis analysis;

  @override
  void initState() {
    super.initState();
    analysis = GPTAnalysisService.analyzeRound(widget.round);
  }

  @override
  Widget build(BuildContext context) {
    final totalScore = widget.round.holes.fold<int>(
      0,
      (p, h) => p + h.holeScore,
    );
    final totalPar = widget.round.holes.fold<int>(0, (p, h) => p + h.par);
    final scoreText = '$totalScore (par $totalPar)';

    return SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top KPI band
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text('Score', style: TextStyle(fontSize: 12)),
                        Text(
                          scoreText,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Card(
                  color: analysis.netObvious >= 0
                      ? Colors.green[50]
                      : Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text('NetObvious', style: TextStyle(fontSize: 12)),
                        Text(
                          analysis.netObvious.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          analysis.netObvious >= 0
                              ? 'Gains > Losses'
                              : 'Losses > Gains',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          // KPI cards row
          Row(
            children: [
              _kpiCard('OBs', analysis.obviousLossCount.toString()),
              SizedBox(width: 8),
              _kpiCard(
                'Missed C1',
                (analysis.coachingCards
                            .firstWhere(
                              (c) => c.reason == LossReason.missedC1,
                              orElse: () => CoachingCard(
                                reason: LossReason.none,
                                title: 'None',
                                summary: '',
                                drills: [],
                                priorityScore: 0,
                              ),
                            )
                            .priorityScore >
                        0)
                    ? '${analysis.countByReason[LossReason.missedC1] ?? 0}'
                    : '0',
              ),
              SizedBox(width: 8),
              _kpiCard(
                'Drive Fairway %',
                '${_calcDriveFairwayPct(analysis).toStringAsFixed(0)}%',
              ),
            ],
          ),

          SizedBox(height: 12),

          // Stacked Good / Neutral / Bad visual summary
          Text(
            'Shot quality distribution',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          _stackedQualityBar(analysis),

          SizedBox(height: 12),

          // Shot map (simple list)
          Text(
            'Sho ts (tap for details)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          _shotList(),

          SizedBox(height: 16),

          // Coaching cards
          Text(
            'Top coaching suggestions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...analysis.coachingCards.take(3).map((c) => _coachingCard(c)),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value) {
    return Expanded(
      child: Card(
        child: Container(
          padding: EdgeInsets.all(10),
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: TextStyle(fontSize: 12)),
              SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calcDriveFairwayPct(RoundAnalysis a) {
    // average of per-hole driveFairwayPct
    final sum = a.holeAnalyses.fold<double>(
      0.0,
      (p, h) => p + h.driveFairwayPct,
    );
    return (sum / max(1, a.holeAnalyses.length)) * 100.0;
  }

  Widget _stackedQualityBar(RoundAnalysis a) {
    int goods = 0;
    int neutrals = 0;
    int bads = 0;
    for (final h in a.holeAnalyses) {
      for (final ta in h.throwAnalyses) {
        switch (ta.execCategory) {
          case ExecCategory.good:
            goods++;
            break;
          case ExecCategory.neutral:
            neutrals++;
            break;
          case ExecCategory.bad:
          case ExecCategory.severe:
            bads++;
            break;
        }
      }
    }
    final total = max(1, goods + neutrals + bads);
    final gw = goods / total;
    final nw = neutrals / total;
    final bw = bads / total;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Row(
          children: [
            Container(width: width * gw, height: 18, color: Colors.green),
            Container(width: width * nw, height: 18, color: Colors.amber),
            Container(width: width * bw, height: 18, color: Colors.red),
          ],
        );
      },
    );
  }

  Widget _shotList() {
    // Flatten throws across holes
    final rows = <Widget>[];
    for (final h in analysis.holeAnalyses) {
      for (final ta in h.throwAnalyses) {
        rows.add(
          ListTile(
            visualDensity: VisualDensity.compact,
            leading: _execIcon(ta),
            title: Text(
              'Hole ${h.hole.number} • Throw ${ta.discThrow.index + 1} • ${describePurpose(ta.discThrow.purpose)}',
            ),
            subtitle: Text(ta.note),
            trailing: Text(
              ta.weight > 0
                  ? '+${ta.weight}'
                  : '-${ta.weight.toStringAsFixed(1)}',
            ),
            onTap: () => _showThrowDetail(context, ta, h),
          ),
        );
      }
    }
    return Card(child: Column(children: rows));
  }

  Widget _execIcon(ThrowAnalysis ta) {
    switch (ta.execCategory) {
      case ExecCategory.good:
        return CircleAvatar(backgroundColor: Colors.green, radius: 10);
      case ExecCategory.neutral:
        return CircleAvatar(backgroundColor: Colors.grey, radius: 10);
      case ExecCategory.bad:
        return CircleAvatar(backgroundColor: Colors.orange, radius: 10);
      case ExecCategory.severe:
        return CircleAvatar(backgroundColor: Colors.red, radius: 10);
    }
  }

  void _showThrowDetail(BuildContext ctx, ThrowAnalysis ta, HoleAnalysis hole) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hole ${hole.hole.number} • Throw ${ta.discThrow.index + 1}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text('Exec: '),
                  Text(
                    describeExec(ta.execCategory),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 12),
                  Text('Weight: ${ta.weight}'),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Reason: ${GPTAnalysisService.describeLossReason(ta.lossReason)}',
              ),
              SizedBox(height: 10),
              Text('Note: ${ta.note}'),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _coachingCard(CoachingCard c) {
    return Card(
      color: Colors.blueGrey[50],
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(c.title, style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Priority: ${c.priorityScore.toStringAsFixed(2)}'),
              ],
            ),
            SizedBox(height: 8),
            Text(c.summary),
            SizedBox(height: 8),
            ...c.drills.map(
              (d) => Row(
                children: [
                  Icon(Icons.fitness_center, size: 14),
                  SizedBox(width: 6),
                  Expanded(child: Text(d)),
                ],
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(onPressed: () {}, child: Text('Start Drill')),
                SizedBox(width: 8),
                TextButton(onPressed: () {}, child: Text('Snooze')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // helper describers (small)
  String describePurpose(ThrowPurpose? p) {
    if (p == null) return 'unknown';
    switch (p) {
      case ThrowPurpose.teeDrive:
        return 'Tee';
      case ThrowPurpose.fairwayDrive:
        return 'Fairway drive';
      case ThrowPurpose.approach:
        return 'Approach';
      case ThrowPurpose.putt:
        return 'Putt';
      case ThrowPurpose.scramble:
        return 'Scramble';
      default:
        return p.name;
    }
  }

  String describeExec(ExecCategory e) {
    switch (e) {
      case ExecCategory.good:
        return 'Good';
      case ExecCategory.neutral:
        return 'Neutral';
      case ExecCategory.bad:
        return 'Bad';
      case ExecCategory.severe:
        return 'Severe';
    }
  }
}
