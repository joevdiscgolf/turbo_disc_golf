import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/compact_popup_menu_item.dart';
import 'package:turbo_disc_golf/components/custom_cupertino_action_sheet.dart';
import 'package:turbo_disc_golf/components/form_analysis/form_analysis_tabbed_view.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_response_v2.dart';
import 'package:turbo_disc_golf/models/feature_flags/feature_flag.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/state/form_analysis_history_cubit.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class FormAnalysisDetailScreen extends StatefulWidget {
  static const String routeName = '/form-analysis-detail';
  static const String screenName = 'Form Analysis Detail';

  const FormAnalysisDetailScreen({super.key, required this.analysis});

  final FormAnalysisResponseV2 analysis;

  @override
  State<FormAnalysisDetailScreen> createState() =>
      _FormAnalysisDetailScreenState();
}

class _FormAnalysisDetailScreenState extends State<FormAnalysisDetailScreen>
    with SingleTickerProviderStateMixin {
  late final LoggingServiceBase _logger;
  TabController? _tabController;
  late final bool _showObservationsTab;

  static const List<String> _tabNames = ['Video', 'Observations'];

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

    // Check if observations tab should be shown (empty state handles no data)
    _showObservationsTab = locator.get<FeatureFlagService>().getBool(
      FeatureFlag.showFormObservationsTab,
    );

    // Initialize tab controller if showing tabs
    if (_showObservationsTab) {
      _tabController = TabController(length: 2, vsync: this);
      _tabController!.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    if (_tabController != null && !_tabController!.indexIsChanging) {
      _logger.track(
        'Tab Changed',
        properties: {
          'tab_index': _tabController!.index,
          'tab_name': _tabNames[_tabController!.index],
        },
      );
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topViewPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [SenseiColors.gray[50]!, Colors.white],
            stops: const [0.0, 0.5],
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
            bottomWidget: _showObservationsTab ? _buildTabBar() : null,
            bottomWidgetHeight: _showObservationsTab ? 40 : 0,
          ),
          body: FormAnalysisTabbedView(
            analysis: widget.analysis,
            onBack: () => Navigator.pop(context),
            topPadding: _showObservationsTab ? 8 : 0,
            tabController: _tabController,
            logger: _logger,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      splashFactory: NoSplash.splashFactory,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      labelColor: Colors.black,
      unselectedLabelColor: Colors.black54,
      indicatorColor: Colors.black,
      indicatorWeight: 2,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      labelPadding: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      indicatorPadding: EdgeInsets.zero,
      onTap: (_) => HapticFeedback.lightImpact(),
      tabs: const [
        Tab(text: 'Video'),
        Tab(text: 'Observations'),
      ],
    );
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
        CompactPopupMenuItem<String>(
          value: 'delete',
          label: 'Delete Analysis',
          icon: Icons.delete_outline,
          color: Colors.red,
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
    cubit.deleteAnalysis(widget.analysis.id!);
  }
}
