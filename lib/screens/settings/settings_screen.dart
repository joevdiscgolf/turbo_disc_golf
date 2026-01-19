import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/user_data/pdga_metadata.dart';
import 'package:turbo_disc_golf/models/data/user_data/user_data.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/state/user_data_cubit.dart';
import 'package:turbo_disc_golf/state/user_data_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/pdga_constants.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _useMeters = false;

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
                      if (showDistancePreferences) ...[
                        _buildSectionHeader('Preferences'),
                        _buildSettingsCard([
                          _buildUnitToggleRow(),
                        ]),
                      ],
                      if (currentUser?.pdgaMetadata != null) ...[
                        const SizedBox(height: 32),
                        _buildSectionHeader('PDGA Information'),
                        _buildPdgaInfoSection(currentUser!.pdgaMetadata!),
                      ],
                      const SizedBox(height: 32),
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
      child: Column(
        children: children,
      ),
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
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
                child: const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 20,
                ),
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
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdgaInfoSection(PDGAMetadata pdgaData) {
    final Color subtleGreen = flattenedOverWhite(Colors.green, 0.08);
    final Color borderGreen = flattenedOverWhite(Colors.green, 0.25);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [subtleGreen, flattenedOverWhite(Colors.green, 0.04)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPdgaStatsGrid(pdgaData),
        ],
      ),
    );
  }

  Widget _buildPdgaStatsGrid(PDGAMetadata pdgaData) {
    final List<_PdgaStat> stats = [
      _PdgaStat(
        'PDGA Number',
        pdgaData.pdgaNum != null ? '#${pdgaData.pdgaNum}' : 'N/A',
      ),
      _PdgaStat(
        'PDGA Rating',
        pdgaData.pdgaRating != null ? '${pdgaData.pdgaRating}' : 'N/A',
      ),
      _PdgaStat(
        'Division',
        pdgaData.division != null
            ? PDGADivisions.getDisplayName(pdgaData.division!)
            : 'N/A',
      ),
    ];

    // Build rows of 2 items each
    final List<Widget> rows = [];
    for (int i = 0; i < stats.length; i += 2) {
      final bool hasSecond = i + 1 < stats.length;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < stats.length ? 12 : 0),
          child: Row(
            children: [
              Expanded(
                child: _buildPdgaStatItem(stats[i].label, stats[i].value),
              ),
              if (hasSecond)
                Expanded(
                  child: _buildPdgaStatItem(stats[i + 1].label, stats[i + 1].value),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildPdgaStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade400,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
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
              top: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
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
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Log out'),
        message: const Text('Are you sure you want to log out?'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              locator.get<AuthService>().logout();
            },
            child: const Text('Log out'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
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
              Navigator.of(context).pop();
              _showFinalDeleteConfirmation();
            },
            child: const Text('Delete Account'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showFinalDeleteConfirmation() {
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
              Navigator.of(context).pop();
              await _deleteUserAccount();
            },
            child: const Text('Yes, Delete Everything'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
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

class _PdgaStat {
  const _PdgaStat(this.label, this.value);
  final String label;
  final String value;
}
