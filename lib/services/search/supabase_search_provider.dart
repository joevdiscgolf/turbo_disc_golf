import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:turbo_disc_golf/services/search/course_search_provider.dart';

/// Supabase implementation of [CourseSearchProvider].
///
/// Uses Supabase's full-text search capabilities on the course_search table.
/// Requires Supabase to be initialized before use.
class SupabaseSearchProvider implements CourseSearchProvider {
  static const String _tableName = 'courses_search';

  /// Valid columns in the courses_search table
  static const List<String> _validColumns = [
    'id',
    'name',
    'city',
    'state',
    'country',
    'aliases',
    'lat',
    'lng',
    'layouts', // stored as jsonb
  ];

  SupabaseClient get _client => Supabase.instance.client;

  /// Filters a document to only include valid columns for the courses_search table.
  /// Also maps common field name variations (latitude -> lat, longitude -> lng).
  Map<String, dynamic> _toSupabaseRow(Map<String, dynamic> doc) {
    final Map<String, dynamic> row = <String, dynamic>{};

    for (final String column in _validColumns) {
      if (doc.containsKey(column)) {
        row[column] = doc[column];
      }
    }

    // Map common field name variations
    if (!row.containsKey('lat') && doc.containsKey('latitude')) {
      row['lat'] = doc['latitude'];
    }
    if (!row.containsKey('lng') && doc.containsKey('longitude')) {
      row['lng'] = doc['longitude'];
    }

    return row;
  }

  @override
  Future<List<Map<String, dynamic>>> search(
    String query, {
    int limit = 25,
  }) async {
    final q = query.trim();
    if (q.length < 2) return []; // avoid noisy results on 0–1 chars

    final res = await _client.rpc(
      'search_courses',
      params: {'q': q, 'lim': limit},
    );

    return (res as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> indexDocument(Map<String, dynamic> doc) async {
    final Map<String, dynamic> row = _toSupabaseRow(doc);
    await _client.from(_tableName).upsert(row, onConflict: 'id');
  }

  @override
  Future<void> indexDocuments(List<Map<String, dynamic>> docs) async {
    if (docs.isEmpty) return;

    final List<Map<String, dynamic>> rows = docs
        .map((doc) => _toSupabaseRow(doc))
        .toList();
    await _client.from(_tableName).upsert(rows, onConflict: 'id');
  }

  @override
  Future<void> deleteDocument(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

  @override
  Future<void> clearIndex() async {
    // Delete all rows from the table
    // Using a condition that matches all rows
    await _client.from(_tableName).delete().neq('id', '');
  }

  /// Test function to upsert a list of courses to the course_search table.
  ///
  /// Takes a list of course maps and upserts them to Supabase.
  /// Each course map should contain at minimum an 'id' field.
  ///
  /// Example usage:
  /// ```dart
  /// final provider = SupabaseSearchProvider();
  /// await provider.upsertCoursesForTesting([
  ///   {'id': '1', 'name': 'Maple Hill', 'city': 'Leicester', 'state': 'MA'},
  ///   {'id': '2', 'name': 'Blue Ribbon Pines', 'city': 'East Bethel', 'state': 'MN'},
  /// ]);
  /// ```
  Future<void> upsertCoursesForTesting(
    List<Map<String, dynamic>> courses,
  ) async {
    if (courses.isEmpty) return;

    final List<Map<String, dynamic>> rows = courses
        .map((course) => _toSupabaseRow(course))
        .toList();
    await _client.from(_tableName).upsert(rows, onConflict: 'id');
  }
}
