import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GenericAppBar(
        topViewPadding: MediaQuery.of(context).viewPadding.top,
        title: 'Onboarding',
      ),
      backgroundColor: TurbColors.white,
    );
  }
}
