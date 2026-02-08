import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Placeholder shown when pro comparison image is not available
/// Shows pro name and measurement if available, with "coming soon" messaging
class ProComparisonPlaceholder extends StatelessWidget {
  const ProComparisonPlaceholder({
    super.key,
    this.proName,
    this.proMeasurement,
    this.aspectRatio = 9 / 16,
  });

  final String? proName;
  final String? proMeasurement;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: SenseiColors.gray[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: SenseiColors.gray[200]!,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pro silhouette icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: SenseiColors.gray[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 28,
                  color: SenseiColors.gray[400],
                ),
              ),
              const SizedBox(height: 8),
              // Pro name
              Text(
                proName ?? 'Pro comparison',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SenseiColors.gray[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Coming soon label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SenseiColors.gray[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Coming soon',
                  style: TextStyle(
                    fontSize: 10,
                    color: SenseiColors.gray[500],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
