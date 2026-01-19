import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/user_data/pdga_metadata.dart';
import 'package:turbo_disc_golf/models/data/user_data/user_data.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/state/user_data_cubit.dart';
import 'package:turbo_disc_golf/state/user_data_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/pdga_constants.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';

class SettingsScreen extends StatefulWidget {
  static const String routeName = '/settings';
  static const String screenName = 'Settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final LoggingServiceBase _logger;
  bool _useMeters = false;

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': SettingsScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('SettingsScreen');
  }

  @override
  Widget build(BuildContext context) {
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
          topViewPadding: MediaQuery.of(context).viewPadding.top,
          title: 'Settings',
        ),
        body: BlocBuilder<UserDataCubit, UserDataState>(
          builder: (context, userDataState) {
            final TurboUser? currentUser = userDataState is UserDataLoaded
                ? userDataState.user
                : null;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (currentUser != null) ...[
                        _buildProfileHeader(currentUser),
                        const SizedBox(height: 32),
                      ],
                      if (locator
                          .get<FeatureFlagService>()
                          .showDistancePreferences) ...[
                        _buildSectionHeader('Preferences'),
                        _buildSettingsCard([_buildUnitToggleRow()]),
                        const SizedBox(height: 32),
                      ],
                      _buildSectionHeader('Account'),
                      _buildSettingsCard([
                        _buildLogoutRow(),
                        _buildDeleteAccountRow(),
                      ]),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildUnitToggleRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF64B5F6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.straighten,
              color: Color(0xFF1565C0),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Distance units',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          _buildUnitToggle(),
        ],
      ),
    );
  }

  Widget _buildUnitToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption('Feet', !_useMeters),
          _buildToggleOption('Meters', _useMeters),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        _logger.track(
          'Distance Unit Toggle Tapped',
          properties: {'selected_unit': label},
        );
        HapticFeedback.lightImpact();
        setState(() {
          _useMeters = label == 'Meters';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutRow() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _logger.track('Log Out Button Tapped');
          HapticFeedback.lightImpact();
          _showLogoutConfirmation();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Log out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(TurboUser user) {
    final PDGAMetadata? pdgaData = user.pdgaMetadata;
    final bool hasRating = pdgaData?.pdgaRating != null;
    final bool hasDivision = pdgaData?.division != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Username headline
          Text(
            '@${user.username}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: SenseiColors.gray[800],
            ),
          ),
          if (hasRating || hasDivision) ...[
            const SizedBox(height: 16),
            // Stats rows
            if (hasRating)
              _buildProfileStatRow(
                'PDGA Rating',
                pdgaData!.pdgaRating.toString(),
                Icons.star_outline,
              ),
            if (hasRating && hasDivision) const SizedBox(height: 8),
            if (hasDivision)
              _buildProfileStatRow(
                'Division',
                PDGADivisions.getDisplayName(pdgaData!.division!),
                Icons.emoji_events_outlined,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: SenseiColors.gray[400]),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: SenseiColors.gray[500]),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: SenseiColors.gray[700],
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteAccountRow() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _logger.track('Delete Account Button Tapped');
          HapticFeedback.lightImpact();
          _showDeleteAccountConfirmation();
        },
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Delete Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    _logger.track(
      'Modal Opened',
      properties: {'modal_type': 'alert', 'modal_name': 'Logout Confirmation'},
    );

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Log out'),
        message: const Text('Are you sure you want to log out?'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              _logger.track('Logout Confirmed');
              Navigator.of(context).pop();
              locator.get<AuthService>().logout();
            },
            child: const Text('Log out'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            _logger.track('Logout Cancelled');
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    _logger.track(
      'Modal Opened',
      properties: {
        'modal_type': 'alert',
        'modal_name': 'Delete Account Confirmation',
      },
    );

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Delete Account'),
        message: const Text(
          'This will permanently delete your account and all data. This action cannot be undone.',
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              _logger.track('Delete Account First Confirmation');
              Navigator.of(context).pop();
              _showFinalDeleteConfirmation();
            },
            child: const Text('Delete Account'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            _logger.track('Delete Account Cancelled');
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showFinalDeleteConfirmation() {
    _logger.track(
      'Modal Opened',
      properties: {
        'modal_type': 'alert',
        'modal_name': 'Delete Account Final Confirmation',
      },
    );

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Are you absolutely sure?'),
        message: const Text(
          'Your account, rounds, and all data will be permanently deleted. This cannot be undone.',
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              _logger.track('Delete Account Final Confirmed');
              Navigator.of(context).pop();
              await _deleteUserAccount();
            },
            child: const Text('Yes, Delete Everything'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            _logger.track('Delete Account Final Cancelled');
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _deleteUserAccount() async {
    final AuthService authService = locator.get<AuthService>();
    HapticFeedback.mediumImpact();

    final bool success = await authService.deleteCurrentUser();

    if (!mounted) return;

    if (!success) {
      // Show error if deletion failed
      showCupertinoModalPopup<void>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('Error'),
          message: const Text(
            'Failed to delete account. Please try again later.',
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    // If success, AuthService automatically handles logout and navigation
  }
}
