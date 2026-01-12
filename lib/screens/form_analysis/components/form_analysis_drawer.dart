import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/state/form_analysis_history_cubit.dart';
import 'package:turbo_disc_golf/state/form_analysis_history_state.dart';

/// Drawer showing recent form analysis history.
class FormAnalysisDrawer extends StatelessWidget {
  const FormAnalysisDrawer({super.key, this.onAnalysisSelected});

  /// Called when user selects a historical analysis.
  final void Function(FormAnalysisRecord)? onAnalysisSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            Expanded(child: _buildHistoryList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF137e66).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.history,
                  color: Color(0xFF137e66),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Analysis History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your recent form analyses',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    return BlocBuilder<FormAnalysisHistoryCubit, FormAnalysisHistoryState>(
      builder: (context, state) {
        if (state is FormAnalysisHistoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is FormAnalysisHistoryError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load history',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      context.read<FormAnalysisHistoryCubit>().loadHistory();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is FormAnalysisHistoryLoaded) {
          if (state.analyses.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.analyses.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _buildHistoryItem(context, state.analyses[index]);
            },
          );
        }

        // Initial state - show empty
        return _buildEmptyState(context);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.slow_motion_video,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No analyses yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your form analyses will appear here',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, FormAnalysisRecord analysis) {
    final DateTime createdAt = DateTime.parse(analysis.createdAt);
    final String dateStr = DateFormat.yMMMd().format(createdAt);
    final String timeStr = DateFormat.jm().format(createdAt);

    return ListTile(
      onTap: () {
        Navigator.pop(context); // Close drawer
        onAnalysisSelected?.call(analysis);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: _buildSeverityIndicator(analysis.worstDeviationSeverity),
      title: Row(
        children: [
          _buildThrowTypeBadge(analysis.throwType),
          const SizedBox(width: 8),
          if (analysis.overallFormScore != null)
            Text(
              '${analysis.overallFormScore}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '$dateStr at $timeStr',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          if (analysis.checkpoints.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${analysis.checkpoints.length} checkpoints',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildSeverityIndicator(String? severity) {
    Color color;
    IconData icon;

    switch (severity?.toLowerCase()) {
      case 'good':
        color = const Color(0xFF4CAF50);
        icon = Icons.check_circle;
        break;
      case 'minor':
        color = const Color(0xFFFF9800);
        icon = Icons.info;
        break;
      case 'moderate':
        color = const Color(0xFFFF5722);
        icon = Icons.warning;
        break;
      case 'significant':
        color = const Color(0xFFF44336);
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildThrowTypeBadge(String throwType) {
    final bool isBackhand = throwType.toLowerCase() == 'backhand';
    final Color color = isBackhand
        ? const Color(0xFF2196F3)
        : const Color(0xFF9C27B0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isBackhand ? 'BH' : 'FH',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
