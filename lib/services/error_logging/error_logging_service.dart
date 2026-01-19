import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/error/app_error_type.dart';
import 'package:turbo_disc_golf/models/error/error_context.dart';
import 'package:turbo_disc_golf/models/error/error_severity.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/protocols/error_logging_provider.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';

/// Centralized error logging service that broadcasts errors to multiple providers.
///
/// This service:
/// - Manages multiple error logging providers (Firebase Crashlytics, Sentry, etc.)
/// - Auto-enriches errors with user ID, timestamp, and error type
/// - Implements fire-and-forget error handling that never crashes the app
/// - Implements ClearOnLogoutProtocol for proper cleanup on user logout
class ErrorLoggingService implements ClearOnLogoutProtocol {
  ErrorLoggingService({required List<ErrorLoggingProvider> providers})
      : _providers = providers;

  final List<ErrorLoggingProvider> _providers;
  String? _currentUserId;

  /// Initialize the error logging service.
  ///
  /// This method:
  /// - Identifies the current user from AuthService if logged in
  /// - Sets the user ID on all providers
  Future<void> initialize() async {
    try {
      // Get current user ID from AuthService if available
      final AuthService authService = locator.get<AuthService>();
      final String? userId = authService.currentUid;

      if (userId != null) {
        await setUserId(userId);
      }
    } catch (e) {
      // Fail silently - initialization errors should not crash the app
    }
  }

  /// Log an error/exception with optional stack trace and context.
  ///
  /// This method:
  /// - Enriches the error with user ID, timestamp, and error type
  /// - Broadcasts to all providers in a fire-and-forget manner
  /// - Never throws - always fails silently
  ///
  /// [exception] - The exception/error object to log
  /// [stackTrace] - Optional stack trace for the error
  /// [type] - The category of error (defaults to unknown)
  /// [severity] - Severity level (defaults to error)
  /// [context] - Optional contextual metadata
  /// [reason] - Optional human-readable reason/message
  Future<void> logError({
    required dynamic exception,
    StackTrace? stackTrace,
    AppErrorType type = AppErrorType.unknown,
    ErrorSeverity severity = ErrorSeverity.error,
    ErrorContext? context,
    String? reason,
  }) async {
    try {
      // Enrich context with user ID if available
      final ErrorContext enrichedContext = _enrichContext(context);

      // Broadcast to all providers (fire-and-forget)
      for (final provider in _providers) {
        // Don't await - fire and forget
        provider
            .logError(
          exception: exception,
          stackTrace: stackTrace,
          severity: severity,
          context: enrichedContext,
          reason: reason,
        )
            .catchError((_) {
          // Silently catch any provider errors
        });

        // Set error type as custom key
        provider.setCustomKey('error_type', type.displayName).catchError((_) {
          // Silently catch any provider errors
        });
      }
    } catch (e) {
      // Fail silently - error logging should never crash the app
    }
  }

  /// Log a message without an exception.
  ///
  /// This method:
  /// - Enriches the message with user ID and timestamp
  /// - Broadcasts to all providers in a fire-and-forget manner
  /// - Never throws - always fails silently
  ///
  /// [message] - The message to log
  /// [type] - The category of message (defaults to unknown)
  /// [severity] - Severity level (defaults to info)
  /// [context] - Optional contextual metadata
  Future<void> logMessage({
    required String message,
    AppErrorType type = AppErrorType.unknown,
    ErrorSeverity severity = ErrorSeverity.info,
    ErrorContext? context,
  }) async {
    try {
      // Enrich context with user ID if available
      final ErrorContext enrichedContext = _enrichContext(context);

      // Broadcast to all providers (fire-and-forget)
      for (final provider in _providers) {
        // Don't await - fire and forget
        provider
            .logMessage(
          message: message,
          severity: severity,
          context: enrichedContext,
        )
            .catchError((_) {
          // Silently catch any provider errors
        });

        // Set message type as custom key
        provider.setCustomKey('message_type', type.displayName).catchError((_) {
          // Silently catch any provider errors
        });
      }
    } catch (e) {
      // Fail silently - error logging should never crash the app
    }
  }

  /// Set the user ID for all future errors.
  ///
  /// Associates all future errors with this user ID until [clearUserId] is called.
  ///
  /// [userId] - Unique identifier for the user
  Future<void> setUserId(String userId) async {
    try {
      _currentUserId = userId;

      // Set user ID on all providers
      for (final provider in _providers) {
        provider.setUserId(userId).catchError((_) {
          // Silently catch any provider errors
        });
      }
    } catch (e) {
      // Fail silently
    }
  }

  /// Clear the current user ID on all providers.
  ///
  /// Should be called on logout to remove user association.
  Future<void> clearUserId() async {
    try {
      _currentUserId = null;

      // Clear user ID on all providers
      for (final provider in _providers) {
        provider.clearUserId().catchError((_) {
          // Silently catch any provider errors
        });
      }
    } catch (e) {
      // Fail silently
    }
  }

  /// Set a custom key-value pair for additional context on all providers.
  ///
  /// These keys persist across errors until cleared.
  ///
  /// [key] - The key name
  /// [value] - The value (String, int, bool, double, etc.)
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      // Set custom key on all providers
      for (final provider in _providers) {
        provider.setCustomKey(key, value).catchError((_) {
          // Silently catch any provider errors
        });
      }
    } catch (e) {
      // Fail silently
    }
  }

  /// Clear all user-specific state on logout.
  ///
  /// Implements [ClearOnLogoutProtocol] to ensure proper cleanup.
  @override
  Future<void> clearOnLogout() async {
    await clearUserId();
  }

  /// Enriches the provided context with the current user ID.
  ///
  /// If context is null, creates a new context with just the user ID.
  /// If context exists but has no user ID, adds the current user ID.
  /// If context already has a user ID, leaves it unchanged.
  ErrorContext _enrichContext(ErrorContext? context) {
    if (context == null) {
      return ErrorContext(userId: _currentUserId);
    }

    // Only add user ID if not already present in context
    if (context.userId == null && _currentUserId != null) {
      return context.copyWith(userId: _currentUserId);
    }

    return context;
  }
}
