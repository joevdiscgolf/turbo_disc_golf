import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/models/data/course_data.dart';
import 'package:turbo_disc_golf/screens/courses/create_course_sheet.dart';
import 'package:turbo_disc_golf/state/record_round_cubit.dart';
import 'package:turbo_disc_golf/state/record_round_state.dart';
import 'package:turbo_disc_golf/utils/panel_helpers.dart';
import 'package:turbo_disc_golf/utils/search_helpers.dart';

class SelectCoursePanel extends StatefulWidget {
  const SelectCoursePanel({super.key});

  @override
  State<SelectCoursePanel> createState() => _SelectCoursePanelState();
}

class _SelectCoursePanelState extends State<SelectCoursePanel> {
  static const Color _courseAccent = Color(0xFF2196F3); // blue
  static const Color _createAccent = Color(0xFF9D4EDD); // purple-ish

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Course> _filterCourses(List<Course> courses) {
    if (_searchQuery.isEmpty) {
      return courses;
    }

    return courses.where((course) {
      return fuzzyMatch(course.name, _searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordRoundCubit, RecordRoundState>(
      builder: (context, recordRoundState) {
        if (recordRoundState is! RecordRoundActive) return const SizedBox();

        final List<Course> courses = BlocProvider.of<RecordRoundCubit>(
          context,
        ).courses;

        final List<Course> filteredCourses = _filterCourses(courses);

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Course',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search courses...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredCourses.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index < filteredCourses.length) {
                          final Course course = filteredCourses[index];
                          final bool selected =
                              course.id == recordRoundState.selectedCourse?.id;

                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            tileColor: selected
                                ? _courseAccent.withValues(alpha: 0.08)
                                : null,
                            leading: Icon(
                              Icons.landscape,
                              color: selected ? _courseAccent : Colors.black87,
                            ),
                            title: Text(
                              course.name,
                              style: selected
                                  ? const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _courseAccent,
                                    )
                                  : null,
                            ),
                            trailing: selected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: _courseAccent,
                                  )
                                : null,
                            onTap: () {
                              BlocProvider.of<RecordRoundCubit>(
                                context,
                              ).setSelectedCourse(course);
                              Navigator.pop(context);
                            },
                          );
                        } else {
                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            tileColor: _createAccent.withValues(alpha: 0.08),
                            leading: const Icon(
                              Icons.add_circle_outline,
                              color: _createAccent,
                            ),
                            title: const Text(
                              'Create new course',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              displayBottomSheet(
                                context,
                                CreateCourseSheet(
                                  onCourseCreated: (course) {
                                    BlocProvider.of<RecordRoundCubit>(
                                      context,
                                    ).courses.add(course);
                                    BlocProvider.of<RecordRoundCubit>(
                                      context,
                                    ).setSelectedCourse(course);

                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
