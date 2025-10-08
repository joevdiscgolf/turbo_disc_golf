import 'package:flutter/material.dart';

class PuttingDistanceCard extends StatelessWidget {
  final double avgMakeDistance;
  final double avgAttemptDistance;
  final double avgBirdiePuttDistance;
  final double totalMadeDistance;
  final double horizontalPadding;

  const PuttingDistanceCard({
    super.key,
    required this.avgMakeDistance,
    required this.avgAttemptDistance,
    required this.avgBirdiePuttDistance,
    required this.totalMadeDistance,
    this.horizontalPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Putting Distance Stats',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  context,
                  'Avg Made',
                  '${avgMakeDistance.toStringAsFixed(1)} ft',
                  const Color(0xFF00F5D4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  context,
                  'Avg Attempted',
                  '${avgAttemptDistance.toStringAsFixed(1)} ft',
                  const Color(0xFF10E5FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  context,
                  'Avg Birdie Putt',
                  '${avgBirdiePuttDistance.toStringAsFixed(1)} ft',
                  const Color(0xFFFFB800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  context,
                  'Total Made',
                  '${totalMadeDistance.toStringAsFixed(0)} ft',
                  const Color(0xFFFF7A7A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    BuildContext context,
    String label,
    String value,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
