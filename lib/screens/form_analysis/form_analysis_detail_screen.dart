import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/screens/form_analysis/components/history_analysis_view.dart';

class FormAnalysisDetailScreen extends StatelessWidget {
  const FormAnalysisDetailScreen({
    super.key,
    required this.analysis,
  });

  final FormAnalysisRecord analysis;

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
        ),
        body: HistoryAnalysisView(
          analysis: analysis,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
