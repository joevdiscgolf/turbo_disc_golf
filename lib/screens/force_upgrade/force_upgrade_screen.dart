import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/auth/components/landing_background.dart';
import 'package:turbo_disc_golf/services/app_phase/app_phase_controller.dart';
import 'package:turbo_disc_golf/services/firestore/fb_app_info_data_loader.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/utils/platform_helpers.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpgradeScreen extends StatefulWidget {
  const ForceUpgradeScreen({super.key});

  static const String screenName = 'Force Upgrade';

  @override
  State<ForceUpgradeScreen> createState() => _ForceUpgradeScreenState();
}

class _ForceUpgradeScreenState extends State<ForceUpgradeScreen> {
  String? _currentVersion;
  String? _requiredVersion;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
    );

    _loadVersionInfo();
    _trackScreenImpression();
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
    );
    super.dispose();
  }

  Future<void> _loadVersionInfo() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final AppPhaseController controller = locator.get<AppPhaseController>();
    final AppVersionInfo? versionInfo = controller.appVersionInfo;

    setState(() {
      _currentVersion = packageInfo.version;
      _requiredVersion = versionInfo?.minimumVersion;
    });
  }

  void _trackScreenImpression() {
    final AppPhaseController controller = locator.get<AppPhaseController>();
    final AppVersionInfo? versionInfo = controller.appVersionInfo;

    locator.get<LoggingService>().track(
      'Screen Impression',
      properties: {
        'screen_name': ForceUpgradeScreen.screenName,
        'screen_class': 'ForceUpgradeScreen',
        'current_version': _currentVersion ?? 'unknown',
        'required_version': versionInfo?.minimumVersion ?? 'unknown',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
      child: Scaffold(
        body: Stack(
          children: [
            const LandingBackground(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _buildContent(context),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        _buildAppIcon(),
        const SizedBox(height: 40),
        _buildTitle(context),
        const SizedBox(height: 16),
        _buildMessage(context),
        if (_currentVersion != null && _requiredVersion != null) ...[
          const SizedBox(height: 24),
          _buildVersionInfo(context),
        ],
        const SizedBox(height: 48),
        _buildUpgradeButton(context),
      ],
    );
  }

  Widget _buildAppIcon() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Image.asset(
        'assets/icon/app_icon_clear_bg.png',
        height: 100,
        width: 100,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return const Text(
      'Update Required',
      style: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage(BuildContext context) {
    final AppPhaseController controller = locator.get<AppPhaseController>();
    final AppVersionInfo? versionInfo = controller.appVersionInfo;

    final String message =
        versionInfo?.upgradeMessage ??
        'A new version of ScoreSensei is available. Please update to continue.';

    return Text(
      message,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.8),
        fontSize: 16,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    return Text(
      'Current: $_currentVersion → Required: $_requiredVersion',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 14,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildUpgradeButton(BuildContext context) {
    return PrimaryButton(
      width: double.infinity,
      height: 56,
      label: 'Update Now',
      labelColor: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 17,
      gradientBackground: const [Color(0xFF4ECDC4), Color(0xFF44CF9C)],
      onPressed: _handleUpgrade,
    );
  }

  Future<void> _handleUpgrade() async {
    final AppPhaseController controller = locator.get<AppPhaseController>();
    final AppVersionInfo? versionInfo = controller.appVersionInfo;

    final String? storeUrl = PlatformHelpers.getStoreUrl(
      versionInfo?.appStoreUrl,
      versionInfo?.playStoreUrl,
    );

    locator.get<LoggingService>().track(
      'Update Now Button Tapped',
      properties: {
        'screen_name': ForceUpgradeScreen.screenName,
        'platform': PlatformHelpers.isIOS ? 'iOS' : 'Android',
        'store_url_configured': storeUrl != null && storeUrl.isNotEmpty,
      },
    );

    if (storeUrl != null && storeUrl.isNotEmpty) {
      try {
        final Uri uri = Uri.parse(storeUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('[ForceUpgradeScreen] Error launching URL: $e');
      }
    }
  }
}
