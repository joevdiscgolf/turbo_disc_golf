import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/user_data/pdga_metadata.dart';
import 'package:turbo_disc_golf/screens/onboarding/feature_walkthrough/feature_walkthrough_screen.dart';
import 'package:turbo_disc_golf/services/auth/auth_database_service.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/pdga_constants.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

class OnboardingScreen extends StatefulWidget {
  static const String routeName = '/onboarding';
  static const String screenName = 'Onboarding';

  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final AuthService _authService = locator.get<AuthService>();
  final AuthDatabaseService _authDatabaseService = locator
      .get<AuthDatabaseService>();
  late final LoggingServiceBase _logger;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _pdgaRatingController = TextEditingController();

  Timer? _usernameDebounceTimer;

  String? _username;
  int? _pdgaRating;
  String? _selectedDivision;

  UsernameStatus _usernameStatus = UsernameStatus.empty;

  bool _isSubmitting = false;
  String? _errorText;

  static final RegExp _usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': OnboardingScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('OnboardingScreen');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _pdgaRatingController.dispose();
    _usernameDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: GenericAppBar(
        topViewPadding: MediaQuery.of(context).viewPadding.top,
        title: 'Complete Your Profile',
        hasBackButton: true,
        onBackPressed: () async {
          await _authService.logout();
        },
      ),
      backgroundColor: TurbColors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 16,
            right: 16,
            bottom: autoBottomPadding(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form fields
              _buildUsernameLabel(),
              const SizedBox(height: 6),
              _buildUsernameField(),
              const SizedBox(height: 16),

              _buildSectionLabel('PDGA Rating (optional)'),
              const SizedBox(height: 6),
              _buildPdgaRatingField(),
              const SizedBox(height: 16),

              _buildSectionLabel('Division (optional)'),
              const SizedBox(height: 6),
              _buildDivisionSelector(),

              // Error text if any
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _errorText!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const Spacer(),

              // Bottom buttons
              if (kDebugMode) ...[
                _buildDebugSkipButton(),
                const SizedBox(height: 4),
                _buildSkipButton(),
                const SizedBox(height: 12),
              ],

              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameLabel() {
    return Row(
      children: [
        Text(
          'Username',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: TurbColors.gray[700],
          ),
        ),
        Text(
          ' *',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: TurbColors.gray[700],
          ),
        ),
        if (_usernameStatus == UsernameStatus.taken) ...[
          const SizedBox(width: 8),
          Text(
            'taken',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: TurbColors.gray[700],
      ),
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _usernameController,
          autocorrect: false,
          maxLength: 20,
          maxLines: 1,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
          ],
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Choose a username',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: true,
            fillColor: TurbColors.gray[50],
            hintStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: TurbColors.gray[200]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            prefixIcon: const Icon(
              FlutterRemix.user_line,
              color: Colors.grey,
              size: 18,
            ),
            suffixIcon: _buildUsernameSuffixIcon(),
            counter: const Offstage(),
          ),
          onChanged: _onUsernameChanged,
        ),
        const SizedBox(height: 4),
        Text(
          'Letters, numbers, and underscores only. Min 3 characters.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: TurbColors.gray[500]),
        ),
      ],
    );
  }

  Widget? _buildUsernameSuffixIcon() {
    return switch (_usernameStatus) {
      UsernameStatus.empty => null,
      UsernameStatus.tooShort => null,
      UsernameStatus.invalid => const Icon(
        FlutterRemix.close_circle_fill,
        color: Colors.red,
        size: 20,
      ),
      UsernameStatus.checking => const SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      UsernameStatus.available => const Icon(
        FlutterRemix.checkbox_circle_fill,
        color: Colors.green,
        size: 20,
      ),
      UsernameStatus.taken => const Icon(
        FlutterRemix.close_circle_fill,
        color: Colors.red,
        size: 20,
      ),
    };
  }

  Widget _buildPdgaRatingField() {
    return TextFormField(
      controller: _pdgaRatingController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 4,
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Enter your rating',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: TurbColors.gray[50],
        hintStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
          color: Colors.grey[400],
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: TurbColors.gray[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        prefixIcon: const Icon(
          FlutterRemix.bar_chart_2_line,
          color: Colors.grey,
          size: 18,
        ),
        counter: const Offstage(),
      ),
      onChanged: (value) {
        setState(() {
          _pdgaRating = int.tryParse(value);
        });
      },
    );
  }

  Widget _buildDivisionSelector() {
    final bool hasSelection = _selectedDivision != null;

    return GestureDetector(
      onTap: _showDivisionPanel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: TurbColors.gray[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TurbColors.gray[200]!, width: 1),
        ),
        child: Row(
          children: [
            const Icon(FlutterRemix.trophy_line, color: Colors.grey, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasSelection ? _selectedDivision! : 'Select Division',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: hasSelection ? Colors.black : Colors.grey[400],
                  fontSize: 16,
                  fontWeight: hasSelection ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
            Icon(
              FlutterRemix.arrow_down_s_line,
              color: TurbColors.gray[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDivisionPanel() async {
    // Dismiss keyboard before showing panel
    FocusManager.instance.primaryFocus?.unfocus();

    final String? result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) =>
          _DivisionSelectionPanel(selectedDivision: _selectedDivision),
    );

    // Dismiss keyboard again after panel closes to prevent refocus
    if (mounted) {
      FocusManager.instance.primaryFocus?.unfocus();
    }

    if (result != null && mounted) {
      setState(() {
        _selectedDivision = result;
      });
    }
  }

  Widget _buildSubmitButton() {
    return PrimaryButton(
      width: double.infinity,
      height: 56,
      label: 'Continue',
      backgroundColor: Colors.blue,
      loading: _isSubmitting,
      disabled: !_isFormValid(),
      onPressed: _onSubmit,
    );
  }

  Widget _buildSkipButton() {
    return Center(
      child: TextButton(
        onPressed: _onSkipToWalkthrough,
        child: Text(
          'Skip for now',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildDebugSkipButton() {
    return Center(
      child: TextButton(
        onPressed: _onSkipOnboarding,
        child: Text(
          '[DEBUG] Skip Onboarding',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.orange,
            decoration: TextDecoration.underline,
            decorationColor: Colors.orange,
          ),
        ),
      ),
    );
  }

  void _onSkipToWalkthrough() {
    _logger.track('Skip For Now Button Tapped');
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const FeatureWalkthroughScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _onUsernameChanged(String value) {
    _usernameDebounceTimer?.cancel();

    final String trimmed = value.trim();
    setState(() {
      _username = trimmed;
      _errorText = null;

      if (trimmed.isEmpty) {
        _usernameStatus = UsernameStatus.empty;
      } else if (trimmed.length < 3) {
        _usernameStatus = UsernameStatus.tooShort;
      } else if (!_usernameRegex.hasMatch(trimmed)) {
        _usernameStatus = UsernameStatus.invalid;
      } else {
        _usernameStatus = UsernameStatus.checking;
      }
    });

    if (_usernameStatus == UsernameStatus.checking) {
      _usernameDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        _checkUsernameAvailability(trimmed);
      });
    }
  }

  Future<void> _checkUsernameAvailability(String username) async {
    final bool isAvailable = await _authDatabaseService.usernameIsAvailable(
      username,
    );

    if (!mounted) return;

    if (_username == username) {
      setState(() {
        _usernameStatus = isAvailable
            ? UsernameStatus.available
            : UsernameStatus.taken;
      });
    }
  }

  bool _isFormValid() {
    return _usernameStatus == UsernameStatus.available && !_isSubmitting;
  }

  Future<void> _onSubmit() async {
    _logger.track('Create My Card Button Tapped');

    if (!_isFormValid()) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    HapticFeedback.lightImpact();

    PDGAMetadata? pdgaMetadata;
    if (_pdgaRating != null || _selectedDivision != null) {
      pdgaMetadata = PDGAMetadata(
        pdgaNum: null,
        pdgaRating: _pdgaRating,
        division: _selectedDivision,
      );
    }

    final bool success = await _authService.setupNewUser(
      _username!,
      pdgaMetadata: pdgaMetadata,
    );

    if (!mounted) return;

    if (success) {
      // Navigate to feature walkthrough
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const FeatureWalkthroughScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      setState(() {
        _isSubmitting = false;
        _errorText = 'Failed to complete profile. Please try again.';
      });
    }
  }

  Future<void> _onSkipOnboarding() async {
    _logger.track('Skip Onboarding Button Tapped');
    HapticFeedback.lightImpact();
    await _authService.markUserOnboarded();
  }
}

enum UsernameStatus { empty, tooShort, invalid, checking, available, taken }

class _DivisionSelectionPanel extends StatefulWidget {
  const _DivisionSelectionPanel({this.selectedDivision});

  final String? selectedDivision;

  @override
  State<_DivisionSelectionPanel> createState() =>
      _DivisionSelectionPanelState();
}

class _DivisionSelectionPanelState extends State<_DivisionSelectionPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredDivisions {
    if (_searchQuery.isEmpty) return PDGADivisions.all;

    final String query = _searchQuery.toLowerCase();
    return PDGADivisions.all.where((division) {
      final String displayName = PDGADivisions.getDisplayName(
        division,
      ).toLowerCase();
      return division.toLowerCase().contains(query) ||
          displayName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        final List<String> divisions = _filteredDivisions;

        return Column(
          children: [
            PanelHeader(
              title: 'Select Division',
              onClose: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search divisions...',
                  hintStyle: TextStyle(color: TurbColors.gray[400]),
                  prefixIcon: Icon(
                    FlutterRemix.search_line,
                    color: TurbColors.gray[400],
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Icon(
                            FlutterRemix.close_circle_fill,
                            color: TurbColors.gray[400],
                            size: 20,
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: TurbColors.gray[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: TurbColors.gray[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: TurbColors.gray[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Expanded(
              child: divisions.isEmpty
                  ? Center(
                      child: Text(
                        'No divisions found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: TurbColors.gray[500],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 64),
                      itemCount: divisions.length,
                      itemBuilder: (context, index) {
                        final String division = divisions[index];
                        final bool isSelected =
                            division == widget.selectedDivision;

                        return _DivisionListItem(
                          division: division,
                          isSelected: isSelected,
                          onTap: () => Navigator.of(context).pop(division),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _DivisionListItem extends StatelessWidget {
  const _DivisionListItem({
    required this.division,
    required this.isSelected,
    required this.onTap,
  });

  final String division;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? flattenedOverWhite(Colors.blue, 0.1)
              : TurbColors.gray[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : TurbColors.gray[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    division,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.blue : TurbColors.gray[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getFullName(division),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TurbColors.gray[400],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                FlutterRemix.checkbox_circle_fill,
                color: Colors.blue,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  String _getFullName(String division) {
    final String displayName = PDGADivisions.getDisplayName(division);
    // Remove the division code prefix (e.g., "MPO – " from "MPO – Mixed Professional Open")
    final int dashIndex = displayName.indexOf('–');
    if (dashIndex != -1 && dashIndex + 2 < displayName.length) {
      return displayName.substring(dashIndex + 2);
    }
    return displayName;
  }
}
