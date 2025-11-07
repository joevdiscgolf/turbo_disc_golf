import 'package:intl/intl.dart';

/// Formats an ISO 8601 date string to a readable format like "May 4, 2025"
/// Returns null if the date string is null, empty, or invalid
String? formatRoundDate(String? isoString) {
  if (isoString == null || isoString.isEmpty) {
    return null;
  }

  try {
    final DateTime dateTime = DateTime.parse(isoString);
    final DateFormat formatter = DateFormat('MMMM d, y');
    return formatter.format(dateTime);
  } catch (e) {
    return null;
  }
}

/// Formats an ISO 8601 date string to a short format like "May 4"
/// Returns null if the date string is null, empty, or invalid
String? formatRoundDateShort(String? isoString) {
  if (isoString == null || isoString.isEmpty) {
    return null;
  }

  try {
    final DateTime dateTime = DateTime.parse(isoString);
    final DateFormat formatter = DateFormat('MMM d');
    return formatter.format(dateTime);
  } catch (e) {
    return null;
  }
}

/// Gets the current date/time as an ISO 8601 string
String getCurrentISOString() {
  return DateTime.now().toIso8601String();
}
