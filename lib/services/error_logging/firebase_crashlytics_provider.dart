import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:turbo_disc_golf/models/error/error_context.dart';
import 'package:turbo_disc_golf/models/error/error_severity.dart';
import 'package:turbo_disc_golf/protocols/error_logging_provider.dart';

/// Firebase Crashlytics implementation of ErrorLoggingProvider.
///
/// Uses Firebase Crashlytics to log errors and crashes.
/// All methods fail silently to ensure error logging never crashes the app.
class FirebaseCrashlyticsProvider implements ErrorLoggingProvider {
  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  @override
  String get providerName => 'Firebase Crashlytics';

  @override
  Future<bool> initialize() async {
    try {
      // Enable Crashlytics collection
      await _crashlytics.setCrashlyticsCollectionEnabled(true);
      return true;
    } catch (e) {
      // Fail silently - error logging initialization should never crash the app
      return false;
    }
  }

  @override
  Future<void> logError({
    required dynamic exception,
    StackTrace? stackTrace,
    ErrorSeverity severity = ErrorSeverity.error,
    ErrorContext? context,
    String? reason,
  }) async {
    try {
      // Set custom keys for context
      if (context != null) {
        final Map<String, dynamic> contextMap = context.toMap();
        for (final entry in contextMap.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }

      // Set severity as custom key
      await _crashlytics.setCustomKey('error_severity', severity.displayName);

      // Set timestamp
      await _crashlytics.setCustomKey(
        'error_timestamp',
        DateTime.now().toIso8601String(),
      );

      // Set reason if provided
      if (reason != null) {
        await _crashlytics.setCustomKey('error_reason', reason);
      }

      // Determine if this is a fatal error
      final bool fatal = severity == ErrorSeverity.fatal;

      // Record the error
      await _crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      // Fail silently - error logging should never crash the app
    }
  }

  @override
  Future<void> logMessage({
    required String message,
    ErrorSeverity severity = ErrorSeverity.info,
    ErrorContext? context,
  }) async {
    try {
      // Set custom keys for context
      if (context != null) {
        final Map<String, dynamic> contextMap = context.toMap();
        for (final entry in contextMap.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }

      // Set severity as custom key
      await _crashlytics.setCustomKey('message_severity', severity.displayName);

      // Set timestamp
      await _crashlytics.setCustomKey(
        'message_timestamp',
        DateTime.now().toIso8601String(),
      );

      // Log the message
      await _crashlytics.log(message);
    } catch (e) {
      // Fail silently - error logging should never crash the app
    }
  }

  @override
  Future<void> setUserId(String userId) async {
    try {
      await _crashlytics.setUserIdentifier(userId);
    } catch (e) {
      // Fail silently
    }
  }

  @override
  Future<void> clearUserId() async {
    try {
      await _crashlytics.setUserIdentifier('');
    } catch (e) {
      // Fail silently
    }
  }

  @override
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      await _crashlytics.setCustomKey(key, value.toString());
    } catch (e) {
      // Fail silently
    }
  }
}
