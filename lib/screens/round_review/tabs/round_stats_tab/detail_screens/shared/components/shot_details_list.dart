import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/models/shot_detail.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/shared/components/outcome_badge.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/shared/helpers/score_color_helper.dart';

/// Widget showing the list of shots for a specific shot shape or throw type
class ShotDetailsList extends StatelessWidget {
  const ShotDetailsList({required this.shotDetails, super.key});

  final List<ShotDetail> shotDetails;

  @override
  Widget build(BuildContext context) {
    if (shotDetails.isEmpty) {
      return Text(
        'No shots found',
        style: TextStyle(fontSize: 13, color: const Color(0xFF6B7280)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: shotDetails.map((detail) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: getScoreColor(detail.relativeScore).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${detail.holeNumber}',
                    style: TextStyle(
                      color: getScoreColor(detail.relativeScore),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Par ${detail.par}${detail.distance != null ? ' • ${detail.distance} ft' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
              if (detail.shotOutcome.wasBirdie)
                OutcomeBadge(
                  icon: Icons.emoji_events,
                  color: const Color(0xFF10B981),
                ),
              if (detail.shotOutcome.wasC1InReg)
                OutcomeBadge(
                  icon: Icons.my_location,
                  color: const Color(0xFF3B82F6),
                ),
              if (detail.shotOutcome.wasC2InReg)
                OutcomeBadge(
                  icon: Icons.adjust,
                  color: const Color(0xFF8B5CF6),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
