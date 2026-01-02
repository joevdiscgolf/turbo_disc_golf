import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/hole_grid_card.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/models/data/course_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/state/create_course_cubit.dart';
import 'package:turbo_disc_golf/state/create_course_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Bottom sheet / modal for creating a course + default layout
class CreateCourseSheet extends StatefulWidget {
  const CreateCourseSheet({
    super.key,
    required this.onCourseCreated,
    required this.topViewPadding,
  });

  final void Function(Course course) onCourseCreated;
  final double topViewPadding;

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
              padding: const EdgeInsets.only(bottom: 16),
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

          // return SafeArea(
          //   child: DraggableScrollableSheet(
          //     controller: _sheetController,
          //     expand: false,
          //     initialChildSize: 1.0,
          //     minChildSize: 0.0,
          //     maxChildSize: 1.0,
          //     snap: true,
          //     snapSizes: const [1.0],
          //     builder: (context, scrollController) {
          //       return
          //     },
          //   ),
          // );
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
        SegmentedButton<int>(
          segments: const [
            ButtonSegment<int>(value: 9, label: Text('9')),
            ButtonSegment<int>(value: 18, label: Text('18')),
            ButtonSegment<int>(value: 0, label: Text('Custom')),
          ],
          selected: {state.numberOfHoles == 9 || state.numberOfHoles == 18 ? state.numberOfHoles : 0},
          onSelectionChanged: (Set<int> selection) {
            final int value = selection.first;
            if (value == 0) {
              _showCustomHoleCountDialog(context);
            } else {
              _createCourseCubit.updateHoleCount(value);
            }
          },
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: state.isParsingImage
              ? null
              : () => _createCourseCubit.pickAndParseImage(context),
          borderRadius: BorderRadius.circular(12),
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
                  state.isParsingImage ? Icons.hourglass_empty : Icons.camera_alt,
                  color: TurbColors.gray.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.isParsingImage ? 'Parsing Image...' : 'Upload scorecard image',
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

  Widget _buildQuickFillCard(BuildContext context) {
    int quickFillPar = 3;
    int quickFillFeet = 300;
    HoleType quickFillType = HoleType.open;

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text(
                'Quick Fill',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: const Text(
                'Set default values for all holes',
                style: TextStyle(fontSize: 12),
              ),
              initiallyExpanded: false,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
              collapsedBackgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.05),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: quickFillPar.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Par',
                                isDense: true,
                              ),
                              onChanged: (v) {
                                final int? parsed = int.tryParse(v);
                                if (parsed != null) {
                                  setState(() => quickFillPar = parsed);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: quickFillFeet.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Distance (ft)',
                                isDense: true,
                              ),
                              onChanged: (v) {
                                final int? parsed = int.tryParse(v);
                                if (parsed != null) {
                                  setState(() => quickFillFeet = parsed);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<HoleType>(
                        initialValue: quickFillType,
                        decoration: const InputDecoration(
                          labelText: 'Hole Type',
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: HoleType.open,
                            child: Text('🌳 Open'),
                          ),
                          DropdownMenuItem(
                            value: HoleType.slightlyWooded,
                            child: Text('🌲 Moderate'),
                          ),
                          DropdownMenuItem(
                            value: HoleType.wooded,
                            child: Text('🌲🌲 Wooded'),
                          ),
                        ],
                        onChanged: (HoleType? value) {
                          if (value != null) {
                            setState(() => quickFillType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _createCourseCubit.applyDefaultsToAllHoles(
                              defaultPar: quickFillPar,
                              defaultFeet: quickFillFeet,
                              defaultType: quickFillType,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Applied defaults to all holes'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text('Apply to All Holes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  Widget _buildHolesSection(BuildContext context, CreateCourseState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Holes', Icons.sports_golf, Colors.orange),
        const SizedBox(height: 8),
        _buildQuickFillCard(context),
        const SizedBox(height: 8),
        ...state.holes.map((hole) {
          return HoleGridCard(
            hole: hole,
            onParChanged: (v) =>
                _createCourseCubit.updateHolePar(hole.holeNumber, v),
            onFeetChanged: (v) =>
                _createCourseCubit.updateHoleFeet(hole.holeNumber, v),
            onTypeChanged: (type) =>
                _createCourseCubit.updateHoleType(hole.holeNumber, type),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────
  Widget _buildSaveButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF137e66), Color(0xFF1a9f7f)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: _createCourseCubit.saveCourse,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: const Text(
          'Create Course',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
