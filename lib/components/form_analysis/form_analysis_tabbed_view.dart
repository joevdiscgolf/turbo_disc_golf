import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_response_v2.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/feature_flags/feature_flag.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/history_analysis_view.dart';
import 'package:turbo_disc_golf/screens/form_analysis/tabs/form_observations_tab.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';

/// Reusable tabbed view for form analysis results.
///
/// Displays a tab bar with "Video" and "Observations" tabs when observations
/// are available and the feature flag is enabled. Otherwise, shows only the
/// video analysis view.
///
/// Used by both [AnalysisResultsView] (fresh analysis) and
/// [FormAnalysisDetailScreen] (historical analysis) to ensure consistent
/// display across the app.
class FormAnalysisTabbedView extends StatefulWidget {
  const FormAnalysisTabbedView({
    super.key,
    required this.analysis,
    required this.onBack,
    this.topPadding = 0,
    this.poseAnalysisResponse,
    this.tabController,
    this.logger,
  });

  /// The form analysis data to display.
  final FormAnalysisResponseV2 analysis;

  /// Callback when back navigation is triggered.
  final VoidCallback onBack;

  /// Top padding for the content (e.g., for app bar spacing).
  final double topPadding;

  /// Optional pose analysis response for fresh analyses.
  /// Contains video sync metadata for synchronized video playback.
  final FormAnalysisResponseV2? poseAnalysisResponse;

  /// Optional external tab controller.
  /// When provided, this controller is used instead of creating an internal one.
  /// The caller is responsible for managing the controller's lifecycle.
  final TabController? tabController;

  /// Optional logger for analytics. If not provided, creates its own.
  final LoggingServiceBase? logger;

  @override
  State<FormAnalysisTabbedView> createState() => FormAnalysisTabbedViewState();
}

class FormAnalysisTabbedViewState extends State<FormAnalysisTabbedView>
    with SingleTickerProviderStateMixin {
  TabController? _internalTabController;
  late final bool _showObservationsTab;
  late final LoggingServiceBase _logger;
  bool _ownsTabController = false;

  static const List<String> _tabNames = ['Video', 'Observations'];

  /// Returns the effective tab controller (external or internal).
  TabController? get tabController =>
      widget.tabController ?? _internalTabController;

  /// Returns whether the observations tab should be shown.
  bool get showObservationsTab => _showObservationsTab;

  @override
  void initState() {
    super.initState();

    // Use provided logger or create one
    _logger = widget.logger ??
        locator.get<LoggingService>().withBaseProperties({
          'screen_name': 'Form Analysis Tabbed View',
        });

    // Check if observations tab should be shown
    _showObservationsTab =
        locator.get<FeatureFlagService>().getBool(
              FeatureFlag.showFormObservationsTab,
            ) &&
            widget.analysis.formObservations != null;

    // Use external controller if provided, otherwise create internal one
    if (_showObservationsTab) {
      if (widget.tabController != null) {
        widget.tabController!.addListener(_onTabChanged);
      } else {
        _internalTabController = TabController(length: 2, vsync: this);
        _internalTabController!.addListener(_onTabChanged);
        _ownsTabController = true;
      }
    }
  }

  void _onTabChanged() {
    final TabController? controller = tabController;
    if (controller != null && !controller.indexIsChanging) {
      _logger.track(
        'Tab Changed',
        properties: {
          'tab_index': controller.index,
          'tab_name': _tabNames[controller.index],
        },
      );
    }
  }

  @override
  void dispose() {
    if (widget.tabController != null) {
      widget.tabController!.removeListener(_onTabChanged);
    }
    if (_ownsTabController) {
      _internalTabController?.removeListener(_onTabChanged);
      _internalTabController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showObservationsTab) {
      return TabBarView(
        controller: tabController,
        children: [
          _buildVideoTab(),
          FormObservationsTab(analysis: widget.analysis),
        ],
      );
    }

    return _buildVideoTab();
  }

  Widget _buildVideoTab() {
    return HistoryAnalysisView(
      analysis: widget.analysis,
      onBack: widget.onBack,
      topPadding: widget.topPadding,
      throwType: _parseThrowTechnique(widget.analysis.analysisResults.throwType),
      cameraAngle: widget.analysis.analysisResults.cameraAngle,
      videoAspectRatio: widget.analysis.videoMetadata.videoAspectRatio,
      poseAnalysisResponse: widget.poseAnalysisResponse,
    );
  }

  /// Parse throw technique string to enum.
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
        return null;
    }
  }

  /// Builds a standard tab bar widget for use in AppBar or elsewhere.
  Widget buildTabBar() {
    return TabBar(
      controller: tabController,
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
}
