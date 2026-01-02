// lib/ui/course_search/course_search_view.dart
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course_data.dart';
import 'package:turbo_disc_golf/screens/courses/create_course_sheet.dart';
import 'package:turbo_disc_golf/services/courses/course_search_service.dart';
import 'package:turbo_disc_golf/services/firestore/course_data_loader.dart';
import 'package:turbo_disc_golf/state/record_round_cubit.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

class SelectCoursePanel extends StatefulWidget {
  const SelectCoursePanel({super.key});

  @override
  State<SelectCoursePanel> createState() => _SelectCoursePanelState();
}

class _SelectCoursePanelState extends State<SelectCoursePanel> {
  final _controller = TextEditingController();
  late final CourseSearchService _searchService;

  Timer? _debounce;
  bool _isLoading = false;

  List<CourseSearchHit> _meiliResults = [];
  List<Course> _localResults = [];

  @override
  void initState() {
    super.initState();

    _searchService = locator.get<CourseSearchService>();

    // ⭐ Load recent courses immediately
    if (kUseMeiliCourseSearch) {
      _loadRecentCourses();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // -------------------------
  // Initial recent load
  // -------------------------
  Future<void> _loadRecentCourses() async {
    final recent = await _searchService.getRecentCourses();
    setState(() {
      _meiliResults = recent;
    });
  }

  // -------------------------
  // Debounced search handler
  // -------------------------
  void _onSearchChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 200), () async {
      if (!mounted) return;

      if (kUseMeiliCourseSearch) {
        // Empty or short input → recents
        if (value.trim().length < 2) {
          await _loadRecentCourses();
          return;
        }

        setState(() => _isLoading = true);

        final results = await _searchService.searchCourses(value);

        if (!mounted) return;
        setState(() {
          _meiliResults = results;
          _isLoading = false;
        });
      } else {
        final allCourses = BlocProvider.of<RecordRoundCubit>(context).courses;

        setState(() {
          _localResults = allCourses
              .where((c) => c.name.toLowerCase().contains(value.toLowerCase()))
              .toList();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Panel header
        PanelHeader(
          title: 'Select Course',
          onClose: () => Navigator.of(context).pop(),
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

        if (_isLoading) const LinearProgressIndicator(),

        Expanded(
          child: kUseMeiliCourseSearch
              ? _buildMeiliResults()
              : _buildLocalResults(),
        ),

        // Create course button
        _buildCreateCourseButton(context),
      ],
    );
  }

  // -------------------------
  // Meilisearch + recents
  // -------------------------
  Widget _buildMeiliResults() {
    if (_meiliResults.isEmpty) {
      return const Center(child: Text('No recent courses'));
    }

    return ListView.separated(
      itemCount: _meiliResults.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: TurbColors.gray.shade50,
        indent: 16,
        endIndent: 16,
      ),
      physics: const ClampingScrollPhysics(),
      itemBuilder: (context, index) {
        final courseSearchHit = _meiliResults[index];
        return _CourseListItem(
          course: courseSearchHit,
          onTap: () => _onCourseTapped(courseSearchHit),
        );
      },
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
          onTap: () => _onCourseTapped(courseSearchHit),
        );
      },
    );
  }

  // -------------------------
  // Create course button
  // -------------------------
  Widget _buildCreateCourseButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: SafeArea(
        top: false,
        child: PrimaryButton(
          width: double.infinity,
          height: 56,
          backgroundColor: Colors.blue,
          label: 'Create new course',
          icon: Icons.add,
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                fullscreenDialog: true,
                builder: (context) => CreateCourseSheet(
                  onCourseCreated: (course) {
                    // Set the course and close both sheets
                    BlocProvider.of<RecordRoundCubit>(
                      context,
                    ).setSelectedCourse(course);
                    Navigator.pop(context); // Close create sheet
                    Navigator.pop(context); // Close select panel
                  },
                  topViewPadding: MediaQuery.of(context).padding.top,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onCourseTapped(CourseSearchHit courseSearchHit) async {
    // Fetch full Course from Firestore using course.id
    locator.get<CourseSearchService>().markCourseAsUsed(courseSearchHit);

    final Course? course = await FBCourseDataLoader.getCourseById(
      courseSearchHit.id,
    );

    if (!mounted) return;
    if (course == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Applied defaults to all holes'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    BlocProvider.of<RecordRoundCubit>(context).setSelectedCourse(course);
    Navigator.pop(context);
  }
}

// -------------------------
// Course list item widget (NO cards, NO borders)
// -------------------------
class _CourseListItem extends StatelessWidget {
  const _CourseListItem({required this.course, required this.onTap});

  final CourseSearchHit course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course name
            Text(
              course.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            // Location with icon
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: TurbColors.gray.shade400,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    [
                      course.city,
                      course.state,
                    ].where((e) => e != null && e.isNotEmpty).join(', '),
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
    );
  }
}
