import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/course/course_search_data.dart';
import 'package:turbo_disc_golf/screens/create_course/create_course_screen.dart';
import 'package:turbo_disc_golf/screens/create_course/create_layout_sheet.dart';
import 'package:turbo_disc_golf/services/courses/course_search_service.dart';
import 'package:turbo_disc_golf/services/firestore/course_data_loader.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/state/record_round_cubit.dart';
import 'package:turbo_disc_golf/utils/auth_helpers.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/navigation_helpers.dart';

class SelectCoursePanel extends StatefulWidget {
  const SelectCoursePanel({
    super.key,
    required this.topViewPadding,
    required this.bottomViewPadding,
  });

  static const String panelName = 'Select Course';

  final double topViewPadding;
  final double bottomViewPadding;

  @override
  State<SelectCoursePanel> createState() => _SelectCoursePanelState();
}

class _SelectCoursePanelState extends State<SelectCoursePanel> {
  final TextEditingController _controller = TextEditingController();
  final CourseSearchService _searchService = locator.get<CourseSearchService>();
  late final LoggingServiceBase _logger;

  Timer? _debounce;
  List<CourseSearchHit> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();

    // Create scoped logger with base properties
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'panel_name': SelectCoursePanel.panelName,
    });

    // Track panel impression
    _logger.track(
      'Panel Impression',
      properties: {'panel_class': 'SelectCoursePanel'},
    );

    // Check admin status
    _isAdmin = isCurrentUserAdmin();

    _loadRecentCourses();
  }

  // ==========================================================================
  // TESTING FUNCTIONS - Call these from initState for debugging
  // ==========================================================================

  /// Syncs all courses from Firestore to the local Meili search instance.
  /// Firestore is the source of truth - this will upsert all courses to Meili.
  /// Useful for populating a local Meili instance for simulator testing.
  // Future<void> _syncMeiliFromFirestore() async {
  //   try {
  //     debugPrint('[Testing] Syncing Meili from Firestore...');

  //     // Fetch all courses from Firestore
  //     final List<Course> courses = await FBCourseDataLoader.getAllCourses();
  //     debugPrint('[Testing] Found ${courses.length} courses in Firestore');

  //     if (courses.isEmpty) {
  //       debugPrint('[Testing] No courses to sync');
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('No courses found in Firestore'),
  //             backgroundColor: Colors.orange,
  //           ),
  //         );
  //       }
  //       return;
  //     }

  //     // Upsert each course to Meili
  //     int successCount = 0;
  //     int failCount = 0;
  //     for (final Course course in courses) {
  //       try {
  //         await _searchService.upsertCourse(course);
  //         successCount++;
  //         debugPrint('[Testing] ✓ Synced: ${course.name}');
  //       } catch (e) {
  //         failCount++;
  //         debugPrint('[Testing] ✗ Failed to sync ${course.name}: $e');
  //       }
  //     }

  //     debugPrint(
  //       '[Testing] Sync complete: $successCount succeeded, $failCount failed',
  //     );

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(
  //             'Synced $successCount/${courses.length} courses to Meili',
  //           ),
  //           backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
  //         ),
  //       );
  //     }
  //   } catch (e, stackTrace) {
  //     debugPrint('[Testing] Failed to sync Meili from Firestore: $e');
  //     debugPrint('[Testing] Stack trace: $stackTrace');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Failed to sync Meili: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  /// Clears the shared preferences recent courses cache.
  /// Useful for testing the empty state or resetting the cache.
  // Future<void> _clearRecentCoursesCache() async {
  //   try {
  //     debugPrint('[Testing] Clearing recent courses cache...');
  //     await _searchService.clearRecentCoursesCache();
  //     debugPrint('[Testing] Successfully cleared recent courses cache');

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Cleared recent courses cache'),
  //           backgroundColor: Colors.orange,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint('[Testing] Failed to clear cache: $e');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Failed to clear cache: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  // /// Syncs the shared preferences cache from Firestore.
  // /// For each course in the cache, fetches the latest version from Firestore
  // /// and updates the cache. Firestore is the source of truth.
  // Future<void> _syncCacheFromFirestore() async {
  //   try {
  //     debugPrint('[Testing] Syncing cache from Firestore...');
  //     final int updatedCount = await _searchService.syncCacheFromFirestore();
  //     debugPrint(
  //       '[Testing] Successfully synced $updatedCount courses from Firestore',
  //     );

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Synced $updatedCount courses from Firestore'),
  //           backgroundColor: Colors.green,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint('[Testing] Failed to sync from Firestore: $e');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Failed to sync from Firestore: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  // ==========================================================================
  // END TESTING FUNCTIONS
  // ==========================================================================

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
      debugPrint('[SelectCoursePanel] Loading recent courses...');
      final List<CourseSearchHit> recent = await _searchService
          .getRecentCourses();
      debugPrint('[SelectCoursePanel] Loaded ${recent.length} recent courses');
      if (mounted) {
        setState(() {
          _searchResults = recent;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      // Gracefully handle errors by showing empty state instead of error
      debugPrint('[SelectCoursePanel] Failed to load recent courses: $e');
      debugPrint('[SelectCoursePanel] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _searchResults = [];
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

      _logger.track(
        'Course Search Executed',
        properties: {'query_length': value.length},
      );

      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final List<CourseSearchHit> results = await _searchService
            .searchCourses(value);
        if (mounted) {
          _logger.track(
            'Course Search Results Returned',
            properties: {'result_count': results.length},
          );
          setState(() {
            _searchResults = results;
            _isLoading = false;
          });
        }
      } catch (e, trace) {
        debugPrint(e.toString());
        debugPrint(trace.toString());
        _logger.track(
          'Course Search Failed',
          properties: {'error': e.toString()},
        );
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
            _logger.track('Close Panel Button Tapped');
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
      return _EmptyStateWidget(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        subtitle: _error!,
        onRetry: _controller.text.isEmpty
            ? _loadRecentCourses
            : () => _onSearchChanged(_controller.text),
      );
    }

    if (_searchResults.isEmpty) {
      return _controller.text.isEmpty
          ? const _EmptyStateWidget(
              icon: Icons.landscape_outlined,
              title: 'Ready to play?',
              subtitle: 'Search for a course above or create your own!',
            )
          : const _EmptyStateWidget(
              icon: Icons.search_outlined,
              title: 'No matches yet',
              subtitle: 'Try a different name or location',
            );
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: SenseiColors.gray.shade50,
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
          isAdmin: _isAdmin,
          onDelete: () => _showDeleteConfirmationDialog(hit),
        );
      },
    );
  }

  Future<void> _onLayoutSelected(
    CourseSearchHit hit,
    CourseLayoutSummary layoutSummary,
  ) async {
    _logger.track(
      'Course Layout Selected',
      properties: {
        'course_name': hit.name,
        'layout_name': layoutSummary.name,
        'hole_count': layoutSummary.holeCount,
      },
    );

    // Fetch full course from Firestore
    final Course? course = await FBCourseDataLoader.getCourseById(hit.id);
    if (course == null) {
      _logger.track('Course Load Failed', properties: {'course_id': hit.id});
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
    _logger.track(
      'Create New Layout Button Tapped',
      properties: {'course_name': hit.name},
    );

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

    _logger.track(
      'Modal Opened',
      properties: {
        'modal_type': 'full_screen_modal',
        'modal_name': 'Create Layout',
      },
    );

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
    _logger.track(
      'Edit Layout Button Tapped',
      properties: {'course_name': hit.name, 'layout_name': layoutSummary.name},
    );

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

    _logger.track(
      'Modal Opened',
      properties: {
        'modal_type': 'full_screen_modal',
        'modal_name': 'Edit Layout',
      },
    );

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
    final String eventName = isNew
        ? 'Layout Created Successfully'
        : 'Layout Updated Successfully';
    _logger.track(
      eventName,
      properties: {
        'course_name': course.name,
        'layout_name': layout.name,
        'hole_count': layout.holes.length,
      },
    );

    debugPrint(
      '[SelectCoursePanel] _handleLayoutSaved called - isNew: $isNew, '
      'course: ${course.name}, layout: ${layout.name}',
    );

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
    try {
      if (isNew) {
        debugPrint('[SelectCoursePanel] Saving new layout to Firestore...');
        await FBCourseDataLoader.addLayoutToCourse(course.id, layout);
        debugPrint(
          '[SelectCoursePanel] Successfully saved layout to Firestore',
        );
      } else {
        debugPrint('[SelectCoursePanel] Updating layout in Firestore...');
        await FBCourseDataLoader.updateLayoutInCourse(course.id, layout);
        debugPrint(
          '[SelectCoursePanel] Successfully updated layout in Firestore',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[SelectCoursePanel] Failed to save layout to Firestore: $e');
      debugPrint('[SelectCoursePanel] Stack trace: $stackTrace');
    }

    // Update shared preferences cache with the updated course
    // (search indexing is handled by backend via Firestore listeners)
    try {
      debugPrint('[SelectCoursePanel] Updating shared preferences cache...');
      await _searchService.markCourseAsUsed(updatedCourse.toCourseSearchHit());
      debugPrint('[SelectCoursePanel] Successfully updated shared preferences');
    } catch (e, stackTrace) {
      debugPrint('[SelectCoursePanel] Failed to update shared preferences: $e');
      debugPrint('[SelectCoursePanel] Stack trace: $stackTrace');
    }

    // Set the course and layout in RecordRoundCubit and pop back to main screen
    if (mounted) {
      BlocProvider.of<RecordRoundCubit>(
        context,
      ).setSelectedCourse(updatedCourse, layoutId: layout.id);
      // Pop this panel to go back to RecordRoundStepsScreen
      Navigator.pop(context);
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
          _logger.track('Create New Course Button Tapped');

          _logger.track(
            'Modal Opened',
            properties: {
              'modal_type': 'full_screen_modal',
              'modal_name': 'Create Course',
            },
          );

          // Capture cubit reference before popping (context will be invalid after pop)
          final RecordRoundCubit recordRoundCubit =
              BlocProvider.of<RecordRoundCubit>(context);

          Navigator.of(context).pop();

          pushCupertinoRoute(
            context,
            CreateCourseScreen(
              onCourseCreated: (course) {
                debugPrint(
                  '[SelectCoursePanel] New course created: ${course.name}',
                );

                // Use captured reference since context is no longer valid
                // Cache update is handled by CreateCourseCubit.saveCourse()
                // CreateCourseScreen pops itself after this callback
                recordRoundCubit.setSelectedCourse(
                  course,
                  layoutId: course.defaultLayout.id,
                );
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

  Future<void> _showDeleteConfirmationDialog(CourseSearchHit hit) async {
    _logger.track(
      'Course Delete Button Tapped',
      properties: {'course_name': hit.name},
    );

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course?'),
        content: Text(
          "Are you sure you want to delete '${hit.name}'? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteCourse(hit);
    }
  }

  Future<void> _deleteCourse(CourseSearchHit hit) async {
    _logger.track(
      'Course Delete Confirmed',
      properties: {'course_id': hit.id, 'course_name': hit.name},
    );

    try {
      await FBCourseDataLoader.deleteCourse(hit.id);

      _logger.track(
        'Course Deleted Successfully',
        properties: {'course_id': hit.id},
      );

      // Remove from local list
      if (mounted) {
        setState(() {
          _searchResults.removeWhere((result) => result.id == hit.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("'${hit.name}' deleted"),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Remove from search service cache
      await _searchService.removeCourseFromCache(hit.id);
    } catch (e, stackTrace) {
      debugPrint('[SelectCoursePanel] Failed to delete course: $e');
      debugPrint('[SelectCoursePanel] Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete course'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _CourseSearchResultItem extends StatefulWidget {
  const _CourseSearchResultItem({
    required this.hit,
    required this.onLayoutSelected,
    required this.onCreateLayout,
    required this.onEditLayout,
    required this.isAdmin,
    required this.onDelete,
  });

  final CourseSearchHit hit;
  final void Function(CourseLayoutSummary layout) onLayoutSelected;
  final VoidCallback onCreateLayout;
  final void Function(CourseLayoutSummary layout) onEditLayout;
  final bool isAdmin;
  final VoidCallback onDelete;

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
                            color: SenseiColors.gray.shade500,
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
                    color: SenseiColors.gray.shade400,
                  ),
                ),
                const SizedBox(width: 4),
                if (widget.isAdmin)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onDelete();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                if (widget.isAdmin) const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right,
                    color: SenseiColors.gray.shade400,
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
                  flattenedOverWhite(SenseiColors.blue, 0.1),
                  flattenedOverWhite(SenseiColors.blue, 0.05),
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
              border: Border.all(color: SenseiColors.gray.shade100, width: 1),
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
                          color: SenseiColors.gray.shade500,
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
                      color: SenseiColors.gray.shade400,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: SenseiColors.gray.shade400,
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
              color: SenseiColors.gray.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SenseiColors.gray.shade200,
                width: 1,
                style: BorderStyle.solid,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.add, size: 20, color: SenseiColors.gray.shade600),
                const SizedBox(width: 8),
                Text(
                  'New layout',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: SenseiColors.gray.shade600,
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

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50,
                    Colors.blue.shade100.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: Colors.blue.shade300),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: SenseiColors.gray.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                color: SenseiColors.gray.shade400,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
                style: TextButton.styleFrom(foregroundColor: SenseiColors.blue),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
