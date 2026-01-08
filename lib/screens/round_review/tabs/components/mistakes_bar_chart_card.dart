import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

class MistakesBarChartCard extends StatefulWidget {
  final int totalMistakes;
  final List<dynamic> mistakeTypes;
  final List<Map<String, dynamic>> mistakeDetails;

  const MistakesBarChartCard({
    super.key,
    required this.totalMistakes,
    required this.mistakeTypes,
    required this.mistakeDetails,
  });

  @override
  State<MistakesBarChartCard> createState() => _MistakesBarChartCardState();
}

class _MistakesBarChartCardState extends State<MistakesBarChartCard> {
  bool _isExpanded = false;

  Color _getColorForIndex(int index) {
    final List<Color> colors = [
      const Color(0xFFFF7A7A), // Red for top mistake
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFFA726), // Orange
      const Color(0xFF66BB6A), // Green
      const Color(0xFFEC407A), // Pink
      const Color(0xFF42A5F5), // Light blue
      const Color(0xFFAB47BC), // Deep purple
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    // Filter out mistakes with count > 0
    final List<dynamic> nonZeroMistakes = widget.mistakeTypes
        .where((mistake) => mistake.count > 0)
        .toList();

    if (nonZeroMistakes.isEmpty) {
      return const SizedBox.shrink();
    }

    final int maxCount = nonZeroMistakes
        .map((m) => m.count as int)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: useHeroAnimationsForRoundReview
                        ? Hero(
                            tag: 'mistakes_count',
                            child: Material(
                              color: Colors.transparent,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${widget.totalMistakes}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFFF7A7A),
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'mistakes',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${widget.totalMistakes}',
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF7A7A),
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'mistakes',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...nonZeroMistakes.asMap().entries.map((entry) {
                final int index = entry.key;
                final dynamic mistake = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < nonZeroMistakes.length - 1 ? 16 : 0,
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
              // Expandable section with all mistakes
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          Text(
                            'All Mistakes',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ...widget.mistakeDetails.map((mistake) {
                            return _buildMistakeListItem(context, mistake);
                          }),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMistakeListItem(
    BuildContext context,
    Map<String, dynamic> mistake,
  ) {
    final int holeNumber = mistake['holeNumber'];
    final int throwIndex = mistake['throwIndex'];
    final DiscThrow discThrow = mistake['throw'];
    final String label = mistake['label'];

    final List<String> subtitleParts = [];
    subtitleParts.add('Shot ${throwIndex + 1}');
    if (discThrow.distanceFeetBeforeThrow != null) {
      subtitleParts.add('${discThrow.distanceFeetBeforeThrow} ft');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(
        context,
      ).colorScheme.errorContainer.withValues(alpha: 0.2),
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
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitleParts.join(' • ')),
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
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Background bar
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // Foreground bar (actual value)
            FractionallySizedBox(
              widthFactor: barWidth,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
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
