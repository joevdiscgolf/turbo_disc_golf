/// Abstract protocol defining the interface for analytics/logging providers.
///
/// All analytics providers (Mixpanel, Firebase, Amplitude, etc.) must implement
/// this protocol to work with the [LoggingService].
abstract class LoggingProvider {
  /// The name of this provider (e.g., "Mixpanel", "Firebase Analytics")
  String get providerName;

  /// Initialize the provider with the given project token.
  ///
  /// Returns true if initialization was successful, false otherwise.
  /// Should never throw - catch all errors internally and return false.
  ///
  /// [projectToken] - The API key/token for this analytics provider
  /// [trackAutomaticEvents] - Whether to automatically track app lifecycle events
  Future<bool> initialize({
    required String projectToken,
    bool trackAutomaticEvents = true,
  });

  /// Track an event with optional properties.
  ///
  /// Should never throw - catch all errors internally.
  /// Fire-and-forget operation that returns immediately.
  ///
  /// [eventName] - Name of the event to track
  /// [properties] - Optional key-value properties to attach to the event
  Future<void> track(
    String eventName, {
    Map<String, dynamic>? properties,
  });

  /// Identify a user by their unique ID.
  ///
  /// Associates all future events with this user ID until [reset] is called.
  /// Should never throw - catch all errors internally.
  ///
  /// [userId] - Unique identifier for the user
  Future<void> identify(String userId);

  /// Set properties on the identified user's profile.
  ///
  /// These properties persist across sessions and are associated with the user.
  /// Should never throw - catch all errors internally.
  ///
  /// [properties] - Key-value properties to set on the user profile
  Future<void> setUserProperties(Map<String, dynamic> properties);

  /// Reset the current user identity.
  ///
  /// Clears the identified user and generates a new anonymous ID.
  /// Should be called on logout.
  /// Should never throw - catch all errors internally.
  Future<void> reset();

  /// Force send any queued events to the server.
  ///
  /// Useful before logout to ensure events are not lost.
  /// Should never throw - catch all errors internally.
  Future<void> flush();

  /// Register super properties that are sent with every event.
  ///
  /// Super properties persist until explicitly cleared and are automatically
  /// included with all tracked events. Useful for properties that should be
  /// on every event (e.g., platform, user type).
  /// Should never throw - catch all errors internally.
  ///
  /// [properties] - Key-value properties to include with every event
  Future<void> registerSuperProperties(Map<String, dynamic> properties);

  /// Clear all super properties.
  ///
  /// Should be called on logout to remove user-specific super properties.
  /// Should never throw - catch all errors internally.
  Future<void> clearSuperProperties();
}
