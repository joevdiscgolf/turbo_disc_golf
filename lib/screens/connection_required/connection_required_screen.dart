import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/backgrounds/animated_particle_background.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/app_phase/app_phase_controller.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

class ConnectionRequiredScreen extends StatefulWidget {
  const ConnectionRequiredScreen({super.key});

  static const String screenName = 'Connection Required';

  @override
  State<ConnectionRequiredScreen> createState() =>
      _ConnectionRequiredScreenState();
}

class _ConnectionRequiredScreenState extends State<ConnectionRequiredScreen> {
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
    );

    _trackScreenImpression();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _trackScreenImpression() {
    locator.get<LoggingService>().track(
      'Screen Impression',
      properties: {
        'screen_name': ConnectionRequiredScreen.screenName,
        'screen_class': 'ConnectionRequiredScreen',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
      child: Scaffold(
        body: Stack(
          children: [
            const AnimatedParticleBackground(),
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: MediaQuery.of(context).padding.top + 16,
                bottom: autoBottomPadding(context),
              ),
              child: _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIcon(),
                const SizedBox(height: 40),
                _buildTitle(context),
                const SizedBox(height: 16),
                _buildMessage(context),
              ],
            ),
          ),
        ),
        _buildRetryButton(context),
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SenseiColors.gray[100],
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(
        Icons.wifi_off_rounded,
        size: 56,
        color: SenseiColors.gray[500],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      'Connection required',
      style: TextStyle(
        color: SenseiColors.gray[700],
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage(BuildContext context) {
    return Text(
      'Please check your internet connection and try again.',
      style: TextStyle(
        color: SenseiColors.gray[600],
        fontSize: 16,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return PrimaryButton(
      width: double.infinity,
      height: 56,
      label: _isRetrying ? 'Connecting...' : 'Try again',
      labelColor: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 17,
      gradientBackground: const [Color(0xFF4ECDC4), Color(0xFF44CF9C)],
      disabled: _isRetrying,
      onPressed: _handleRetry,
    );
  }

  Future<void> _handleRetry() async {
    locator.get<LoggingService>().track(
      'Try Again Button Tapped',
      properties: {'screen_name': ConnectionRequiredScreen.screenName},
    );

    setState(() {
      _isRetrying = true;
    });

    try {
      await locator.get<AppPhaseController>().initialize();
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }
}
