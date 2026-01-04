import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/screens/create_course/components/create_course_hole_card.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/screens/create_course/components/quick_fill_holes_card.dart';
import 'package:turbo_disc_golf/state/create_course_cubit.dart';
import 'package:turbo_disc_golf/state/create_course_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

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
            child: ListView(
              padding: EdgeInsets.only(bottom: widget.bottomViewPadding),
              children: [
                // PanelHeader(
                //   title: 'Create Course',
                //   onClose: () => Navigator.of(context).pop(),
                // ),
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
                      _buildLayoutSection(context, state),
                      Divider(
                        height: 32,
                        color: TurbColors.gray.shade100,
                        thickness: 1,
                      ),
                      _buildHolesSection(context, state),
                      const SizedBox(height: 24),
                      _buildSaveButton(context),
                    ],
                  ),
                ),
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
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: _createCourseCubit.updateCity,
                decoration: const InputDecoration(labelText: 'City'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: _createCourseCubit.updateState,
                decoration: const InputDecoration(labelText: 'State'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: _createCourseCubit.updateCountry,
          decoration: const InputDecoration(labelText: 'Country'),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  Widget _buildLayoutSection(BuildContext context, CreateCourseState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Default Layout', Icons.grid_view, Colors.teal),
        const SizedBox(height: 12),
        TextField(
          onChanged: _createCourseCubit.updateLayoutName,
          decoration: const InputDecoration(labelText: 'Layout name'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Number of holes',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    side: WidgetStateProperty.all(
                      BorderSide(color: TurbColors.gray.shade300),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  segments: [
                    ButtonSegment<int>(
                      value: 9,
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: const Text('9', maxLines: 1),
                      ),
                    ),
                    ButtonSegment<int>(
                      value: 18,
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: const Text('18', maxLines: 1),
                      ),
                    ),
                    ButtonSegment<int>(
                      value: 0,
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          state.numberOfHoles != 9 && state.numberOfHoles != 18
                              ? 'Custom (${state.numberOfHoles})'
                              : 'Custom',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  selected: {
                    state.numberOfHoles == 9 || state.numberOfHoles == 18
                        ? state.numberOfHoles
                        : 0,
                  },
                  onSelectionChanged: (Set<int> selection) {
                    final int value = selection.first;
                    if (value == 0) {
                      _showCustomHoleCountDialog(context);
                    } else {
                      _createCourseCubit.updateHoleCount(value);
                    }
                  },
                ),
              ),
              // Transparent overlay on custom segment to allow re-tapping
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => _showCustomHoleCountDialog(context),
                  child: Container(
                    width: MediaQuery.of(context).size.width / 3 - 16,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: state.isParsingImage
              ? null
              : () async {
                  // Unfocus any active text fields first
                  FocusScope.of(context).unfocus();
                  // Small delay to ensure keyboard is dismissed
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (context.mounted) {
                    _createCourseCubit.pickAndParseImage(context);
                  }
                },
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
                  state.isParsingImage
                      ? Icons.hourglass_empty
                      : Icons.camera_alt,
                  color: TurbColors.gray.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.isParsingImage
                            ? 'Parsing Image...'
                            : 'Upload scorecard image',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: TurbColors.gray.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Auto-fill par & distance from photo',
                        style: TextStyle(
                          fontSize: 12,
                          color: TurbColors.gray.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.isParsingImage)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
        if (state.parseError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              state.parseError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showCustomHoleCountDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    final int? customCount = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Hole Count'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of holes',
            hintText: 'Enter 1-99',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final int? value = int.tryParse(controller.text);
              if (value != null && value >= 1 && value <= 99) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (customCount != null) {
      _createCourseCubit.updateHoleCount(customCount);
    }
  }

  // ─────────────────────────────────────────────
  Widget _buildHolesSection(BuildContext context, CreateCourseState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Holes', Icons.sports_golf, Colors.orange),
        const SizedBox(height: 8),
        QuickFillHolesCard(),
        const SizedBox(height: 8),
        ...addDividers(
          state.holes.map((hole) {
            return CrateCourseHoleCard(
              hole: hole,
              onParChanged: (v) =>
                  _createCourseCubit.updateHolePar(hole.holeNumber, v),
              onFeetChanged: (v) =>
                  _createCourseCubit.updateHoleFeet(hole.holeNumber, v),
              onTypeChanged: (type) =>
                  _createCourseCubit.updateHoleType(hole.holeNumber, type),
            );
          }).toList(),
          height: 12,
          dividerColor: TurbColors.gray[50],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  Widget _buildSaveButton(BuildContext context) {
    return PrimaryButton(
      width: double.infinity,
      height: 56,
      label: 'Create Course',
      gradientBackground: const [Color(0xFF137e66), Color(0xFF1a9f7f)],
      fontSize: 18,
      fontWeight: FontWeight.bold,
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
