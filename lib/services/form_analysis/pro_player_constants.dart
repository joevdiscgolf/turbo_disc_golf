/// Constants for professional player references used in form analysis.
///
/// This file contains mappings and metadata for pro players whose form
/// can be used as reference comparisons.
class ProPlayerConstants {
  ProPlayerConstants._();

  /// Mapping of pro player IDs to their display names.
  ///
  /// Keys are snake_case identifiers used in storage paths and API responses.
  /// Values are the properly formatted display names.
  static const Map<String, String> proPlayerNames = {
    'paul_mcbeth': 'Paul McBeth',
    'drew_gibson': 'Drew Gibson',
  };

  /// List of pro player IDs whose references are bundled with the app.
  ///
  /// These players have their reference images included in the app assets
  /// for instant loading without network requests.
  /// NOTE: paul_mcbeth removed temporarily to force cloud storage loading for updated images
  static const List<String> bundledPlayers = [];

  /// Gets the display name for a pro player ID.
  ///
  /// Returns the formatted name if found, otherwise returns the ID
  /// with underscores replaced by spaces and title-cased.
  static String getDisplayName(String proPlayerId) {
    return proPlayerNames[proPlayerId] ?? _formatIdAsName(proPlayerId);
  }

  /// Formats a pro player ID as a display name by replacing underscores
  /// with spaces and title-casing each word.
  static String _formatIdAsName(String proPlayerId) {
    return proPlayerId
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }
}
