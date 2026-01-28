import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:flutter/services.dart';

class GenericStatsScreen extends StatelessWidget {
  static const String screenName = 'Generic Stats';
  static const String routeName = '/generic-stats';

  const GenericStatsScreen({super.key, required this.statsWidget});

  final Widget statsWidget;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      locator.get<LoggingService>().track(
        'Screen Impression',
        properties: {
          'screen_name': GenericStatsScreen.screenName,
          'screen_class': 'GenericStatsScreen',
        },
      );
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
      child: Scaffold(
        appBar: GenericAppBar(
          topViewPadding: MediaQuery.of(context).viewPadding.top,
          title: 'Stats',
        ),

        body: statsWidget,
      ),
    );
  }
}
