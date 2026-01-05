import 'package:intl/intl.dart';

int versionToNumber(String version) {
  final withoutDots = version.replaceAll(RegExp('\\.'), ''); // abc
  return int.parse(withoutDots);
}

String getEnumValuesAsString<T>(List<T> values) {
  return values
      .map((e) {
        final str = e.toString().split('.').last;
        // Convert camelCase to snake_case for JSON values
        // Special handling for names with numbers like circle1 -> circle_1
        String snakeCase = str
            .replaceAllMapped(
              RegExp(r'([a-z])([0-9])'), // lowercase letter followed by number
              (Match m) => '${m[1]}_${m[2]}',
            )
            .replaceAllMapped(
              RegExp(r'[A-Z]'),
              (Match m) => '_${m[0]!.toLowerCase()}',
            )
            .replaceAll(RegExp(r'^_'), '');
        return snakeCase;
      })
      .join(', ');
}

List<String> getPrefixes(String str) {
  final String lowerCase = str.toLowerCase();
  final List<String> result = <String>[];

  if (lowerCase.isEmpty) {
    return result;
  }

  for (int i = 1; i <= lowerCase.length; i++) {
    result.add(lowerCase.substring(0, i));
  }
  return result;
}

String getMessageFromDifference(int difference) {
  if (difference > 0) {
    return 'Victory';
  } else if (difference < 0) {
    return 'Defeat';
  } else {
    return 'Draw';
  }
}

String timestampToDate(int timestamp) {
  return '${DateFormat.yMMMMd('en_US').format(DateTime.fromMillisecondsSinceEpoch(timestamp)).toString()}, ${DateFormat.jm().format(DateTime.fromMillisecondsSinceEpoch(timestamp)).toString()}';
}

extension CapitalizeFirstExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
