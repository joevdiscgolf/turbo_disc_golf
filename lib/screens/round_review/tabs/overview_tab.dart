import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/utils/putting_constants.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/course_tab/components/score_kpi_card.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/services/round_analysis/mistakes_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/psych_analysis_service.dart';
import 'package:turbo_disc_golf/widgets/circular_stat_indicator.dart';

class OverviewTab extends StatefulWidget {
  final DGRound round;
  final TabController? tabController;

  const OverviewTab({
    super.key,
    required this.round,
    this.tabController,
  });

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
            onTap: () => _navigateToTab(2), // Scores tab
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
          child: _DiscUsageCard(
            round: widget.round,
            onTap: () => _navigateToTab(5), // Discs tab
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
    int totalDrives = 0;
    int fairwayHits = 0;
    int obDrives = 0;
    int c1InReg = 0;
    int totalDistance = 0;
    int distanceCount = 0;

    for (final DGHole hole in round.holes) {
      if (hole.throws.isEmpty) continue;

      // First throw is the drive
      final DiscThrow drive = hole.throws.first;
      totalDrives++;

      // Check if fairway hit
      if (drive.landingSpot == LandingSpot.fairway ||
          drive.landingSpot == LandingSpot.parked ||
          drive.landingSpot == LandingSpot.circle1 ||
          drive.landingSpot == LandingSpot.circle2 ||
          drive.landingSpot == LandingSpot.inBasket) {
        fairwayHits++;
      }

      // Check if OB
      if (drive.landingSpot == LandingSpot.outOfBounds || (drive.penaltyStrokes ?? 0) > 0) {
        obDrives++;
      }

      // Check if C1 in regulation (parked or in C1 on first throw)
      if (drive.landingSpot == LandingSpot.parked ||
          drive.landingSpot == LandingSpot.circle1 ||
          drive.landingSpot == LandingSpot.inBasket) {
        c1InReg++;
      }

      // Calculate distance if available
      if (drive.distanceFeetAfterThrow != null) {
        totalDistance += drive.distanceFeetAfterThrow!;
        distanceCount++;
      }
    }

    final double fairwayPct = totalDrives > 0 ? (fairwayHits / totalDrives * 100) : 0;
    final double avgDistance = distanceCount > 0 ? (totalDistance / distanceCount) : 0;
    final double c1InRegPct = totalDrives > 0 ? (c1InReg / totalDrives * 100) : 0;

    return {
      'fairwayPct': fairwayPct,
      'avgDistance': avgDistance,
      'c1InRegPct': c1InRegPct,
      'obDrives': obDrives,
      'hasData': totalDrives > 0,
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
                children: [
                  Expanded(
                    child: _buildMetricBox(
                      'Fairway %',
                      hasData ? '${stats['fairwayPct'].toStringAsFixed(0)}%' : '—',
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricBox(
                      'Avg Distance',
                      hasData && stats['avgDistance'] > 0
                          ? '${stats['avgDistance'].toStringAsFixed(0)} ft'
                          : '—',
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricBox(
                      'C1 in Reg',
                      hasData ? '${stats['c1InRegPct'].toStringAsFixed(0)}%' : '—',
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricBox(
                      'OB Drives',
                      hasData ? '${stats['obDrives']}' : '—',
                      Colors.red,
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

  Widget _buildMetricBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
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
    int scrambles = 0;
    int scrambleAttempts = 0;
    final List<bool> allPutts = [];

    for (final DGHole hole in round.holes) {
      for (final DiscThrow discThrow in hole.throws) {
        if (discThrow.purpose == ThrowPurpose.putt) {
          totalPutts++;
          final double? distance = discThrow.distanceFeetBeforeThrow?.toDouble();
          final bool made = discThrow.landingSpot == LandingSpot.inBasket;
          allPutts.add(made);

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
        final bool missedFairway = drive.landingSpot == LandingSpot.offFairway ||
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
    final double scramblePct = scrambleAttempts > 0 ? (scrambles / scrambleAttempts * 100) : 0;

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
      'scramblePct': scramblePct,
      'hasData': totalPutts > 0,
      'allPutts': allPutts,
    };
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> stats = _calculatePuttingStats();
    final bool hasData = stats['hasData'] as bool;
    final List<bool> allPutts = stats['allPutts'] as List<bool>;

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
              if (hasData && allPutts.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allPutts.map((made) {
                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: made
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF7A7A),
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CircularStatIndicator(
                    label: 'C1',
                    percentage: hasData ? stats['c1Pct'] as double : 0.0,
                    color: const Color(0xFF137e66),
                    internalLabel: hasData
                        ? '(${stats['c1Makes']}/${stats['c1Attempts']})'
                        : '(—)',
                    size: 90,
                    shouldAnimate: true,
                    shouldGlow: true,
                  ),
                  CircularStatIndicator(
                    label: 'C1X',
                    percentage: hasData ? stats['c1xPct'] as double : 0.0,
                    color: const Color(0xFF4CAF50),
                    internalLabel: hasData
                        ? '(${stats['c1xMakes']}/${stats['c1xAttempts']})'
                        : '(—)',
                    size: 90,
                    shouldAnimate: true,
                    shouldGlow: true,
                  ),
                  CircularStatIndicator(
                    label: 'C2',
                    percentage: hasData ? stats['c2Pct'] as double : 0.0,
                    color: const Color(0xFF2196F3),
                    internalLabel: hasData
                        ? '(${stats['c2Makes']}/${stats['c2Attempts']})'
                        : '(—)',
                    size: 90,
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
        final String discName = discThrow.disc?.name ?? discThrow.discName ?? 'Unknown';

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
      discC1Percentages[discName] = attempts > 0 ? (makes / attempts * 100) : 0.0;
    }

    // Sort by C1 in Reg % (primary), then by throw count (secondary)
    final List<MapEntry<String, double>> sortedDiscs = discC1Percentages.entries.toList()
      ..sort((a, b) {
        final c1Comparison = b.value.compareTo(a.value);
        if (c1Comparison != 0) return c1Comparison;
        return (discCounts[b.key] ?? 0).compareTo(discCounts[a.key] ?? 0);
      });

    // Get top 3 discs
    final List<Map<String, dynamic>> topDiscs = sortedDiscs.take(3).map((entry) {
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
    final List<Map<String, dynamic>> topDiscs = stats['topDiscs'] as List<Map<String, dynamic>>;

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
                    final String medal = index == 0 ? '🥇' : index == 1 ? '🥈' : '🥉';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            medal,
                            style: const TextStyle(fontSize: 20),
                          ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF137e66).withValues(alpha: 0.15),
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

  @override
  Widget build(BuildContext context) {
    final MistakesAnalysisService mistakesService = locator.get<MistakesAnalysisService>();
    final int totalMistakes = mistakesService.getTotalMistakesCount(round);
    final Map<String, int> mistakesByCategory = mistakesService.getMistakesByCategory(round);
    final List<dynamic> mistakeTypes = mistakesService.getMistakeTypes(round);

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
                Center(
                  child: Column(
                    children: [
                      Text(
                        '$totalMistakes',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF7A7A),
                        ),
                      ),
                      const Text(
                        'Total Mistakes',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMistakePill(
                      'Driving',
                      mistakesByCategory['driving'] ?? 0,
                      const Color(0xFF2196F3),
                    ),
                    _buildMistakePill(
                      'Approach',
                      mistakesByCategory['approach'] ?? 0,
                      const Color(0xFFFFA726),
                    ),
                    _buildMistakePill(
                      'Putting',
                      mistakesByCategory['putting'] ?? 0,
                      const Color(0xFF9C27B0),
                    ),
                  ],
                ),
                if (mistakeTypes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7A7A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF7A7A).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.priority_high,
                          color: Color(0xFFFF7A7A),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Most common: ${mistakeTypes.first.label}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMistakePill(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// Mental Game Card
class _MentalGameCard extends StatelessWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const _MentalGameCard({required this.round, this.onTap});

  @override
  Widget build(BuildContext context) {
    final PsychAnalysisService psychService = locator.get<PsychAnalysisService>();
    final psychStats = psychService.getPsychStats(round);

    // Check if we have enough data
    final bool hasData = psychStats.mentalProfile != 'Insufficient Data';

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
              const SizedBox(height: 16),
              if (!hasData)
                const Text(
                  'Play at least 3 holes to see your mental game analysis.',
                  style: TextStyle(color: Colors.grey),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profile',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            Text(
                              psychStats.mentalProfile,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMentalMetric(
                        'Bounce Back',
                        '${psychStats.bounceBackRate.toStringAsFixed(0)}%',
                        const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMentalMetric(
                        'Par Streak',
                        '${psychStats.longestParStreak}',
                        const Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
                if (psychStats.insights.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            psychStats.insights.first,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMentalMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
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
                    '🤖 AI Insights',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.chevron_right, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 12),
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
                      'Get AI-powered analysis and coaching advice in the Summary tab',
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
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
