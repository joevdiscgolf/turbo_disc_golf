import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/map/location_picker_sheet.dart';
import 'package:turbo_disc_golf/components/map/mini_map_preview.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/screens/create_course/components/holes_section.dart';
import 'package:turbo_disc_golf/screens/create_course/components/layout_info_section.dart';
import 'package:turbo_disc_golf/state/create_course_cubit.dart';
import 'package:turbo_disc_golf/state/create_course_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

/// Bottom sheet / modal for creating a course + default layout
class CreateCourseSheet extends StatefulWidget {
  const CreateCourseSheet({
    super.key,
    required this.onCourseCreated,
    required this.topViewPadding,
    required this.bottomViewPadding,
  });

  final void Function(Course course) onCourseCreated;
  final double topViewPadding;
  final double bottomViewPadding;

  @override
  State<CreateCourseSheet> createState() => _CreateCourseSheetState();
}

class _CreateCourseSheetState extends State<CreateCourseSheet> {
  late final CreateCourseCubit _createCourseCubit;

  @override
  void initState() {
    super.initState();
    _createCourseCubit = BlocProvider.of<CreateCourseCubit>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: GenericAppBar(
        topViewPadding: widget.topViewPadding,
        title: 'Create course',
        rightWidget: IconButton(
          icon: const Icon(
            Icons.close,
            size: PanelConstants.closeButtonIconSize,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
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
                // Scrollable content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 12, bottom: 48),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCourseSection(context, state),
                            Divider(
                              height: 32,
                              color: TurbColors.gray.shade100,
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
                              onHoleCountChanged:
                                  _createCourseCubit.updateHoleCount,
                              onParseImage: () async {
                                HapticFeedback.lightImpact();
                                FocusScope.of(context).unfocus();
                                await Future.delayed(
                                  const Duration(milliseconds: 300),
                                );
                                if (context.mounted) {
                                  _createCourseCubit.pickAndParseImage(context);
                                }
                              },
                            ),
                            Divider(
                              height: 32,
                              color: TurbColors.gray.shade100,
                              thickness: 1,
                            ),
                            HolesSection(
                              holes: state.holes,
                              onApplyDefaults:
                                  _createCourseCubit.applyDefaultsToAllHoles,
                              onHoleParChanged: _createCourseCubit.updateHolePar,
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
    );
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
          decoration: const InputDecoration(labelText: 'Course name'),
        ),
        const SizedBox(height: 12),
        // Map location picker (controlled by feature flag)
        if (showMapLocationPicker) ...[
          _buildLocationPickerSection(context, state),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
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
                controller: TextEditingController(text: state.city ?? '')
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: state.city?.length ?? 0),
                  ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: _createCourseCubit.updateState,
                decoration: const InputDecoration(labelText: 'State'),
                controller: TextEditingController(text: state.state ?? '')
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: state.state?.length ?? 0),
                  ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: _createCourseCubit.updateCountry,
          decoration: const InputDecoration(labelText: 'Country'),
          controller: TextEditingController(text: state.country ?? '')
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: state.country?.length ?? 0),
            ),
        ),
      ],
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
          color: TurbColors.gray.shade50,
          border: Border.all(color: TurbColors.gray.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.map_outlined,
              color: TurbColors.gray.shade600,
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
                      color: TurbColors.gray.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pin your course for easy discovery',
                    style: TextStyle(
                      fontSize: 12,
                      color: TurbColors.gray.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: TurbColors.gray.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _openLocationPicker(BuildContext context, CreateCourseState state) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocationPickerSheet(
          topViewPadding: widget.topViewPadding,
          initialLatitude: state.latitude,
          initialLongitude: state.longitude,
          onLocationSelected: (double lat, double lng) {
            _createCourseCubit.updateLocation(lat, lng);
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  Widget _buildFooter(BuildContext context, CreateCourseState state) {
    final bool canSave = state.courseName.trim().isNotEmpty;

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
        label: 'Create Course',
        gradientBackground: canSave
            ? const [Color(0xFF137e66), Color(0xFF1a9f7f)]
            : null,
        backgroundColor: canSave
            ? Colors.transparent
            : TurbColors.gray.shade200,
        labelColor: canSave ? Colors.white : TurbColors.gray.shade400,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        disabled: !canSave,
        onPressed: () async {
          await _createCourseCubit.saveCourse(
            onSuccess: (Course course) {
              // Call parent callback
              widget.onCourseCreated(course);

              if (context.mounted) {
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Course "${course.name}" created!')),
                );

                // Close the sheet
                Navigator.of(context).pop();
              }
            },
            onError: (String errorMessage) {
              if (context.mounted) {
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                  ),
                );
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
