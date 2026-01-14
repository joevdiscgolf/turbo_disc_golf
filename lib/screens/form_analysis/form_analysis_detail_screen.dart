import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/history_analysis_view.dart';
import 'package:turbo_disc_golf/state/form_analysis_history_cubit.dart';

class FormAnalysisDetailScreen extends StatefulWidget {
  const FormAnalysisDetailScreen({
    super.key,
    required this.analysis,
  });

  final FormAnalysisRecord analysis;

  @override
  State<FormAnalysisDetailScreen> createState() =>
      _FormAnalysisDetailScreenState();
}

class _FormAnalysisDetailScreenState extends State<FormAnalysisDetailScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final double topViewPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEEE8F5),
            Color(0xFFECECEE),
            Color(0xFFE8F4E8),
            Color(0xFFEAE8F0),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GenericAppBar(
          topViewPadding: topViewPadding,
          title: 'Form Analysis',
          backgroundColor: Colors.transparent,
          hasBackButton: true,
          rightWidget: _buildMenuButton(),
        ),
        body: HistoryAnalysisView(
          analysis: widget.analysis,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz),
      enabled: !_isDeleting,
      onSelected: (String value) {
        if (value == 'delete') {
          _showDeleteConfirmation();
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('Delete Analysis', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showDeleteConfirmation() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Analysis?'),
          content: const Text(
            'This will permanently delete this form analysis and all associated images. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _handleDelete();
    }
  }

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);

    final FormAnalysisHistoryCubit cubit =
        BlocProvider.of<FormAnalysisHistoryCubit>(context);

    final bool success = await cubit.deleteAnalysis(widget.analysis.id);

    if (!mounted) return;

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analysis deleted successfully'),
          backgroundColor: Color(0xFF137e66),
        ),
      );

      // Navigate back to history screen
      Navigator.pop(context);
    } else {
      // Show error message
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete analysis. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
