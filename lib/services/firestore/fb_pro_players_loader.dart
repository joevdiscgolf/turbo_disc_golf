import 'package:flutter/foundation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pro_player_models.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_constants.dart';
import 'package:turbo_disc_golf/utils/firebase/firebase_utils.dart';

/// Loads pro player configuration from Firestore.
/// Data is fetched once and cached for the app session.
abstract class FBProPlayersLoader {
  static ProPlayersConfig? _cachedConfig;

  /// Track if a fetch is currently in progress to avoid duplicate requests
  static Future<ProPlayersConfig?>? _pendingFetch;

  /// Default retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialBackoff = Duration(milliseconds: 500);

  /// Fetch pro players config from Firestore (cached after first call).
  ///
  /// Includes automatic retry with exponential backoff on failure.
  /// Set [forceRefresh] to true to bypass cache and fetch fresh data.
  /// Set [withRetry] to false to disable automatic retries (e.g., for startup).
  static Future<ProPlayersConfig?> getProPlayersConfig({
    bool forceRefresh = false,
    bool withRetry = true,
  }) async {
    if (_cachedConfig != null && !forceRefresh) {
      return _cachedConfig;
    }

    // If a fetch is already in progress, wait for it instead of starting another
    if (_pendingFetch != null && !forceRefresh) {
      return _pendingFetch;
    }

    _pendingFetch = _fetchWithRetry(withRetry: withRetry);
    final ProPlayersConfig? result = await _pendingFetch;
    _pendingFetch = null;
    return result;
  }

  /// Internal method that handles fetching with exponential backoff retry
  static Future<ProPlayersConfig?> _fetchWithRetry({
    bool withRetry = true,
  }) async {
    final int maxAttempts = withRetry ? _maxRetries : 1;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final snapshot = await firestoreFetch(
          '$kAppConfigCollection/$kProPlayersDoc',
        );

        if (snapshot == null || !snapshot.exists || snapshot.data() == null) {
          debugPrint('[FBProPlayersLoader] Pro players config not found');
          return null;
        }

        // print('raw data: ');
        // // INSERT_YOUR_CODE
        // // Print the full snapshot data map to avoid truncation
        // final data = snapshot.data()!;
        // const chunkSize = 1000;
        // final String dataStr = data.toString();
        // for (int i = 0; i < dataStr.length; i += chunkSize) {
        //   final end = (i + chunkSize < dataStr.length)
        //       ? i + chunkSize
        //       : dataStr.length;
        //   print(dataStr.substring(i, end));
        // }

        _cachedConfig = ProPlayersConfig.fromJson(snapshot.data()!);
        return _cachedConfig;
      } catch (e, trace) {
        debugPrint(
          '[FBProPlayersLoader] Error fetching pro players (attempt $attempt/$maxAttempts): $e',
        );
        debugPrint('Trace: ${trace.toString()}');

        if (attempt < maxAttempts) {
          // Exponential backoff: 500ms, 1000ms, 2000ms...
          final Duration backoff = _initialBackoff * (1 << (attempt - 1));
          debugPrint(
            '[FBProPlayersLoader] Retrying in ${backoff.inMilliseconds}ms...',
          );
          await Future<void>.delayed(backoff);
        }
      }
    }

    debugPrint('[FBProPlayersLoader] All retry attempts exhausted');
    return null;
  }

  /// Get metadata for a specific pro player
  static Future<ProPlayerMetadata?> getProPlayer(String proPlayerId) async {
    final config = await getProPlayersConfig();
    return config?.pros[proPlayerId];
  }

  /// Get list of active pro players
  static Future<List<ProPlayerMetadata>> getActivePros() async {
    final config = await getProPlayersConfig();
    if (config == null) return [];
    return config.pros.values.where((pro) => pro.isActive ?? true).toList();
  }

  /// Clear cache (useful for refresh)
  static void clearCache() {
    _cachedConfig = null;
  }
}
