import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/course/course_search_data.dart';
import 'package:turbo_disc_golf/screens/create_course/create_course_sheet.dart';
import 'package:turbo_disc_golf/screens/create_course/create_layout_sheet.dart';
import 'package:turbo_disc_golf/services/courses/course_search_service.dart';
import 'package:turbo_disc_golf/services/firestore/course_data_loader.dart';
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
  final TextEditingController _controller = TextEditingController();
  final CourseSearchService _searchService = locator.get<CourseSearchService>();

  Timer? _debounce;
  List<CourseSearchHit> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _syncFirestoreToMeiliSearch();
    _loadRecentCourses();
  }

  /// Syncs all courses from Firestore to MeiliSearch.
  /// Call this once to populate the search index with existing data.
  Future<void> _syncFirestoreToMeiliSearch() async {
    try {
      debugPrint('[MeiliSearch Sync] Starting sync...');

      // Load all courses from Firestore
      final List<Course> courses = await FBCourseDataLoader.getAllCourses();
      debugPrint(
        '[MeiliSearch Sync] Loaded ${courses.length} courses from Firestore',
      );

      if (courses.isEmpty) {
        debugPrint('[MeiliSearch Sync] No courses to sync');
        return;
      }

      // Sync to MeiliSearch
      await _searchService.upsertCourses(courses);
      debugPrint(
        '[MeiliSearch Sync] Successfully synced ${courses.length} courses to MeiliSearch',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synced ${courses.length} courses to search index'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('[MeiliSearch Sync] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync courses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecentCourses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<CourseSearchHit> recent = await _searchService
          .getRecentCourses();
      if (mounted) {
        setState(() {
          _searchResults = recent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load recent courses';
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      _loadRecentCourses();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final List<CourseSearchHit> results = await _searchService
            .searchCourses(value);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Search failed. Please try again.';
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PanelHeader(
          title: 'Select Course',
          onClose: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
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
        Expanded(child: _buildSearchResults()),
        _buildCreateCourseButton(context),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _error!,
            style: TextStyle(color: TurbColors.gray.shade500),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _controller.text.isEmpty ? 'No recent courses' : 'No courses found',
            style: TextStyle(color: TurbColors.gray.shade500),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: TurbColors.gray.shade50,
        indent: 16,
        endIndent: 16,
      ),
      physics: const ClampingScrollPhysics(),
      itemBuilder: (context, index) {
        final CourseSearchHit hit = _searchResults[index];
        return _CourseSearchResultItem(
          hit: hit,
          onLayoutSelected: (layoutSummary) =>
              _onLayoutSelected(hit, layoutSummary),
          onCreateLayout: () => _openCreateLayoutSheet(hit),
          onEditLayout: (layoutSummary) =>
              _openEditLayoutSheet(hit, layoutSummary),
        );
      },
    );
  }

  Future<void> _onLayoutSelected(
    CourseSearchHit hit,
    CourseLayoutSummary layoutSummary,
  ) async {
    // Fetch full course from Firestore
    final Course? course = await FBCourseDataLoader.getCourseById(hit.id);
    if (course == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to load course')));
      }
      return;
    }

    // Mark course as recently used
    await _searchService.markCourseAsUsed(hit);

    if (mounted) {
      BlocProvider.of<RecordRoundCubit>(
        context,
      ).setSelectedCourse(course, layoutId: layoutSummary.id);
      Navigator.pop(context);
    }
  }

  Future<void> _openCreateLayoutSheet(CourseSearchHit hit) async {
    // Fetch full course for the layout sheet
    final Course? course = await FBCourseDataLoader.getCourseById(hit.id);
    if (course == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to load course')));
      }
      return;
    }

    if (!mounted) return;

    pushCupertinoRoute(
      context,
      CreateLayoutSheet(
        course: course,
        onLayoutSaved: (layout) {
          _handleLayoutSaved(course, layout, isNew: true);
        },
        topViewPadding: widget.topViewPadding,
        bottomViewPadding: widget.bottomViewPadding,
      ),
      pushFromBottom: true,
    );
  }

  Future<void> _openEditLayoutSheet(
    CourseSearchHit hit,
    CourseLayoutSummary layoutSummary,
  ) async {
    // Fetch full course for the layout sheet
    final Course? course = await FBCourseDataLoader.getCourseById(hit.id);
    if (course == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to load course')));
      }
      return;
    }

    // Find the full layout
    final CourseLayout? layout = course.layouts
        .where((l) => l.id == layoutSummary.id)
        .firstOrNull;

    if (layout == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Layout not found')));
      }
      return;
    }

    if (!mounted) return;

    pushCupertinoRoute(
      context,
      CreateLayoutSheet(
        course: course,
        existingLayout: layout,
        onLayoutSaved: (updatedLayout) {
          _handleLayoutSaved(course, updatedLayout, isNew: false);
        },
        topViewPadding: widget.topViewPadding,
        bottomViewPadding: widget.bottomViewPadding,
      ),
      pushFromBottom: true,
    );
  }

  Future<void> _handleLayoutSaved(
    Course course,
    CourseLayout layout, {
    required bool isNew,
  }) async {
    // Update the course with the new/updated layout
    final Course updatedCourse;
    if (isNew) {
      updatedCourse = course.copyWith(layouts: [...course.layouts, layout]);
    } else {
      updatedCourse = course.copyWith(
        layouts: course.layouts
            .map((l) => l.id == layout.id ? layout : l)
            .toList(),
      );
    }

    // Save to Firestore
    if (isNew) {
      await FBCourseDataLoader.addLayoutToCourse(course.id, layout);
    } else {
      await FBCourseDataLoader.updateLayoutInCourse(course.id, layout);
    }

    // Update MeiliSearch index
    await _searchService.upsertCourse(updatedCourse);

    // Refresh search results
    if (_controller.text.isEmpty) {
      await _loadRecentCourses();
    } else {
      _onSearchChanged(_controller.text);
    }
  }

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
                // MeiliSearch indexing is handled by CreateCourseCubit.saveCourse()
                BlocProvider.of<RecordRoundCubit>(
                  context,
                ).setSelectedCourse(course, layoutId: course.defaultLayout.id);
                Navigator.pop(context);
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
}

class _CourseSearchResultItem extends StatefulWidget {
  const _CourseSearchResultItem({
    required this.hit,
    required this.onLayoutSelected,
    required this.onCreateLayout,
    required this.onEditLayout,
  });

  final CourseSearchHit hit;
  final void Function(CourseLayoutSummary layout) onLayoutSelected;
  final VoidCallback onCreateLayout;
  final void Function(CourseLayoutSummary layout) onEditLayout;

  @override
  State<_CourseSearchResultItem> createState() =>
      _CourseSearchResultItemState();
}

class _CourseSearchResultItemState extends State<_CourseSearchResultItem> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String location = [
      widget.hit.city,
      widget.hit.state,
    ].where((e) => e != null && e.isNotEmpty).join(', ');

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
                      Text(
                        widget.hit.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          location,
                          style: TextStyle(
                            fontSize: 13,
                            color: TurbColors.gray.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.hit.layouts.length == 1
                      ? '1 layout'
                      : '${widget.hit.layouts.length} layouts',
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
        children: [
          ...widget.hit.layouts.map((layout) {
            return _LayoutSummaryItem(
              layout: layout,
              onTap: () => widget.onLayoutSelected(layout),
              onEdit: () => widget.onEditLayout(layout),
            );
          }),
          _NewLayoutButton(onTap: widget.onCreateLayout),
        ],
      ),
    );
  }
}

class _LayoutSummaryItem extends StatelessWidget {
  const _LayoutSummaryItem({
    required this.layout,
    required this.onTap,
    required this.onEdit,
  });

  final CourseLayoutSummary layout;
  final VoidCallback onTap;
  final VoidCallback onEdit;

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
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onEdit();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: TurbColors.gray.shade400,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
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

class _NewLayoutButton extends StatelessWidget {
  const _NewLayoutButton({required this.onTap});

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
              color: TurbColors.gray.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: TurbColors.gray.shade200,
                width: 1,
                style: BorderStyle.solid,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.add, size: 20, color: TurbColors.gray.shade600),
                const SizedBox(width: 8),
                Text(
                  'New layout',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: TurbColors.gray.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
