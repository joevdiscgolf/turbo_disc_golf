import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:turbo_disc_golf/components/form_analysis/form_analysis_tabbed_view.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_response_v2.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_result.dart';
import 'package:turbo_disc_golf/models/feature_flags/feature_flag.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// View displaying the complete form analysis results with tab support.
///
/// Uses FormAnalysisTabbedView to show "Video" and "Observations" tabs
/// when observations are available. The tab bar is rendered as part of
/// the content since this view is used in screens where we don't control
/// the app bar.
class AnalysisResultsView extends StatefulWidget {
  const AnalysisResultsView({
    super.key,
    this.result,
    this.poseAnalysis,
    required this.topViewPadding,
  });

  final FormAnalysisResult? result;
  final FormAnalysisResponseV2? poseAnalysis;
  final double topViewPadding;

  @override
  State<AnalysisResultsView> createState() => _AnalysisResultsViewState();
}

class _AnalysisResultsViewState extends State<AnalysisResultsView>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  late final bool _showObservationsTab;

  @override
  void initState() {
    super.initState();

    // Check if observations tab should be shown (empty state handles no data)
    _showObservationsTab = locator.get<FeatureFlagService>().getBool(
      FeatureFlag.showFormObservationsTab,
    );

    // Initialize tab controller if showing tabs
    if (_showObservationsTab) {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.poseAnalysis == null) {
      return const Center(child: Text('No pose analysis data available'));
    }

    // Add 48px for GenericAppBar height since FormAnalysisRecordingScreen uses extendBodyBehindAppBar
    const double appBarHeight = 48.0;

    return Column(
      children: [
        SizedBox(height: widget.topViewPadding + appBarHeight),
        if (_showObservationsTab) _buildTabBar(),
        Expanded(
          child: FormAnalysisTabbedView(
            analysis: widget.poseAnalysis!,
            onBack: () {}, // No-op for fresh analysis
            topPadding: 8, // Small padding since tab bar is above
            poseAnalysisResponse: widget.poseAnalysis,
            tabController: _tabController,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: SenseiColors.gray.shade200, width: 1),
        ),
      ),
      child: TabBar(
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
      ),
    );
  }
}
