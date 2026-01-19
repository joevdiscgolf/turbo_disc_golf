/// Enum representing the severity level of an error or log message
enum ErrorSeverity {
  /// Informational message - lowest priority
  info,

  /// Warning message - potential issue but not critical
  warning,

  /// Error message - something went wrong but app can continue
  error,

  /// Fatal error - critical issue that may crash the app
  fatal;

  /// Get a human-readable display name for the severity level
  String get displayName {
    switch (this) {
      case ErrorSeverity.info:
        return 'Info';
      case ErrorSeverity.warning:
        return 'Warning';
      case ErrorSeverity.error:
        return 'Error';
      case ErrorSeverity.fatal:
        return 'Fatal';
    }
  }
}
