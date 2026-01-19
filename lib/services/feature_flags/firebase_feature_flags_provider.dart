import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:turbo_disc_golf/models/feature_flags/feature_flag.dart';
import 'package:turbo_disc_golf/protocols/feature_flag_provider.dart';

/// Firebase Remote Config implementation of [FeatureFlagProvider].
///
/// Fetches feature flag values from Firebase Remote Config and caches them
/// locally for offline access.
class FirebaseFeatureFlagsProvider implements FeatureFlagProvider {
  FirebaseRemoteConfig? _remoteConfig;
  DateTime? _lastFetchTime;
  bool _hasFetchedRemoteValues = false;

  @override
  String get providerName => 'Firebase Remote Config';

  @override
  DateTime? get lastFetchTime => _lastFetchTime;

  @override
  bool get hasFetchedRemoteValues => _hasFetchedRemoteValues;

  @override
  Future<bool> initialize() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Configure fetch settings
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // In debug mode, allow frequent fetches. In release, cache for 1 hour.
          minimumFetchInterval:
              kDebugMode ? const Duration(seconds: 10) : const Duration(hours: 1),
        ),
      );

      // Set default values from FeatureFlag enum
      final Map<String, dynamic> defaults = {};
      for (final FeatureFlag flag in FeatureFlag.values) {
        defaults[flag.remoteKey] = flag.defaultValue;
      }
      await _remoteConfig!.setDefaults(defaults);

      debugPrint(
        '[FirebaseFeatureFlagsProvider] Initialized with ${defaults.length} default values',
      );

      // Fetch and activate initial values
      final bool fetchSuccess = await fetchAndActivate();
      debugPrint(
        '[FirebaseFeatureFlagsProvider] Initial fetch ${fetchSuccess ? 'succeeded' : 'failed'}',
      );

      return true;
    } catch (e) {
      debugPrint('[FirebaseFeatureFlagsProvider] Initialize failed: $e');
      return false;
    }
  }

  @override
  Future<bool> fetchAndActivate() async {
    try {
      if (_remoteConfig == null) {
        debugPrint(
          '[FirebaseFeatureFlagsProvider] Cannot fetch - not initialized',
        );
        return false;
      }

      final bool activated = await _remoteConfig!.fetchAndActivate();
      _lastFetchTime = DateTime.now();
      _hasFetchedRemoteValues = true;

      debugPrint(
        '[FirebaseFeatureFlagsProvider] Fetch completed, activated=$activated',
      );

      return true;
    } catch (e) {
      debugPrint('[FirebaseFeatureFlagsProvider] Fetch failed: $e');
      return false;
    }
  }

  @override
  bool getBool(FeatureFlag flag) {
    if (_remoteConfig == null) {
      return flag.defaultValue as bool;
    }
    return _remoteConfig!.getBool(flag.remoteKey);
  }

  @override
  String getString(FeatureFlag flag) {
    if (_remoteConfig == null) {
      return flag.defaultValue as String;
    }
    return _remoteConfig!.getString(flag.remoteKey);
  }

  @override
  int getInt(FeatureFlag flag) {
    if (_remoteConfig == null) {
      return flag.defaultValue as int;
    }
    return _remoteConfig!.getInt(flag.remoteKey);
  }

  @override
  double getDouble(FeatureFlag flag) {
    if (_remoteConfig == null) {
      return flag.defaultValue as double;
    }
    return _remoteConfig!.getDouble(flag.remoteKey);
  }

  @override
  Map<String, dynamic> getAllValues() {
    final Map<String, dynamic> values = {};
    for (final FeatureFlag flag in FeatureFlag.values) {
      final dynamic defaultValue = flag.defaultValue;
      if (defaultValue is bool) {
        values[flag.remoteKey] = getBool(flag);
      } else if (defaultValue is String) {
        values[flag.remoteKey] = getString(flag);
      } else if (defaultValue is int) {
        values[flag.remoteKey] = getInt(flag);
      } else if (defaultValue is double) {
        values[flag.remoteKey] = getDouble(flag);
      } else {
        values[flag.remoteKey] = defaultValue;
      }
    }
    return values;
  }
}
