import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/services/courses/courses_service.dart';
import 'package:turbo_disc_golf/services/search/course_search_provider.dart';

/// Test implementation of [CourseSearchProvider] that returns hardcoded courses.
/// Used for testing on physical devices when MeiliSearch isn't available.
class TestCourseProvider implements CourseSearchProvider {

  @override
  Future<List<Map<String, dynamic>>> search(
    String query, {
    int limit = 25,
  }) async {
    // Simple search: filter by name containing the query (case-insensitive)
    final String lowerQuery = query.toLowerCase();

    final List<Course> filtered = kTestCourses
        .where(
          (course) =>
              course.name.toLowerCase().contains(lowerQuery) ||
              (course.city?.toLowerCase().contains(lowerQuery) ?? false) ||
              (course.state?.toLowerCase().contains(lowerQuery) ?? false),
        )
        .toList();

    // Convert to search hit format
    return filtered
        .take(limit)
        .map((course) => _courseToSearchDocument(course))
        .toList();
  }

  Map<String, dynamic> _courseToSearchDocument(Course course) {
    final CourseLayout defaultLayout = course.defaultLayout;

    return {
      'id': course.id,
      'name': course.name,
      'city': course.city,
      'state': course.state,
      'country': course.country,
      'description': course.description,
      'layouts': course.layouts
          .map((l) => {
                'id': l.id,
                'name': l.name,
                'holeCount': l.holes.length,
                'par': l.holes.fold<int>(0, (sum, hole) => sum + hole.par),
                'isDefault': l.isDefault,
                'totalFeet':
                    l.holes.fold<int>(0, (sum, hole) => sum + hole.feet),
                'description': l.description,
              })
          .toList(),
      'holeCount': defaultLayout.holes.length,
      'par': defaultLayout.holes.fold<int>(0, (sum, hole) => sum + hole.par),
    };
  }

  @override
  Future<void> indexDocument(Map<String, dynamic> doc) async {
    // No-op for test provider
  }

  @override
  Future<void> indexDocuments(List<Map<String, dynamic>> docs) async {
    // No-op for test provider
  }

  @override
  Future<void> deleteDocument(String id) async {
    // No-op for test provider
  }

  @override
  Future<void> clearIndex() async {
    // No-op for test provider
  }
}
