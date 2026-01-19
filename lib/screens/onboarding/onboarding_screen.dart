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
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/models/data/user_data/pdga_player_info.dart';
import 'package:turbo_disc_golf/services/auth/auth_database_service.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/web_scraper_service.dart';
import 'package:turbo_disc_golf/screens/onboarding/feature_walkthrough/feature_walkthrough_screen.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/pdga_constants.dart';

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
  final WebScraperService _webScraperService = locator.get<WebScraperService>();
  late final LoggingServiceBase _logger;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _pdgaNumController = TextEditingController();
  final TextEditingController _pdgaRatingController = TextEditingController();

  Timer? _usernameDebounceTimer;
  Timer? _pdgaDebounceTimer;

  String? _username;
  int? _pdgaNum;
  int? _pdgaRating;
  String? _selectedDivision;

  UsernameStatus _usernameStatus = UsernameStatus.empty;
  PDGAFetchStatus _pdgaFetchStatus = PDGAFetchStatus.idle;
  PDGAPlayerInfo? _fetchedPlayerInfo;

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
    _pdgaNumController.dispose();
    _pdgaRatingController.dispose();
    _usernameDebounceTimer?.cancel();
    _pdgaDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: 24,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewPadding.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel('Username *'),
              const SizedBox(height: 8),
              _buildUsernameField(),
              const SizedBox(height: 24),
              _buildSectionLabel('PDGA Information (Optional)'),
              const SizedBox(height: 8),
              _buildPdgaNumField(),
              if (_fetchedPlayerInfo != null) ...[
                const SizedBox(height: 12),
                _buildPlayerInfoCard(),
              ],
              // Only show rating field if no player info found
              if (_fetchedPlayerInfo == null) ...[
                const SizedBox(height: 12),
                _buildPdgaRatingField(),
              ],
              const SizedBox(height: 12),
              _buildDivisionSelector(),
              if (_errorText != null) ...[
                const SizedBox(height: 16),
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
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 16),
              _buildSkipToWalkthroughButton(),
              if (kDebugMode) ...[
                const SizedBox(height: 8),
                _buildSkipButton(),
              ],
            ],
          ),
        ),
      ),
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

  Widget _buildPdgaNumField() {
    return TextFormField(
      controller: _pdgaNumController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 10,
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'PDGA Number',
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
          FlutterRemix.hashtag,
          color: Colors.grey,
          size: 18,
        ),
        suffixIcon: _buildPdgaSuffixIcon(),
        counter: const Offstage(),
      ),
      onChanged: _onPdgaNumChanged,
    );
  }

  Widget? _buildPdgaSuffixIcon() {
    return switch (_pdgaFetchStatus) {
      PDGAFetchStatus.idle => null,
      PDGAFetchStatus.fetching => const SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      PDGAFetchStatus.success => const Icon(
        FlutterRemix.checkbox_circle_fill,
        color: Colors.green,
        size: 20,
      ),
      PDGAFetchStatus.notFound => const Icon(
        FlutterRemix.close_circle_fill,
        color: Colors.orange,
        size: 20,
      ),
      PDGAFetchStatus.error => const Icon(
        FlutterRemix.error_warning_fill,
        color: Colors.red,
        size: 20,
      ),
    };
  }

  Widget _buildPlayerInfoCard() {
    final PDGAPlayerInfo info = _fetchedPlayerInfo!;
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
          // Header with name and close button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name ?? 'PDGA #${info.pdgaNum}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: TurbColors.gray[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PDGA #${info.pdgaNum}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TurbColors.gray[500],
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _clearPlayerInfo,
                child: Icon(
                  FlutterRemix.close_line,
                  color: TurbColors.gray[400],
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatsGrid(info),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(PDGAPlayerInfo info) {
    final List<_StatData> stats = [
      if (info.rating != null) _StatData('Rating', info.rating.toString()),
      if (info.location != null) _StatData('Location', info.location!),
      if (info.careerWins != null)
        _StatData('Wins', info.careerWins.toString()),
      if (info.careerEvents != null)
        _StatData('Events', info.careerEvents.toString()),
      if (info.careerEarnings != null)
        _StatData('Earnings', _formatCurrency(info.careerEarnings!)),
      if (info.memberSince != null)
        _StatData('Member Since', info.memberSince!),
      if (info.classification != null) _StatData('Class', info.classification!),
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
              Expanded(child: _buildStatItem(stats[i].label, stats[i].value)),
              if (hasSecond)
                Expanded(
                  child: _buildStatItem(stats[i + 1].label, stats[i + 1].value),
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

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: TurbColors.gray[400],
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
            color: TurbColors.gray[700],
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '\$${amount.toStringAsFixed(0)}';
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
        hintText: 'PDGA Rating',
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
                hasSelection
                    ? PDGADivisions.getDisplayName(_selectedDivision!)
                    : 'Select Division',
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
      label: 'Complete Profile',
      backgroundColor: Colors.blue,
      loading: _isSubmitting,
      disabled: !_isFormValid(),
      onPressed: _onSubmit,
    );
  }

  Widget _buildSkipButton() {
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

  Widget _buildSkipToWalkthroughButton() {
    return Center(
      child: TextButton(
        onPressed: _onSkipToWalkthrough,
        child: Text(
          'Skip to Walkthrough',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  void _onSkipToWalkthrough() {
    _logger.track('Skip To Walkthrough Button Tapped');
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

  void _onPdgaNumChanged(String value) {
    _pdgaDebounceTimer?.cancel();

    final int? pdgaNum = int.tryParse(value);
    setState(() {
      _pdgaNum = pdgaNum;
      _fetchedPlayerInfo = null;
      _pdgaFetchStatus = PDGAFetchStatus.idle;
    });

    // Fetch after 500ms of no typing if a valid number is entered
    if (pdgaNum != null) {
      setState(() {
        _pdgaFetchStatus = PDGAFetchStatus.fetching;
      });

      _pdgaDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        _fetchPdgaPlayerInfo(pdgaNum);
      });
    }
  }

  Future<void> _fetchPdgaPlayerInfo(int pdgaNum) async {
    final PDGAPlayerInfo? info = await _webScraperService.getPDGAPlayerInfo(
      pdgaNum,
    );

    if (!mounted) return;

    if (_pdgaNum == pdgaNum) {
      setState(() {
        if (info != null && info.name != null) {
          _fetchedPlayerInfo = info;
          _pdgaFetchStatus = PDGAFetchStatus.success;

          // Auto-populate rating if fetched
          if (info.rating != null) {
            _pdgaRating = info.rating;
            _pdgaRatingController.text = info.rating.toString();
          }
        } else {
          _fetchedPlayerInfo = null;
          _pdgaFetchStatus = PDGAFetchStatus.notFound;
        }
      });
    }
  }

  void _clearPlayerInfo() {
    setState(() {
      _fetchedPlayerInfo = null;
      _pdgaFetchStatus = PDGAFetchStatus.idle;
    });
  }

  bool _isFormValid() {
    return _usernameStatus == UsernameStatus.available && !_isSubmitting;
  }

  Future<void> _onSubmit() async {
    _logger.track('Complete Profile Button Tapped');

    if (!_isFormValid()) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    HapticFeedback.lightImpact();

    // Use fetched rating if available, otherwise fall back to manual entry
    final int? rating = _fetchedPlayerInfo?.rating ?? _pdgaRating;

    PDGAMetadata? pdgaMetadata;
    if (_pdgaNum != null || rating != null || _selectedDivision != null) {
      pdgaMetadata = PDGAMetadata(
        pdgaNum: _pdgaNum,
        pdgaRating: rating,
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

enum PDGAFetchStatus { idle, fetching, success, notFound, error }

class _StatData {
  const _StatData(this.label, this.value);
  final String label;
  final String value;
}

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
