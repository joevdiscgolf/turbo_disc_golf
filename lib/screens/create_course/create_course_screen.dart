import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/map/location_picker_sheet.dart';
import 'package:turbo_disc_golf/components/map/mini_map_preview.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/country.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/screens/create_course/components/country_picker_panel.dart';
import 'package:turbo_disc_golf/screens/create_course/components/holes_section.dart';
import 'package:turbo_disc_golf/screens/create_course/components/layout_info_section.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';
import 'package:turbo_disc_golf/state/create_course_cubit.dart';
import 'package:turbo_disc_golf/state/create_course_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/country_constants.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';

/// Bottom sheet / modal for creating a course + default layout
class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({
    super.key,
    required this.onCourseCreated,
    required this.topViewPadding,
    required this.bottomViewPadding,
  });

  static const String screenName = 'Create Course';
  static const String routeName = '/create_course';

  final void Function(Course course) onCourseCreated;
  final double topViewPadding;
  final double bottomViewPadding;

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  late final CreateCourseCubit _createCourseCubit;
  late final LoggingServiceBase _logger;

  // Text controllers for location fields
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;

  @override
  void initState() {
    super.initState();
    _createCourseCubit = BlocProvider.of<CreateCourseCubit>(context);

    // Initialize text controllers
    final CreateCourseState initialState = _createCourseCubit.state;
    _cityController = TextEditingController(text: initialState.city ?? '');
    _stateController = TextEditingController(text: initialState.state ?? '');

    // Create scoped logger with base properties
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': CreateCourseScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('CreateCourseSheet');
  }

  @override
  void dispose() {
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final CreateCourseState state = _createCourseCubit.state;
    final bool hasUnsavedChanges =
        state.courseName.isNotEmpty ||
        state.layoutName.isNotEmpty ||
        state.hasLocation ||
        state.city != null;

    if (!hasUnsavedChanges) return true;

    final bool? shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: BlocListener<CreateCourseCubit, CreateCourseState>(
        listenWhen: (prev, curr) =>
            prev.city != curr.city || prev.state != curr.state,
        listener: (context, state) {
          // Sync controllers when state changes from geocoding
          if (_cityController.text != (state.city ?? '')) {
            _cityController.text = state.city ?? '';
          }
          if (_stateController.text != (state.state ?? '')) {
            _stateController.text = state.state ?? '';
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          resizeToAvoidBottomInset: false,
          appBar: GenericAppBar(
            topViewPadding: widget.topViewPadding,
            title: 'Create course',
            rightWidget: IconButton(
              icon: const Icon(
                Icons.close,
                size: PanelConstants.closeButtonIconSize,
              ),
              onPressed: () async {
                _logger.track('Close Button Tapped');
                HapticFeedback.lightImpact();
                final bool shouldPop = await _onWillPop();
                if (shouldPop && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            hasBackButton: false,
          ),
          body: BlocBuilder<CreateCourseCubit, CreateCourseState>(
            builder: (context, state) {
              return GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Column(
                  children: [
                    // Completeness indicator
                    _buildCompletenessIndicator(state),
                    // Scrollable content
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(top: 20, bottom: 48),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCourseSection(context, state),
                                Divider(
                                  height: 32,
                                  color: SenseiColors.gray.shade100,
                                  thickness: 1,
                                ),
                                LayoutInfoSection(
                                  headerTitle: 'Default Layout',
                                  layoutName: state.layoutName,
                                  numberOfHoles: state.numberOfHoles,
                                  isParsingImage: state.isParsingImage,
                                  parseError: state.parseError,
                                  onLayoutNameChanged:
                                      _createCourseCubit.updateLayoutName,
                                  onHoleCountChanged: (int newCount) =>
                                      _handleHoleCountChange(state, newCount),
                                  onParseImage: () async {
                                    _logger.track(
                                      'Parse Layout Image Button Tapped',
                                    );
                                    HapticFeedback.lightImpact();
                                    FocusScope.of(context).unfocus();
                                    await Future.delayed(
                                      const Duration(milliseconds: 300),
                                    );
                                    if (context.mounted) {
                                      _createCourseCubit.pickAndParseImage(
                                        context,
                                      );
                                    }
                                  },
                                ),
                                Divider(
                                  height: 32,
                                  color: SenseiColors.gray.shade100,
                                  thickness: 1,
                                ),
                                HolesSection(
                                  holes: state.holes,
                                  onSnapshotBeforeApply:
                                      _createCourseCubit.snapshotHolesForUndo,
                                  onUndoQuickFill:
                                      _createCourseCubit.undoQuickFill,
                                  onApplyDefaults: _createCourseCubit
                                      .applyDefaultsToAllHoles,
                                  onHoleParChanged:
                                      _createCourseCubit.updateHolePar,
                                  onHoleFeetChanged:
                                      _createCourseCubit.updateHoleFeet,
                                  onHoleTypeChanged:
                                      _createCourseCubit.updateHoleType,
                                  onHoleShapeChanged:
                                      _createCourseCubit.updateHoleShape,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Fixed bottom footer
                    _buildFooter(context, state),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCompletenessIndicator(CreateCourseState state) {
    final int percentage = state.completionPercentage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 3,
      child: LinearProgressIndicator(
        value: percentage / 100,
        backgroundColor: SenseiColors.gray.shade200,
        valueColor: AlwaysStoppedAnimation<Color>(
          percentage == 100 ? Colors.green : const Color(0xFF137e66),
        ),
      ),
    );
  }

  Future<void> _handleHoleCountChange(
    CreateCourseState state,
    int newCount,
  ) async {
    if (newCount < state.numberOfHoles) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reduce hole count?'),
          content: Text(
            'Changing to $newCount holes will remove data for holes ${newCount + 1}-${state.numberOfHoles}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    _createCourseCubit.updateHoleCount(newCount);
  }

  // ─────────────────────────────────────────────
  Widget _buildCourseSection(BuildContext context, CreateCourseState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Course Info', Icons.location_on, Colors.blue),
        const SizedBox(height: 12),
        TextField(
          onChanged: _createCourseCubit.updateCourseName,
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                text: 'Course name ',
                style: TextStyle(
                  color: SenseiColors.gray.shade600,
                  fontSize: 16,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Map location picker (controlled by feature flag)
        if (locator.get<FeatureFlagService>().showMapLocationPicker) ...[
          _buildLocationPickerSection(context, state),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cityController,
                onChanged: _createCourseCubit.updateCity,
                decoration: InputDecoration(
                  labelText: 'City',
                  suffixIcon: state.isGeocodingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _stateController,
                onChanged: _createCourseCubit.updateState,
                decoration: const InputDecoration(labelText: 'State'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCountrySelector(context, state),
      ],
    );
  }

  String? _getCountryDisplayText(CreateCourseState state) {
    if (state.countryCode == null || state.countryCode!.isEmpty) return null;

    final Country? country = allCountries
        .where((c) => c.code == state.countryCode)
        .firstOrNull;

    if (country == null) return state.country; // Fallback for legacy data

    return '${country.flagEmoji} ${country.name}';
  }

  void _openCountryPicker(BuildContext context, CreateCourseState state) {
    _logger.track(
      'Select Country Button Tapped',
      properties: {'has_existing_country': state.countryCode != null},
    );

    _logger.track(
      'Modal Opened',
      properties: {
        'modal_type': 'bottom_sheet',
        'modal_name': 'Country Picker',
      },
    );

    HapticFeedback.lightImpact();

    CountryPickerPanel.show(
      context,
      selectedCountryCode: state.countryCode,
      onCountrySelected: (Country country) {
        _logger.track(
          'Country Selected',
          properties: {
            'country_code': country.code,
            'country_name': country.name,
          },
        );
        _createCourseCubit.updateCountrySelection(country.code, country.name);
      },
    );
  }

  Widget _buildCountrySelector(BuildContext context, CreateCourseState state) {
    final String? displayText = _getCountryDisplayText(state);
    final bool hasCountry = displayText != null;

    return GestureDetector(
      onTap: hasCountry ? null : () => _openCountryPicker(context, state),
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: SenseiColors.gray.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hasCountry)
              Align(
                alignment: Alignment.center,
                child: Text(
                  displayText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    height: 1,
                  ),
                ),
              )
            else ...[
              Icon(
                Icons.public_outlined,
                color: SenseiColors.gray.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Select country',
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: SenseiColors.gray.shade600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: SenseiColors.gray.shade400),
            ],
            if (hasCountry) ...[
              const Spacer(),
              GestureDetector(
                onTap: () {
                  _logger.track(
                    'Clear Country Button Tapped',
                    properties: {'previous_country_code': state.countryCode},
                  );
                  HapticFeedback.lightImpact();
                  _createCourseCubit.updateCountrySelection('', '');
                },
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: SenseiColors.gray.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPickerSection(
    BuildContext context,
    CreateCourseState state,
  ) {
    // Show mini map if location is selected
    if (state.hasLocation) {
      return MiniMapPreview(
        latitude: state.latitude!,
        longitude: state.longitude!,
        isLoading: state.isGeocodingLocation,
        onTap: () => _openLocationPicker(context, state),
        onClear: _createCourseCubit.clearLocation,
      );
    }

    // Show "Select location" button
    return GestureDetector(
      onTap: () => _openLocationPicker(context, state),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SenseiColors.gray.shade50,
          border: Border.all(color: SenseiColors.gray.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.map_outlined,
              color: SenseiColors.gray.shade600,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select location on map',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: SenseiColors.gray.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pin your course for easy discovery',
                    style: TextStyle(
                      fontSize: 12,
                      color: SenseiColors.gray.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: SenseiColors.gray.shade400),
          ],
        ),
      ),
    );
  }

  void _openLocationPicker(BuildContext context, CreateCourseState state) {
    _logger.track(
      'Select Location Button Tapped',
      properties: {'has_existing_location': state.hasLocation},
    );

    _logger.track(
      'Modal Opened',
      properties: {
        'modal_type': 'full_screen_modal',
        'modal_name': 'Location Picker',
      },
    );

    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocationPickerSheet(
          topViewPadding: widget.topViewPadding,
          initialLatitude: state.latitude,
          initialLongitude: state.longitude,
          onLocationSelected: (double lat, double lng) {
            _logger.track('Location Selected On Map');
            _createCourseCubit.updateLocation(lat, lng);
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  Widget _buildFooter(BuildContext context, CreateCourseState state) {
    final bool canSave = state.courseName.trim().isNotEmpty && !state.isSaving;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: PrimaryButton(
        width: double.infinity,
        height: 56,
        label: 'Create',
        loading: state.isSaving,
        gradientBackground: canSave
            ? const [Color(0xFF137e66), Color(0xFF1a9f7f)]
            : null,
        backgroundColor: canSave
            ? Colors.transparent
            : SenseiColors.gray.shade200,
        labelColor: canSave ? Colors.white : SenseiColors.gray.shade400,
        fontSize: 18,
        disabled: !canSave,
        onPressed: () async {
          _logger.track(
            'Create Course Button Tapped',
            properties: {
              'has_course_name': state.courseName.trim().isNotEmpty,
              'has_location': state.hasLocation,
              'hole_count': state.numberOfHoles,
            },
          );

          await _createCourseCubit.saveCourse(
            onSuccess: (Course course) {
              _logger.track(
                'Course Created Successfully',
                properties: {
                  'course_name': course.name,
                  'layout_count': course.layouts.length,
                  'hole_count': course.defaultLayout.holes.length,
                },
              );

              // Call parent callback
              widget.onCourseCreated(course);

              if (context.mounted) {
                // Show success message
                locator.get<ToastService>().showSuccess(
                  'Course "${course.name}" created!',
                );

                // Close the sheet
                Navigator.of(context).pop();
              }
            },
            onError: (String errorMessage) {
              _logger.track(
                'Course Creation Failed',
                properties: {'error': errorMessage},
              );

              if (context.mounted) {
                // Show error message
                locator.get<ToastService>().showError(errorMessage);
              }
            },
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }
}
