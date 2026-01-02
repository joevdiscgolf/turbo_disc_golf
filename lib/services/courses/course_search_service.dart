// lib/services/course_search_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course_data.dart';
import 'package:turbo_disc_golf/services/shared_preferences_service.dart';

class CourseSearchHit {
  final String id;
  final String name;
  final String? city;
  final String? state;

  CourseSearchHit({
    required this.id,
    required this.name,
    this.city,
    this.state,
  });

  factory CourseSearchHit.fromJson(Map<String, dynamic> json) {
    return CourseSearchHit(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String?,
      state: json['state'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'city': city, 'state': state};
  }
}

extension CourseToSearchDocument on Course {
  CourseSearchHit toCourseSearchHit() {
    return CourseSearchHit(id: id, name: name, city: city, state: state);
  }

  Map<String, dynamic> toSearchDocument() {
    final defaultLayout = this.defaultLayout;

    final holeCount = defaultLayout.holes.length;
    final par = defaultLayout.holes.fold<int>(0, (sum, hole) => sum + hole.par);

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

class CourseSearchService {
  static const String _baseUrl = 'http://localhost:7700';
  static const String _index = 'courses';

  static const String _recentKey = 'recent_courses';
  static const String _cacheKey = 'cached_courses';

  Future<List<CourseSearchHit>> searchCourses(String query) async {
    if (query.trim().length < 2) return [];

    final response = await http.post(
      Uri.parse('$_baseUrl/indexes/$_index/search'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'q': query, 'limit': 25}),
    );

    if (response.statusCode != 200) {
      throw Exception('Meilisearch query failed');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final hits = decoded['hits'] as List<dynamic>;

    return hits
        .map((e) => CourseSearchHit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertCourse(Course course) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/indexes/$_index/documents'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode([course.toSearchDocument()]),
    );

    if (response.statusCode != 202) {
      throw Exception('Failed to index course ${course.id}');
    }
  }

  Future<void> upsertCourses(List<Course> courses) async {
    if (courses.isEmpty) return;

    final response = await http.post(
      Uri.parse('$_baseUrl/indexes/$_index/documents'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(courses.map((c) => c.toSearchDocument()).toList()),
    );

    if (response.statusCode != 202) {
      throw Exception('Failed to bulk index courses');
    }
  }

  Future<void> deleteCourse(String courseId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/indexes/$_index/documents/$courseId'),
    );

    if (response.statusCode != 202) {
      throw Exception('Failed to delete course $courseId');
    }
  }

  Future<void> clearIndex() async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/indexes/$_index/documents'),
    );

    if (response.statusCode != 202) {
      throw Exception('Failed to clear index');
    }
  }

  // ------------------
  // RECENT COURSES
  // ------------------
  Future<List<CourseSearchHit>> getRecentCourses() async {
    final recentIds = await locator
        .get<SharedPreferencesService>()
        .getStringList(_recentKey);
    final cache = await locator.get<SharedPreferencesService>().getJsonMap(
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
    final recentIds = await locator
        .get<SharedPreferencesService>()
        .getStringList(_recentKey);
    final cache = await locator.get<SharedPreferencesService>().getJsonMap(
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
