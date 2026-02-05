import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/auth/components/landing_background.dart';
import 'package:turbo_disc_golf/services/app_phase/app_phase_controller.dart';
import 'package:turbo_disc_golf/services/firestore/fb_app_info_data_loader.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';
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
            Container(
              // height: MediaQuery.of(context).size.height,
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
                _buildAppIcon(),
                const SizedBox(height: 40),
                _buildTitle(context),
              ],
            ),
          ),
        ),
        _buildVersionInfo(context),
        const SizedBox(height: 12),
        _buildUpgradeButton(context),
      ],
    );
  }

  Widget _buildAppIcon() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
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
        height: 164,
        width: 164,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return const Text(
      'Update Required',
      style: TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    return Text(
      'Current: $_currentVersion → Required: $_requiredVersion',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.6),
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
        } else {
          locator.get<ToastService>().showError('Please try again.');
        }
      } catch (e) {
        debugPrint('[ForceUpgradeScreen] Error launching URL: $e');
      }
    }
  }
}
