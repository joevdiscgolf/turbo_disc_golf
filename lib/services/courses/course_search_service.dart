import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/course/course_search_data.dart';
import 'package:turbo_disc_golf/services/search/course_search_provider.dart';
import 'package:turbo_disc_golf/services/shared_preferences_service.dart';

extension CourseToSearchDocument on Course {
  CourseSearchHit toCourseSearchHit() {
    return CourseSearchHit(
      id: id,
      name: name,
      city: city,
      state: state,
      layouts: layouts
          .map((CourseLayout layout) => layout.toCourseLayoutSummary())
          .toList(),
    );
  }

  Map<String, dynamic> toSearchDocument() {
    final CourseLayout defaultLayout = this.defaultLayout;

    final int holeCount = defaultLayout.holes.length;
    final int par =
        defaultLayout.holes.fold<int>(0, (sum, hole) => sum + hole.par);

    return {
      'id': id,
      'name': name,
      'city': city,
      'state': state,
      'country': country,
      'description': description,
      'layoutNames': layouts.map((l) => l.name).toList(),
      'holeCount': holeCount,
      'par': par,
    };
  }
}

extension LayoutToSummary on CourseLayout {
  CourseLayoutSummary toCourseLayoutSummary() {
    return CourseLayoutSummary(
      id: id,
      name: name,
      holeCount: holes.length,
      par: holes.fold<int>(0, (sum, hole) => sum + hole.par),
      isDefault: isDefault,
      totalFeet: holes.fold<int>(0, (sum, hole) => sum + hole.feet),
      description: description,
    );
  }
}

class CourseSearchService {
  static const String _recentKey = 'recent_courses';
  static const String _cacheKey = 'cached_courses';

  CourseSearchProvider get _provider => locator.get<CourseSearchProvider>();

  Future<List<CourseSearchHit>> searchCourses(String query) async {
    if (query.trim().length < 2) return [];

    final List<Map<String, dynamic>> hits = await _provider.search(query);

    return hits.map((e) => CourseSearchHit.fromJson(e)).toList();
  }

  Future<void> upsertCourse(Course course) async {
    await _provider.indexDocument(course.toSearchDocument());
  }

  Future<void> upsertCourses(List<Course> courses) async {
    if (courses.isEmpty) return;

    await _provider.indexDocuments(
      courses.map((c) => c.toSearchDocument()).toList(),
    );
  }

  Future<void> deleteCourse(String courseId) async {
    await _provider.deleteDocument(courseId);
  }

  Future<void> clearIndex() async {
    await _provider.clearIndex();
  }

  // ------------------
  // RECENT COURSES
  // ------------------
  Future<List<CourseSearchHit>> getRecentCourses() async {
    final List<String> recentIds = await locator
        .get<SharedPreferencesService>()
        .getStringList(_recentKey);
    final Map<String, dynamic> cache =
        await locator.get<SharedPreferencesService>().getJsonMap(
              _cacheKey,
            );

    return recentIds
        .map((id) => cache[id])
        .where((e) => e != null)
        .map((e) => CourseSearchHit.fromJson(e))
        .toList();
  }

  // ------------------
  // CALLED ON COURSE SELECTION
  // ------------------
  Future<void> markCourseAsUsed(CourseSearchHit course) async {
    final List<String> recentIds = await locator
        .get<SharedPreferencesService>()
        .getStringList(_recentKey);
    final Map<String, dynamic> cache =
        await locator.get<SharedPreferencesService>().getJsonMap(
              _cacheKey,
            );

    // Move to front
    recentIds.remove(course.id);
    recentIds.insert(0, course.id);

    // Cap at 10
    if (recentIds.length > 10) {
      recentIds.removeRange(10, recentIds.length);
    }

    cache[course.id] = course.toJson();

    await locator.get<SharedPreferencesService>().setStringList(
          _recentKey,
          recentIds,
        );
    await locator.get<SharedPreferencesService>().setJsonMap(_cacheKey, cache);
  }
}
