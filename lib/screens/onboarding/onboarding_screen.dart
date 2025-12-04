import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GenericAppBar(
        topViewPadding: MediaQuery.of(context).viewPadding.top,
        title: 'Onboarding',
        hasBackButton: true,
        onBackPressed: () async {
          await locator.get<AuthService>().logout();
        },
      ),
      backgroundColor: TurbColors.white,
      body: Center(
        child: PrimaryButton(
          width: double.infinity,
          label: 'Complete onboarding',
          onPressed: () async {
            await locator.get<AuthService>().markUserOnboarded();
          },
        ),
      ),
    );
  }
}
