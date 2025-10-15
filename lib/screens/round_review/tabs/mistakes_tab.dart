import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/round_analysis/mistakes_analysis_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

class MistakesTab extends StatelessWidget {
  final DGRound round;

  const MistakesTab({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    final MistakesAnalysisService mistakesAnalysisService = locator
        .get<MistakesAnalysisService>();

    final totalMistakes = mistakesAnalysisService.getTotalMistakesCount(round);
    final mistakesByCategory = mistakesAnalysisService.getMistakesByCategory(
      round,
    );
    final mistakeTypes = mistakesAnalysisService.getMistakeTypes(round);
    final mistakeDetails = mistakesAnalysisService.getMistakeThrowDetails(
      round,
    );

    if (totalMistakes == 0) {
      return const Center(child: Text('No mistakes detected'));
    }

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 80),
      children: addRunSpacing(
        [
          _buildMistakeKPIs(context, totalMistakes, mistakesByCategory),
          _buildMistakeBreakdown(context, mistakeTypes, totalMistakes),
          _buildMistakesList(context, mistakeDetails),
        ],
        runSpacing: 16,
        axis: Axis.vertical,
      ),
    );
  }

  Widget _buildMistakeKPIs(
    BuildContext context,
    int totalMistakes,
    Map<String, int> mistakesByCategory,
  ) {
    final drivingPct = totalMistakes > 0
        ? (mistakesByCategory['driving']! / totalMistakes) * 100
        : 0.0;
    final approachPct = totalMistakes > 0
        ? (mistakesByCategory['approach']! / totalMistakes) * 100
        : 0.0;
    final puttingPct = totalMistakes > 0
        ? (mistakesByCategory['putting']! / totalMistakes) * 100
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mistake Overview',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    '$totalMistakes',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF7A7A),
                    ),
                  ),
                  Text(
                    'Total Mistakes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildCategoryChip(
                  context,
                  'Driving',
                  '${drivingPct.toStringAsFixed(0)}%',
                  const Color(0xFF2196F3),
                ),
                _buildCategoryChip(
                  context,
                  'Approach',
                  '${approachPct.toStringAsFixed(0)}%',
                  const Color(0xFFFFA726),
                ),
                _buildCategoryChip(
                  context,
                  'Putting',
                  '${puttingPct.toStringAsFixed(0)}%',
                  const Color(0xFF9C27B0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMistakeBreakdown(
    BuildContext context,
    List<dynamic> mistakeTypes,
    int totalMistakes,
  ) {
    final topMistakes = mistakeTypes.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Common Mistakes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...topMistakes.map((mistake) {
              final percentage = totalMistakes > 0
                  ? (mistake.count / totalMistakes) * 100
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            mistake.label,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '${mistake.count} (${percentage.toStringAsFixed(0)}%)',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 12,
                        backgroundColor: const Color(
                          0xFFFF7A7A,
                        ).withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF7A7A),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (topMistakes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.priority_high,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Most common mistake: ${topMistakes.first.label}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMistakesList(
    BuildContext context,
    List<Map<String, dynamic>> mistakes,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Mistakes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...mistakes.map((mistake) {
              final holeNumber = mistake['holeNumber'];
              final throwIndex = mistake['throwIndex'];
              final DiscThrow discThrow = mistake['throw'];
              final label = mistake['label'];

              final List<String> subtitleParts = [];
              subtitleParts.add('Hole $holeNumber, Shot ${throwIndex + 1}');
              if (discThrow.distanceFeetBeforeThrow != null) {
                subtitleParts.add('${discThrow.distanceFeetBeforeThrow} ft');
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withValues(alpha: 0.3),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFF7A7A),
                    child: Text(
                      '$holeNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(subtitleParts.join(' • ')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // todo: Navigate to throw detail view
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
