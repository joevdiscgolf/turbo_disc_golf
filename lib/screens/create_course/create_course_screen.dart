import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/custom_cupertino_action_sheet.dart';
import 'package:turbo_disc_golf/components/footers/form_footer.dart';
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
import 'package:turbo_disc_golf/utils/layout_helpers.dart';
import 'package:turbo_disc_golf/utils/navigation_helpers.dart';

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

    // Check for saved draft after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForSavedDraft();
    });
  }

  Future<void> _checkForSavedDraft() async {
    final bool hasDraft = await CreateCourseCubit.hasDraft();
    if (!hasDraft || !mounted) return;

    _logger.track('Draft Found On Screen Open');

    final String? result = await showCupertinoModalPopup<String>(
      context: context,
      builder: (dialogContext) => CustomCupertinoActionSheet(
        title: 'Resume draft?',
        message: 'You have a saved draft. Would you like to continue where you left off?',
        destructiveActionLabel: 'Start fresh',
        onDestructiveActionPressed: () {
          CreateCourseCubit.clearDraft();
          Navigator.pop(dialogContext, 'start_fresh');
        },
        additionalActions: [
          ActionSheetAction(
            label: 'Resume draft',
            onPressed: () => Navigator.pop(dialogContext, 'resume'),
          ),
        ],
        onCancelPressed: () => Navigator.pop(dialogContext, 'cancel'),
      ),
    );

    if (result == 'resume' && mounted) {
      _logger.track('Draft Resumed');
      final bool loaded = await _createCourseCubit.loadDraft();
      if (loaded && mounted) {
        // Update text controllers with loaded values
        final CreateCourseState state = _createCourseCubit.state;
        _cityController.text = state.city ?? '';
        _stateController.text = state.state ?? '';
        locator.get<ToastService>().showInfo('Draft restored');
      }
    } else if (result == 'start_fresh') {
      _logger.track('Draft Discarded On Resume');
    }
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

    final String? result = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CustomCupertinoActionSheet(
        title: 'Unsaved changes',
        message: 'You have unsaved changes. What would you like to do?',
        destructiveActionLabel: 'Discard',
        onDestructiveActionPressed: () {
          CreateCourseCubit.clearDraft();
          Navigator.pop(context, 'discard');
        },
        additionalActions: [
          ActionSheetAction(
            label: 'Save draft',
            onPressed: () async {
              await _createCourseCubit.saveDraft();
              if (context.mounted) {
                Navigator.pop(context, 'save_draft');
              }
            },
          ),
        ],
        onCancelPressed: () => Navigator.pop(context, 'cancel'),
      ),
    );

    if (result == 'discard' || result == 'save_draft') {
      if (result == 'save_draft' && mounted) {
        locator.get<ToastService>().showSuccess('Draft saved');
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
      child: PopScope(
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _buildCourseSection(context, state),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Divider(
                                height: 32,
                                color: SenseiColors.gray.shade100,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: LayoutInfoSection(
                                headerTitle: 'Default Layout',
                                layoutName: state.layoutName,
                                numberOfHoles: state.numberOfHoles,
                                onLayoutNameChanged:
                                    _createCourseCubit.updateLayoutName,
                                onHoleCountChanged: (int newCount) =>
                                    _handleHoleCountChange(state, newCount),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Divider(
                                height: 32,
                                color: SenseiColors.gray.shade100,
                                thickness: 1,
                              ),
                            ),
                            HolesSection(
                              holes: state.holes,
                              isParsingImage: state.isParsingImage,
                              parseError: state.parseError,
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
                      // Fixed bottom footer
                      _buildFooter(context, state),
                    ],
                  ),
                );
              },
            ),
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
      final bool? confirmed = await showCupertinoModalPopup<bool>(
        context: context,
        builder: (context) => CustomCupertinoActionSheet(
          title: 'Reduce hole count?',
          message:
              'Changing to $newCount holes will remove data for holes ${newCount + 1}-${state.numberOfHoles}.',
          destructiveActionLabel: 'Continue',
          onDestructiveActionPressed: () => Navigator.pop(context, true),
          onCancelPressed: () => Navigator.pop(context, false),
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SenseiColors.gray.shade100, width: 1),
          boxShadow: defaultCardBoxShadow(),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SenseiColors.gray.shade100, width: 1),
          boxShadow: defaultCardBoxShadow(),
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
    pushCupertinoRoute(
      context,
      LocationPickerSheet(
        topViewPadding: widget.topViewPadding,
        initialLatitude: state.latitude,
        initialLongitude: state.longitude,
        onLocationSelected: (double lat, double lng) {
          _logger.track('Location Selected On Map');
          _createCourseCubit.updateLocation(lat, lng);
        },
      ),
      pushFromBottom: true,
    );
  }

  // ─────────────────────────────────────────────
  Widget _buildFooter(BuildContext context, CreateCourseState state) {
    final bool canSave = state.courseName.trim().isNotEmpty && !state.isSaving;

    return FormFooter(
      label: 'Create',
      canSave: canSave,
      loading: state.isSaving,
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

            // Clear any saved draft on successful save
            CreateCourseCubit.clearDraft();

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
