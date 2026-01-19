/// Context metadata that can be attached to errors for better debugging
class ErrorContext {
  const ErrorContext({
    this.userId,
    this.screenName,
    this.roundId,
    this.courseId,
    this.holeNumber,
    this.customData,
  });

  /// User ID (auto-enriched by ErrorLoggingService)
  final String? userId;

  /// Name of the screen where the error occurred
  final String? screenName;

  /// ID of the round being processed when error occurred
  final String? roundId;

  /// ID of the course being used when error occurred
  final String? courseId;

  /// Hole number being processed when error occurred
  final int? holeNumber;

  /// Custom key-value pairs for additional context
  final Map<String, dynamic>? customData;

  /// Convert context to a map for logging
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {};

    if (userId != null) map['user_id'] = userId;
    if (screenName != null) map['screen_name'] = screenName;
    if (roundId != null) map['round_id'] = roundId;
    if (courseId != null) map['course_id'] = courseId;
    if (holeNumber != null) map['hole_number'] = holeNumber;
    if (customData != null) {
      map.addAll(customData!);
    }

    return map;
  }

  /// Create a copy of this context with optional field overrides
  ErrorContext copyWith({
    String? userId,
    String? screenName,
    String? roundId,
    String? courseId,
    int? holeNumber,
    Map<String, dynamic>? customData,
  }) {
    return ErrorContext(
      userId: userId ?? this.userId,
      screenName: screenName ?? this.screenName,
      roundId: roundId ?? this.roundId,
      courseId: courseId ?? this.courseId,
      holeNumber: holeNumber ?? this.holeNumber,
      customData: customData ?? this.customData,
    );
  }
}
