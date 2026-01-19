import 'package:flutter/foundation.dart';

import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/protocols/logging_provider.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';

/// Main logging service that orchestrates multiple analytics providers.
///
/// This service:
/// - Manages one or more [LoggingProvider] implementations (Mixpanel, Firebase, etc.)
/// - Automatically enriches events with user context (user_id, timestamp)
/// - Auto-identifies users from [AuthService] on initialization
/// - Implements [ClearOnLogoutProtocol] to clear state on logout
/// - Provides graceful error handling (never crashes the app)
///
/// Usage:
/// ```dart
/// // Track a simple event
/// locator.get<LoggingService>().track('Round Created');
///
/// // Track with properties
/// locator.get<LoggingService>().track('Round Created', properties: {
///   'course_name': 'Blue Lake Park',
///   'holes': 18,
/// });
///
/// // Set user properties
/// locator.get<LoggingService>().setUserProperties({
///   'name': 'John Doe',
///   'email': 'john@example.com',
/// });
/// ```
class LoggingService implements ClearOnLogoutProtocol {
  /// List of analytics providers to broadcast events to
  final List<LoggingProvider> _providers;

  /// The currently identified user ID (cached for event enrichment)
  String? _currentUserId;

  LoggingService({required List<LoggingProvider> providers})
      : _providers = providers;

  /// Initialize all providers and auto-identify the current user.
  ///
  /// This should be called once during app startup after all dependencies
  /// are registered in the service locator.
  Future<void> initialize() async {
    debugPrint('[LoggingService] Initializing with ${_providers.length} provider(s)...');

    // Providers are already initialized in locator.dart before being passed here
    // Just need to auto-identify the current user

    await _autoIdentifyUser();

    debugPrint('[LoggingService] Initialization complete');
  }

  /// Automatically identify the current user from [AuthService].
  ///
  /// Called during initialization and should be called again after login.
  Future<void> _autoIdentifyUser() async {
    try {
      final AuthService authService = locator.get<AuthService>();
      final String? userId = authService.currentUid;

      if (userId != null && userId.isNotEmpty) {
        await identify(userId);
      } else {
        debugPrint('[LoggingService] No user logged in - skipping auto-identify');
      }
    } catch (e) {
      debugPrint('[LoggingService] Failed to auto-identify user: $e');
    }
  }

  /// Track an event across all providers.
  ///
  /// Automatically enriches the event with:
  /// - `user_id` (if a user is identified)
  /// - `timestamp` (ISO8601 format)
  ///
  /// Example:
  /// ```dart
  /// loggingService.track('Button Clicked', properties: {
  ///   'button_name': 'Submit',
  ///   'screen': 'Create Round',
  /// });
  /// ```
  Future<void> track(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    try {
      // Create enriched properties map
      final Map<String, dynamic> enrichedProperties = {
        ...?properties,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Add user_id if available
      if (_currentUserId != null) {
        enrichedProperties['user_id'] = _currentUserId;
      }

      debugPrint('[LoggingService] Tracking: $eventName');

      // Broadcast to all providers (fire-and-forget)
      for (final LoggingProvider provider in _providers) {
        provider
            .track(eventName, properties: enrichedProperties)
            .catchError((dynamic error) {
          debugPrint(
            '[LoggingService] ${provider.providerName} failed to track "$eventName": $error',
          );
        });
      }
    } catch (e) {
      debugPrint('[LoggingService] Failed to track event "$eventName": $e');
    }
  }

  /// Identify a user across all providers.
  ///
  /// Associates all future events with this user ID until [clearOnLogout] is called.
  ///
  /// Example:
  /// ```dart
  /// loggingService.identify('user_12345');
  /// ```
  Future<void> identify(String userId) async {
    try {
      _currentUserId = userId;
      debugPrint('[LoggingService] Identifying user: $userId');

      // Broadcast to all providers (fire-and-forget)
      for (final LoggingProvider provider in _providers) {
        provider.identify(userId).catchError((dynamic error) {
          debugPrint(
            '[LoggingService] ${provider.providerName} failed to identify user: $error',
          );
        });
      }
    } catch (e) {
      debugPrint('[LoggingService] Failed to identify user: $e');
    }
  }

  /// Set user properties across all providers.
  ///
  /// These properties persist across sessions and are associated with the user profile.
  ///
  /// Example:
  /// ```dart
  /// loggingService.setUserProperties({
  ///   'name': 'John Doe',
  ///   'email': 'john@example.com',
  ///   'pdga_number': '12345',
  /// });
  /// ```
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    try {
      debugPrint('[LoggingService] Setting user properties: ${properties.keys.join(", ")}');

      // Broadcast to all providers (fire-and-forget)
      for (final LoggingProvider provider in _providers) {
        provider.setUserProperties(properties).catchError((dynamic error) {
          debugPrint(
            '[LoggingService] ${provider.providerName} failed to set user properties: $error',
          );
        });
      }
    } catch (e) {
      debugPrint('[LoggingService] Failed to set user properties: $e');
    }
  }

  /// Force send any queued events to the server across all providers.
  ///
  /// Useful before logout to ensure events are not lost.
  Future<void> flush() async {
    try {
      debugPrint('[LoggingService] Flushing queued events...');

      // Wait for all providers to flush
      await Future.wait(
        _providers.map((LoggingProvider provider) {
          return provider.flush().catchError((dynamic error) {
            debugPrint(
              '[LoggingService] ${provider.providerName} failed to flush: $error',
            );
          });
        }),
      );

      debugPrint('[LoggingService] Flush complete');
    } catch (e) {
      debugPrint('[LoggingService] Failed to flush: $e');
    }
  }

  /// Implementation of [ClearOnLogoutProtocol].
  ///
  /// Called automatically by [LogoutManager] when the user logs out.
  /// Flushes queued events, resets all providers, and clears the cached user ID.
  @override
  Future<void> clearOnLogout() async {
    try {
      debugPrint('[LoggingService] Clearing on logout...');

      // First, flush any pending events to ensure they're sent
      await flush();

      // Reset all providers (clears user identity and generates new anonymous ID)
      for (final LoggingProvider provider in _providers) {
        await provider.reset().catchError((dynamic error) {
          debugPrint(
            '[LoggingService] ${provider.providerName} failed to reset: $error',
          );
        });
      }

      // Clear cached user ID
      _currentUserId = null;

      debugPrint('[LoggingService] Logout cleanup complete');
    } catch (e) {
      debugPrint('[LoggingService] Failed to clear on logout: $e');
    }
  }
}
