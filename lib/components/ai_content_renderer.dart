import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/custom_markdown_content.dart';
import 'package:turbo_disc_golf/components/stat_card_registry.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';

/// Renders AI content with embedded stat cards
///
/// Takes an AIContent object and renders it as a series of segments,
/// alternating between markdown text and interactive stat card widgets.
///
/// If the AIContent has no segments, falls back to rendering the raw
/// content as plain markdown (backward compatibility).
class AIContentRenderer extends StatelessWidget {
  const AIContentRenderer({
    super.key,
    required this.aiContent,
    required this.round,
    required this.analysis,
  });

  final AIContent aiContent;
  final DGRound round;
  final RoundAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    // If no segments, fall back to plain markdown rendering
    if (aiContent.segments == null || aiContent.segments!.isEmpty) {
      return CustomMarkdownContent(data: aiContent.content);
    }

    // Render segments
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: aiContent.segments!.map((segment) {
        return _buildSegment(context, segment);
      }).toList(),
    );
  }

  Widget _buildSegment(BuildContext context, AIContentSegment segment) {
    switch (segment.type) {
      case AISegmentType.markdown:
        return _buildMarkdownSegment(segment);

      case AISegmentType.statCard:
        return _buildStatCardSegment(segment);
    }
  }

  /// Build a markdown text segment
  Widget _buildMarkdownSegment(AIContentSegment segment) {
    return CustomMarkdownContent(data: segment.content);
  }

  /// Build a stat card widget segment
  Widget _buildStatCardSegment(AIContentSegment segment) {
    final widget = StatCardRegistry.buildCard(
      segment.content,
      round,
      analysis,
      params: segment.params,
    );

    // If card is null or returns empty widget, show nothing
    if (widget == null) {
      return const SizedBox.shrink();
    }

    // Add spacing around the card
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: widget,
    );
  }
}
