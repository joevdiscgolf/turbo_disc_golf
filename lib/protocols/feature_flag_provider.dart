import 'package:turbo_disc_golf/models/feature_flags/feature_flag.dart';

/// Abstract protocol defining the interface for feature flag providers.
///
/// All feature flag providers (Firebase Remote Config, LaunchDarkly, etc.)
/// must implement this protocol to work with the [FeatureFlagService].
abstract class FeatureFlagProvider {
  /// The name of this provider (e.g., "Firebase Remote Config")
  String get providerName;

  /// Initialize the provider and fetch initial values.
  ///
  /// Returns true if initialization was successful, false otherwise.
  /// Should never throw - catch all errors internally and return false.
  Future<bool> initialize();

  /// Fetch the latest values from the remote config server.
  ///
  /// Returns true if fetch was successful, false otherwise.
  /// Should never throw - catch all errors internally and return false.
  Future<bool> fetchAndActivate();

  /// Get a boolean value for the given flag.
  ///
  /// Returns the remote value if available, otherwise the flag's default value.
  bool getBool(FeatureFlag flag);

  /// Get a string value for the given flag.
  ///
  /// Returns the remote value if available, otherwise the flag's default value.
  String getString(FeatureFlag flag);

  /// Get an integer value for the given flag.
  ///
  /// Returns the remote value if available, otherwise the flag's default value.
  int getInt(FeatureFlag flag);

  /// Get a double value for the given flag.
  ///
  /// Returns the remote value if available, otherwise the flag's default value.
  double getDouble(FeatureFlag flag);

  /// Get all flag values as a map for debugging/logging.
  Map<String, dynamic> getAllValues();

  /// Get the last fetch time, or null if never fetched.
  DateTime? get lastFetchTime;

  /// Whether the provider has successfully fetched remote values at least once.
  bool get hasFetchedRemoteValues;
}
