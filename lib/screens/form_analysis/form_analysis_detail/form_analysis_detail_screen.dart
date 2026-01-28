import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';

import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/custom_cupertino_action_sheet.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
      child: Container(
        color: SenseiColors.gray[50],
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
            topPadding: 0,
            videoUrl: widget.analysis.videoUrl,
            throwType: _parseThrowTechnique(widget.analysis.throwType),
            cameraAngle: widget.analysis.cameraAngle,
            videoAspectRatio: widget.analysis.videoAspectRatio,
          ),
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
      onOpened: () {
        HapticFeedback.lightImpact();
      },
      onSelected: (String value) {
        HapticFeedback.lightImpact();
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
        'modal_type': 'action_sheet',
        'modal_name': 'Delete Analysis Confirmation',
        'analysis_id': widget.analysis.id,
      },
    );

    final bool? confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext context) {
        return CustomCupertinoActionSheet(
          title: 'Delete Analysis?',
          message:
              'This will permanently delete this form analysis and all associated images. This action cannot be undone.',
          destructiveActionLabel: 'Delete',
          onDestructiveActionPressed: () {
            _logger.track(
              'Delete Analysis Confirmed',
              properties: {'analysis_id': widget.analysis.id},
            );
            Navigator.of(context).pop(true);
          },
          onCancelPressed: () {
            _logger.track(
              'Delete Analysis Cancelled',
              properties: {'analysis_id': widget.analysis.id},
            );
            Navigator.of(context).pop(false);
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      _handleDelete();
    }
  }

  void _handleDelete() {
    final FormAnalysisHistoryCubit cubit =
        BlocProvider.of<FormAnalysisHistoryCubit>(context);

    // Pop immediately for instant feel
    Navigator.pop(context);

    // Fire optimistic delete in background
    cubit.deleteAnalysis(widget.analysis.id);
  }
}
