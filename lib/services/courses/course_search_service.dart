import 'package:flutter/foundation.dart';

import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/course/course_search_data.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/services/firestore/course_data_loader.dart';
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
    final int par = defaultLayout.holes.fold<int>(
      0,
      (sum, hole) => sum + hole.par,
    );

    return {
      'id': id,
      'name': name,
      'city': city,
      'state': state,
      'country': country,
      'description': description,
      'layouts': layouts
          .map((l) => l.toCourseLayoutSummary().toJson())
          .toList(),
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

class CourseSearchService implements ClearOnLogoutProtocol {
  static const String _recentKey = 'recent_courses';
  static const String _cacheKey = 'cached_courses';

  CourseSearchProvider get _provider => locator.get<CourseSearchProvider>();

  Future<List<CourseSearchHit>> searchCourses(String query) async {
    if (query.trim().length < 2) return [];

    final List<Map<String, dynamic>> hits = await _provider.search(query);

    // Debug: log raw hits to see which have missing layouts
    for (final hit in hits) {
      debugPrint(
        '[CourseSearch] Raw hit: ${hit['name']} - layouts: ${hit['layouts']}',
      );
    }

    return hits.map((e) => CourseSearchHit.fromJson(e)).toList();
  }

  Future<void> upsertCourse(Course course) async {
    final Map<String, dynamic> doc = course.toSearchDocument();
    debugPrint(
      '[CourseSearchService] upsertCourse: ${course.name} with '
      '${course.layouts.length} layouts',
    );
    debugPrint('[CourseSearchService] Document to index: $doc');
    await _provider.indexDocument(doc);
    debugPrint('[CourseSearchService] Successfully indexed course');
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
    debugPrint('[CourseSearchService] Recent IDs: $recentIds');

    final Map<String, dynamic> cache = await locator
        .get<SharedPreferencesService>()
        .getJsonMap(_cacheKey);
    debugPrint('[CourseSearchService] Cache keys: ${cache.keys.toList()}');
    debugPrint('[CourseSearchService] Cache contents: $cache');

    final List<CourseSearchHit> results = [];
    for (final String id in recentIds) {
      final dynamic cached = cache[id];
      if (cached != null) {
        debugPrint('[CourseSearchService] Parsing cached course $id: $cached');
        try {
          results.add(CourseSearchHit.fromJson(cached as Map<String, dynamic>));
          debugPrint('[CourseSearchService] Successfully parsed course $id');
        } catch (e, stackTrace) {
          debugPrint('[CourseSearchService] Failed to parse course $id: $e');
          debugPrint('[CourseSearchService] Stack trace: $stackTrace');
        }
      } else {
        debugPrint('[CourseSearchService] Course $id not found in cache');
      }
    }

    debugPrint('[CourseSearchService] Returning ${results.length} recent courses');
    return results;
  }

  // ------------------
  // CACHE MANAGEMENT (TESTING)
  // ------------------

  /// Clears the recent courses cache from shared preferences.
  /// Useful for testing or resetting the cache.
  Future<void> clearRecentCoursesCache() async {
    debugPrint('[CourseSearchService] Clearing recent courses cache...');
    await locator.get<SharedPreferencesService>().setStringList(_recentKey, []);
    await locator.get<SharedPreferencesService>().setJsonMap(_cacheKey, {});
    debugPrint('[CourseSearchService] Cache cleared');
  }

  /// Syncs the cache from Firestore.
  /// For each course ID in the recent list, fetches the latest version from
  /// Firestore and updates the cache. Firestore is the source of truth.
  /// Returns the number of courses successfully synced.
  Future<int> syncCacheFromFirestore() async {
    debugPrint('[CourseSearchService] Syncing cache from Firestore...');

    final List<String> recentIds = await locator
        .get<SharedPreferencesService>()
        .getStringList(_recentKey);
    debugPrint('[CourseSearchService] Found ${recentIds.length} courses in cache');

    if (recentIds.isEmpty) {
      debugPrint('[CourseSearchService] No courses to sync');
      return 0;
    }

    final Map<String, dynamic> newCache = <String, dynamic>{};
    final List<String> validIds = <String>[];
    int syncedCount = 0;

    for (final String courseId in recentIds) {
      debugPrint('[CourseSearchService] Fetching course $courseId from Firestore...');
      try {
        final Course? course =
            await FBCourseDataLoader.getCourseById(courseId);
        if (course != null) {
          final CourseSearchHit hit = course.toCourseSearchHit();
          newCache[courseId] = hit.toJson();
          validIds.add(courseId);
          syncedCount++;
          debugPrint(
            '[CourseSearchService] Synced course: ${course.name} '
            'with ${course.layouts.length} layouts',
          );
        } else {
          debugPrint('[CourseSearchService] Course $courseId not found in Firestore, removing from cache');
        }
      } catch (e) {
        debugPrint('[CourseSearchService] Error fetching course $courseId: $e');
      }
    }

    // Update cache with fresh data
    await locator.get<SharedPreferencesService>().setStringList(_recentKey, validIds);
    await locator.get<SharedPreferencesService>().setJsonMap(_cacheKey, newCache);

    debugPrint('[CourseSearchService] Sync complete. Updated $syncedCount courses');
    return syncedCount;
  }

  // ------------------
  // CALLED ON COURSE SELECTION
  // ------------------
  Future<void> markCourseAsUsed(CourseSearchHit course) async {
    debugPrint('[CourseSearchService] Marking course as used: ${course.id} - ${course.name}');

    final List<String> recentIds = await locator
        .get<SharedPreferencesService>()
        .getStringList(_recentKey);
    final Map<String, dynamic> cache = await locator
        .get<SharedPreferencesService>()
        .getJsonMap(_cacheKey);

    // Move to front
    recentIds.remove(course.id);
    recentIds.insert(0, course.id);

    // Cap at 10
    if (recentIds.length > 10) {
      recentIds.removeRange(10, recentIds.length);
    }

    final Map<String, dynamic> courseJson = course.toJson();
    debugPrint('[CourseSearchService] Saving course JSON: $courseJson');
    cache[course.id] = courseJson;

    await locator.get<SharedPreferencesService>().setStringList(
      _recentKey,
      recentIds,
    );
    await locator.get<SharedPreferencesService>().setJsonMap(_cacheKey, cache);
    debugPrint('[CourseSearchService] Saved recent IDs: $recentIds');
  }

  /// Removes a course from the local cache (used after deletion).
  Future<void> removeCourseFromCache(String courseId) async {
    debugPrint('[CourseSearchService] Removing course from cache: $courseId');

    final List<String> recentIds = await locator
        .get<SharedPreferencesService>()
        .getStringList(_recentKey);
    final Map<String, dynamic> cache = await locator
        .get<SharedPreferencesService>()
        .getJsonMap(_cacheKey);

    recentIds.remove(courseId);
    cache.remove(courseId);

    await locator.get<SharedPreferencesService>().setStringList(
      _recentKey,
      recentIds,
    );
    await locator.get<SharedPreferencesService>().setJsonMap(_cacheKey, cache);
    debugPrint('[CourseSearchService] Removed course $courseId from cache');
  }

  // ------------------
  // LOGOUT PROTOCOL
  // ------------------
  @override
  Future<void> clearOnLogout() async {
    debugPrint('[CourseSearchService] Clearing cache on logout...');
    await clearRecentCoursesCache();
    debugPrint('[CourseSearchService] Cache cleared on logout');
  }
}
