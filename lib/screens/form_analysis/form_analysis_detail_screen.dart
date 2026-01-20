import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';

import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/history_analysis_view.dart';
import 'package:turbo_disc_golf/state/form_analysis_history_cubit.dart';

class FormAnalysisDetailScreen extends StatefulWidget {
  static const String routeName = '/form-analysis-detail';
  static const String screenName = 'Form Analysis Detail';

  const FormAnalysisDetailScreen({super.key, required this.analysis});

  final FormAnalysisRecord analysis;

  @override
  State<FormAnalysisDetailScreen> createState() =>
      _FormAnalysisDetailScreenState();
}

class _FormAnalysisDetailScreenState extends State<FormAnalysisDetailScreen> {
  bool _isDeleting = false;
  late final LoggingServiceBase _logger;

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': FormAnalysisDetailScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('FormAnalysisDetailScreen');
  }

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
          title: 'Form analysis',
          backgroundColor: Colors.transparent,
          hasBackButton: true,
          rightWidget: _buildMenuButton(),
        ),
        body: HistoryAnalysisView(
          analysis: widget.analysis,
          onBack: () => Navigator.pop(context),
          topViewPadding: topViewPadding,
          // Pass video data for video comparison feature (if available)
          videoUrl: widget.analysis.videoUrl,
          throwType: _parseThrowTechnique(widget.analysis.throwType),
          cameraAngle: widget.analysis.cameraAngle,
          videoAspectRatio: widget.analysis.videoAspectRatio,
        ),
      ),
    );
  }

  /// Parse throw technique string to enum (for video comparison feature)
  ThrowTechnique? _parseThrowTechnique(String throwTypeStr) {
    final String lowerCase = throwTypeStr.toLowerCase();
    switch (lowerCase) {
      case 'backhand':
        return ThrowTechnique.backhand;
      case 'forehand':
        return ThrowTechnique.forehand;
      case 'tomahawk':
        return ThrowTechnique.tomahawk;
      case 'thumber':
        return ThrowTechnique.thumber;
      case 'overhand':
        return ThrowTechnique.overhand;
      default:
        return null; // Unknown throw type
    }
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz),
      enabled: !_isDeleting,
      onSelected: (String value) {
        if (value == 'delete') {
          _logger.track(
            'Delete Analysis Menu Item Tapped',
            properties: {'analysis_id': widget.analysis.id},
          );
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
    // Track modal opened
    _logger.track(
      'Modal Opened',
      properties: {
        'modal_type': 'dialog',
        'modal_name': 'Delete Analysis Confirmation',
        'analysis_id': widget.analysis.id,
      },
    );

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
              onPressed: () {
                _logger.track(
                  'Delete Analysis Cancelled',
                  properties: {'analysis_id': widget.analysis.id},
                );
                Navigator.pop(context, false);
              },
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
      _logger.track(
        'Delete Analysis Confirmed',
        properties: {'analysis_id': widget.analysis.id},
      );
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
      locator.get<ToastService>().showSuccess('Analysis deleted successfully');

      // Navigate back to history screen
      Navigator.pop(context);
    } else {
      // Show error message
      setState(() => _isDeleting = false);
      locator.get<ToastService>().showError(
        'Failed to delete analysis. Please try again.',
      );
    }
  }
}
