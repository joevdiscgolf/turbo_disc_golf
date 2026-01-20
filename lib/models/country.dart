class Country {
  const Country({
    required this.code,        // ISO 3166-1 alpha-2 (e.g., "US")
    required this.name,        // Full name (e.g., "United States")
    required this.flagEmoji,   // Unicode flag emoji (e.g., "🇺🇸")
  });

  final String code;
  final String name;
  final String flagEmoji;
}
