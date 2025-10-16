import 'package:turbo_disc_golf/models/data/ai_content_data.dart';

/// Parser for AI responses that contain stat card markers
class AIResponseParser {
  // Regex to match stat card markers like [STAT_CARD:PUTTING_SUMMARY] or [stat_card:c1_putting]
  // Case-insensitive to handle AI variations in capitalization
  static final RegExp _statCardPattern = RegExp(
    r'\[STAT_CARD:([A-Za-z_0-9]+)(?::([^\]]+))?\]',
    multiLine: true,
    caseSensitive: false,
  );

  /// Parse an AI response string into segments (markdown + stat cards)
  ///
  /// Markers format:
  /// - Simple: [STAT_CARD:PUTTING_SUMMARY]
  /// - With params: [STAT_CARD:PUTTING_DISTANCE:range=20-30,highlight=true]
  ///
  /// Returns list of AIContentSegment objects
  static List<AIContentSegment> parse(String aiResponse) {
    final List<AIContentSegment> segments = [];

    // If no stat card markers found, return entire content as one markdown segment
    if (!_statCardPattern.hasMatch(aiResponse)) {
      return [
        AIContentSegment(
          type: AISegmentType.markdown,
          content: aiResponse.trim(),
        ),
      ];
    }

    int lastEndIndex = 0;
    final matches = _statCardPattern.allMatches(aiResponse);

    for (final match in matches) {
      // Extract markdown text before this stat card
      if (match.start > lastEndIndex) {
        final markdownText = aiResponse.substring(lastEndIndex, match.start).trim();
        if (markdownText.isNotEmpty) {
          segments.add(
            AIContentSegment(
              type: AISegmentType.markdown,
              content: markdownText,
            ),
          );
        }
      }

      // Extract stat card ID and parameters
      final cardId = match.group(1)!; // e.g., "PUTTING_SUMMARY"
      final paramsString = match.group(2); // e.g., "range=20-30,highlight=true"

      Map<String, dynamic>? params;
      if (paramsString != null && paramsString.isNotEmpty) {
        params = _parseParams(paramsString);
      }

      // Add stat card segment
      segments.add(
        AIContentSegment(
          type: AISegmentType.statCard,
          content: cardId,
          params: params,
        ),
      );

      lastEndIndex = match.end;
    }

    // Add remaining markdown text after last stat card
    if (lastEndIndex < aiResponse.length) {
      final markdownText = aiResponse.substring(lastEndIndex).trim();
      if (markdownText.isNotEmpty) {
        segments.add(
          AIContentSegment(
            type: AISegmentType.markdown,
            content: markdownText,
          ),
        );
      }
    }

    return segments;
  }

  /// Parse parameter string like "range=20-30,highlight=true" into a Map
  static Map<String, dynamic> _parseParams(String paramsString) {
    final Map<String, dynamic> params = {};
    final pairs = paramsString.split(',');

    for (final pair in pairs) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim();

        // Try to parse as number
        final numValue = num.tryParse(value);
        if (numValue != null) {
          params[key] = numValue;
        }
        // Try to parse as boolean
        else if (value.toLowerCase() == 'true') {
          params[key] = true;
        } else if (value.toLowerCase() == 'false') {
          params[key] = false;
        }
        // Default to string
        else {
          params[key] = value;
        }
      }
    }

    return params;
  }

  /// Helper to check if a response contains any stat card markers
  static bool containsStatCards(String aiResponse) {
    return _statCardPattern.hasMatch(aiResponse);
  }

  /// Helper to extract all stat card IDs from a response (useful for debugging)
  static List<String> extractStatCardIds(String aiResponse) {
    final matches = _statCardPattern.allMatches(aiResponse);
    return matches.map((match) => match.group(1)!).toList();
  }
}
