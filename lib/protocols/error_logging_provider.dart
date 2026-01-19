import 'package:turbo_disc_golf/models/error/error_context.dart';
import 'package:turbo_disc_golf/models/error/error_severity.dart';

/// Abstract protocol defining the interface for error logging providers.
///
/// All error logging providers (Firebase Crashlytics, Sentry, etc.) must implement
/// this protocol to work with the [ErrorLoggingService].
abstract class ErrorLoggingProvider {
  /// The name of this provider (e.g., "Firebase Crashlytics", "Sentry")
  String get providerName;

  /// Initialize the provider.
  ///
  /// Returns true if initialization was successful, false otherwise.
  /// Should never throw - catch all errors internally and return false.
  Future<bool> initialize();

  /// Log an error/exception with optional stack trace and context.
  ///
  /// Should never throw - catch all errors internally.
  /// Fire-and-forget operation that returns immediately.
  ///
  /// [exception] - The exception/error object to log
  /// [stackTrace] - Optional stack trace for the error
  /// [severity] - Severity level (defaults to error)
  /// [context] - Optional contextual metadata
  /// [reason] - Optional human-readable reason/message
  Future<void> logError({
    required dynamic exception,
    StackTrace? stackTrace,
    ErrorSeverity severity = ErrorSeverity.error,
    ErrorContext? context,
    String? reason,
  });

  /// Log a message without an exception.
  ///
  /// Should never throw - catch all errors internally.
  /// Fire-and-forget operation that returns immediately.
  ///
  /// [message] - The message to log
  /// [severity] - Severity level (defaults to info)
  /// [context] - Optional contextual metadata
  Future<void> logMessage({
    required String message,
    ErrorSeverity severity = ErrorSeverity.info,
    ErrorContext? context,
  });

  /// Set the user ID for all future errors.
  ///
  /// Associates all future errors with this user ID until [clearUserId] is called.
  /// Should never throw - catch all errors internally.
  ///
  /// [userId] - Unique identifier for the user
  Future<void> setUserId(String userId);

  /// Clear the current user ID.
  ///
  /// Should be called on logout to remove user association.
  /// Should never throw - catch all errors internally.
  Future<void> clearUserId();

  /// Set a custom key-value pair for additional context.
  ///
  /// These keys persist across errors until cleared.
  /// Should never throw - catch all errors internally.
  ///
  /// [key] - The key name
  /// [value] - The value (String, int, bool, double, etc.)
  Future<void> setCustomKey(String key, dynamic value);
}
