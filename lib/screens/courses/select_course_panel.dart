// lib/ui/course_search/course_search_view.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course_data.dart';
import 'package:turbo_disc_golf/services/courses/course_search_service.dart';
import 'package:turbo_disc_golf/services/firestore/course_data_loader.dart';
import 'package:turbo_disc_golf/state/record_round_cubit.dart';
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
        // 🔍 Search bar
        Padding(
          padding: const EdgeInsets.all(12),
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

    return ListView.builder(
      itemCount: _meiliResults.length,
      itemBuilder: (context, index) {
        final courseSearchHit = _meiliResults[index];

        return ListTile(
          title: Text(courseSearchHit.name),
          subtitle: Text(
            [
              courseSearchHit.city,
              courseSearchHit.state,
            ].where((e) => e != null && e.isNotEmpty).join(', '),
          ),
          onTap: () async {
            _onCourseTapped(courseSearchHit);
          },
        );
      },
    );
  }

  // -------------------------
  // Local (test) results
  // -------------------------
  Widget _buildLocalResults() {
    return ListView.builder(
      itemCount: _localResults.length,
      itemBuilder: (context, index) {
        final course = _localResults[index];

        return ListTile(
          title: Text(course.name),
          subtitle: Text(
            [
              course.city,
              course.state,
            ].where((e) => e != null && e.isNotEmpty).join(', '),
          ),
          onTap: () {
            _onCourseTapped(course.toCourseSearchHit());
          },
        );
      },
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
