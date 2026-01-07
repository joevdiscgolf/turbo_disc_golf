import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/course/course_search_data.dart';
import 'package:turbo_disc_golf/screens/create_course/create_course_sheet.dart';
import 'package:turbo_disc_golf/services/courses/course_search_service.dart';
import 'package:turbo_disc_golf/services/courses/courses_service.dart';
import 'package:turbo_disc_golf/state/record_round_cubit.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/navigation_helpers.dart';

class SelectCoursePanel extends StatefulWidget {
  const SelectCoursePanel({
    super.key,
    required this.topViewPadding,
    required this.bottomViewPadding,
  });

  final double topViewPadding;
  final double bottomViewPadding;

  @override
  State<SelectCoursePanel> createState() => _SelectCoursePanelState();
}

class _SelectCoursePanelState extends State<SelectCoursePanel> {
  final _controller = TextEditingController();

  Timer? _debounce;
  List<Course> _localResults = [];

  @override
  void initState() {
    super.initState();
    _loadAllCourses();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // -------------------------
  // Load all test courses
  // -------------------------
  void _loadAllCourses() {
    setState(() {
      _localResults = kTestCourses;
    });
  }

  // -------------------------
  // Debounced search handler
  // -------------------------
  void _onSearchChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      setState(() {
        if (value.trim().isEmpty) {
          // Empty search → show all test courses
          _localResults = kTestCourses;
        } else {
          // Filter courses based on search text
          _localResults = kTestCourses
              .where((c) => c.name.toLowerCase().contains(value.toLowerCase()))
              .toList();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Panel header
        PanelHeader(
          title: 'Select Course',
          onClose: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),

        // 🔍 Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: TextField(
            controller: _controller,
            onChanged: _onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Search courses…',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),

        Expanded(child: _buildLocalResults()),

        // Create course button
        _buildCreateCourseButton(context),
      ],
    );
  }

  // -------------------------
  // Local (test) results
  // -------------------------
  Widget _buildLocalResults() {
    return ListView.separated(
      itemCount: _localResults.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: TurbColors.gray.shade50,
        indent: 16,
        endIndent: 16,
      ),
      physics: const ClampingScrollPhysics(),
      itemBuilder: (context, index) {
        final course = _localResults[index];
        final courseSearchHit = course.toCourseSearchHit();
        return _CourseListItem(
          course: courseSearchHit,
          onLayoutSelected: (layout) =>
              _onLayoutSelected(courseSearchHit, layout),
        );
      },
    );
  }

  // -------------------------
  // Create course button
  // -------------------------
  Widget _buildCreateCourseButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: widget.bottomViewPadding,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: PrimaryButton(
        width: double.infinity,
        height: 56,
        backgroundColor: Colors.blue,
        label: 'Create new course',
        icon: Icons.add,
        onPressed: () {
          Navigator.of(context).pop();

          pushCupertinoRoute(
            context,
            CreateCourseSheet(
              onCourseCreated: (course) {
                BlocProvider.of<RecordRoundCubit>(
                  context,
                ).setSelectedCourse(course, layoutId: course.defaultLayout.id);

                Navigator.pop(context); // Close create sheet
                // Navigator.pop(context); // Close select panel
              },
              topViewPadding: widget.topViewPadding,
              bottomViewPadding: widget.bottomViewPadding,
            ),
            pushFromBottom: true,
          );
        },
      ),
    );
  }

  void _onLayoutSelected(
    CourseSearchHit courseSearchHit,
    CourseLayoutSummary layout,
  ) {
    // Find the full course from kTestCourses
    final Course? course = kTestCourses.cast<Course?>().firstWhere(
      (c) => c?.id == courseSearchHit.id,
      orElse: () => null,
    );

    if (course != null) {
      BlocProvider.of<RecordRoundCubit>(
        context,
      ).setSelectedCourse(course, layoutId: layout.id);
    }

    Navigator.pop(context);
  }
}

// -------------------------
// Course list item widget with expandable layouts
// -------------------------
class _CourseListItem extends StatefulWidget {
  const _CourseListItem({required this.course, required this.onLayoutSelected});

  final CourseSearchHit course;
  final void Function(CourseLayoutSummary layout) onLayoutSelected;

  @override
  State<_CourseListItem> createState() => _CourseListItemState();
}

class _CourseListItemState extends State<_CourseListItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggleExpanded,
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course name
                      Text(
                        widget.course.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Location with icon
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              [widget.course.city, widget.course.state]
                                  .where((e) => e != null && e.isNotEmpty)
                                  .join(', '),
                              style: TextStyle(
                                fontSize: 13,
                                color: TurbColors.gray.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.course.layouts.length == 1
                      ? '1 layout'
                      : '${widget.course.layouts.length} layouts',
                  style: TextStyle(
                    fontSize: 12,
                    color: TurbColors.gray.shade400,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right,
                    color: TurbColors.gray.shade400,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        ClipRect(
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            heightFactor: _isExpanded ? 1.0 : 0.0,
            alignment: Alignment.topCenter,
            child: _buildLayoutsList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutsList() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.course.layouts.map((layout) {
          return _LayoutListItem(
            layout: layout,
            onTap: () => widget.onLayoutSelected(layout),
          );
        }).toList(),
      ),
    );
  }
}

// -------------------------
// Layout list item widget
// -------------------------
class _LayoutListItem extends StatelessWidget {
  const _LayoutListItem({required this.layout, required this.onTap});

  final CourseLayoutSummary layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  flattenedOverWhite(TurbColors.blue, 0.1),
                  flattenedOverWhite(TurbColors.blue, 0.05),
                ],
                begin: Alignment.bottomRight,
                end: Alignment.topLeft,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: TurbColors.gray.shade100, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        layout.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${layout.holeCount} holes • Par ${layout.par} • ${layout.totalFeet} ft',
                        style: TextStyle(
                          fontSize: 12,
                          color: TurbColors.gray.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: TurbColors.gray.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
