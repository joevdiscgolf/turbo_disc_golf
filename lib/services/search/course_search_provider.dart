/// Abstract protocol for course search operations.
///
/// Implementations of this protocol handle the low-level search operations
/// (indexing, querying, deleting) while [CourseSearchService] handles
/// business logic like recent courses and caching.
///
/// To swap search providers, register a different implementation
/// in [locator.dart].
abstract class CourseSearchProvider {
  /// Search for courses matching the query.
  ///
  /// Returns a list of raw JSON hits from the search provider.
  Future<List<Map<String, dynamic>>> search(String query, {int limit = 25});

  /// Index a single course document.
  Future<void> indexDocument(Map<String, dynamic> doc);

  /// Index multiple course documents in bulk.
  Future<void> indexDocuments(List<Map<String, dynamic>> docs);

  /// Delete a course document by ID.
  Future<void> deleteDocument(String id);

  /// Clear all documents from the index.
  Future<void> clearIndex();
}
