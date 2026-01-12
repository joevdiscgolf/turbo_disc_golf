import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_result.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/checkpoint_result_card.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/improvement_list.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/pose_comparison_section.dart';
import 'package:turbo_disc_golf/state/video_form_analysis_cubit.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

/// View displaying the complete form analysis results.
class AnalysisResultsView extends StatelessWidget {
  const AnalysisResultsView({
    super.key,
    required this.result,
    this.poseAnalysis,
  });

  final FormAnalysisResult result;
  final PoseAnalysisResponse? poseAnalysis;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (showFormAnalysisScoreAndSummary) ...[
          SliverToBoxAdapter(child: _buildScoreHeader(context)),
          SliverToBoxAdapter(child: _buildOverallFeedback(context)),
        ],
        // Pose comparison section (if pose analysis is available)
        if (poseAnalysis != null) ...[
          SliverToBoxAdapter(
            child: SizedBox(height: showFormAnalysisScoreAndSummary ? 24 : 16),
          ),
          SliverToBoxAdapter(
            child: PoseComparisonSection(poseAnalysis: poseAnalysis!),
          ),
        ],
        if (showFormAnalysisScoreAndSummary) ...[
          SliverToBoxAdapter(
            child: _buildSectionTitle(context, 'Checkpoint Analysis'),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: CheckpointResultCard(
                  result: result.checkpointResults[index],
                ),
              ),
              childCount: result.checkpointResults.length,
            ),
          ),
          if (result.prioritizedImprovements.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionTitle(context, 'Prioritized Improvements'),
            ),
            SliverToBoxAdapter(
              child:
                  ImprovementList(improvements: result.prioritizedImprovements),
            ),
          ],
        ],
        SliverToBoxAdapter(child: _buildActionButtons(context)),
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }

  Widget _buildScoreHeader(BuildContext context) {
    final Color scoreColor = _getScoreColor(result.overallScore);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor,
            scoreColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Overall Score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            '${result.overallScore}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 72,
                ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getScoreLabel(result.overallScore),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallFeedback(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF137e66).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.summarize,
                  size: 20,
                  color: Color(0xFF137e66),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            result.overallFeedback,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: Colors.grey[800],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: PrimaryButton(
        width: double.infinity,
        height: 56,
        label: 'Analyze Another Video',
        icon: Icons.replay,
        gradientBackground: const [Color(0xFF137e66), Color(0xFF1a9f7f)],
        fontSize: 16,
        fontWeight: FontWeight.w600,
        onPressed: () {
          HapticFeedback.lightImpact();
          BlocProvider.of<VideoFormAnalysisCubit>(context).reset();
        },
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFF2196F3);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _getScoreLabel(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Great';
    if (score >= 70) return 'Good';
    if (score >= 60) return 'Solid';
    if (score >= 50) return 'Developing';
    if (score >= 40) return 'Needs Work';
    return 'Keep Practicing';
  }
}
