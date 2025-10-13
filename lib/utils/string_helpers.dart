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
