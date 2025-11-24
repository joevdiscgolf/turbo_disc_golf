import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/improvement_scenario.dart';

class ImprovementScenarioItem extends StatelessWidget {
  final ImprovementScenario scenario;
  final int currentScore;

  const ImprovementScenarioItem({
    super.key,
    required this.scenario,
    required this.currentScore,
  });

  @override
  Widget build(BuildContext context) {
    if (scenario.affectedHoles.isEmpty) {
      return const SizedBox.shrink();
    }

    final targetScore = currentScore - scenario.strokesSaved;
    final targetScoreStr = targetScore >= 0 ? '+$targetScore' : '$targetScore';

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getCategoryColor(context).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  scenario.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scenario.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scenario.category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-${scenario.strokesSaved}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getCategoryColor(context),
                  ),
                ),
                Text(
                  'Target: $targetScoreStr',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scenario.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Affected Holes (${scenario.affectedHoles.length})',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...scenario.affectedHoles.map((hole) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(
                              context,
                            ).withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${hole.number}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Par ${hole.par}${' • ${hole.feet} ft'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(
                              context,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            scenario.getImprovementLabel(hole),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 10,
                                  color: _getCategoryColor(context),
                                ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(BuildContext context) {
    switch (scenario.category.toLowerCase()) {
      case 'easy wins':
      case 'putting':
        return const Color(0xFF137e66);
      case 'short game':
      case 'scrambling':
        return const Color(0xFF2196F3);
      case 'mental game':
      case 'course management':
        return const Color(0xFFFFA726);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
