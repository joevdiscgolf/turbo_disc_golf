import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';

class GenericStatsScreen extends StatelessWidget {
  const GenericStatsScreen({super.key, required this.statsWidget});

  final Widget statsWidget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GenericAppBar(
        topViewPadding: MediaQuery.of(context).viewPadding.top,
        title: 'Stats',
      ),

      body: statsWidget,
    );
  }
}
