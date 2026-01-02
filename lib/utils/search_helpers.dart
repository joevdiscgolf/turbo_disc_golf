/// Performs a simple fuzzy match between text and query.
///
/// Returns true if all characters in [query] appear in order in [text].
/// Both strings are compared case-insensitively.
///
/// Example:
/// - fuzzyMatch('Blue Lake Disc Golf', 'bld') returns true
/// - fuzzyMatch('Riverside Park', 'rpk') returns true
/// - fuzzyMatch('Mountain View', 'vw') returns true
bool fuzzyMatch(String text, String query) {
  final String lowerText = text.toLowerCase();
  final String lowerQuery = query.toLowerCase();

  int queryIndex = 0;
  for (int i = 0; i < lowerText.length && queryIndex < lowerQuery.length; i++) {
    if (lowerText[i] == lowerQuery[queryIndex]) {
      queryIndex++;
    }
  }
  return queryIndex == lowerQuery.length;
}
