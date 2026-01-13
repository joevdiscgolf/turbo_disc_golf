import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Service for loading professional player reference images using a three-tier strategy:
/// 1. Bundled assets (fastest - for Paul McBeth)
/// 2. Local cache (fast - for previously downloaded players)
/// 3. Central cloud storage (one-time download - for new players)
class ProReferenceLoader {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// List of players whose references are bundled with the app
  static const List<String> _bundledPlayers = ['paul_mcbeth'];

  /// Main method to load a reference image with fallback strategy
  ///
  /// [proPlayerId] - ID of the professional player (e.g., 'paul_mcbeth')
  /// [throwType] - Type of throw: 'backhand' or 'forehand'
  /// [checkpoint] - Checkpoint name (e.g., 'heisman', 'loaded', 'magic', 'pro')
  /// [isSkeleton] - true for skeleton-only overlay, false for silhouette with skeleton
  Future<ImageProvider> loadReferenceImage({
    required String proPlayerId,
    required String throwType,
    required String checkpoint,
    required bool isSkeleton,
  }) async {
    final String imageType = isSkeleton ? 'skeleton' : 'silhouette';

    // Tier 1: Check bundled assets (instant loading)
    if (_bundledPlayers.contains(proPlayerId)) {
      final String assetPath =
          'assets/pro_references/$proPlayerId/$throwType/${checkpoint}_$imageType.png';
      return AssetImage(assetPath);
    }

    // Tier 2: Check local cache (fast disk read)
    final File cachedFile = await _getCachedFilePath(
      proPlayerId,
      throwType,
      checkpoint,
      imageType,
    );

    if (await cachedFile.exists()) {
      return FileImage(cachedFile);
    }

    // Tier 3: Download from central storage and cache (one-time download)
    try {
      await _downloadAndCache(
        proPlayerId,
        throwType,
        checkpoint,
        imageType,
        cachedFile,
      );
      return FileImage(cachedFile);
    } catch (e) {
      debugPrint('Failed to download pro reference image: $e');
      // Return a transparent placeholder - error will be handled by errorBuilder in UI
      rethrow;
    }
  }

  /// Downloads a reference image from central cloud storage and caches it locally
  ///
  /// Downloads from: gs://bucket/pro_references/{player}/{throwType}/{checkpoint}_{type}.png
  /// Saves to: {appDocsDir}/pro_references_cache/{player}/{throwType}/{checkpoint}_{type}.png
  Future<void> _downloadAndCache(
    String proPlayerId,
    String throwType,
    String checkpoint,
    String imageType,
    File targetFile,
  ) async {
    // Cloud storage path (central location, NOT per-analysis!)
    final String cloudPath =
        'pro_references/$proPlayerId/$throwType/${checkpoint}_$imageType.png';

    try {
      final Reference ref = _storage.ref(cloudPath);

      // Create parent directories if they don't exist
      await targetFile.parent.create(recursive: true);

      // Download and save to cache
      await ref.writeToFile(targetFile);

      debugPrint(
          'Successfully downloaded and cached pro reference: $cloudPath');
    } catch (e) {
      debugPrint('Error downloading pro reference from $cloudPath: $e');
      rethrow;
    }
  }

  /// Gets the local cache file path for a reference image
  ///
  /// Cache structure: {appDocsDir}/pro_references_cache/{player}/{throwType}/{checkpoint}_{type}.png
  Future<File> _getCachedFilePath(
    String proPlayerId,
    String throwType,
    String checkpoint,
    String imageType,
  ) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String cachePath =
        '${appDir.path}/pro_references_cache/$proPlayerId/$throwType/${checkpoint}_$imageType.png';
    return File(cachePath);
  }

  /// Clears the local cache for a specific player (useful for updates or debugging)
  Future<void> clearCacheForPlayer(String proPlayerId) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory playerCacheDir =
        Directory('${appDir.path}/pro_references_cache/$proPlayerId');

    if (await playerCacheDir.exists()) {
      await playerCacheDir.delete(recursive: true);
      debugPrint('Cleared cache for player: $proPlayerId');
    }
  }

  /// Clears all cached pro reference images
  Future<void> clearAllCache() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory cacheDir =
        Directory('${appDir.path}/pro_references_cache');

    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      debugPrint('Cleared all pro reference cache');
    }
  }

  /// Pre-downloads all reference images for a player to cache
  /// Useful for ensuring offline availability
  Future<void> predownloadPlayerReferences({
    required String proPlayerId,
    required List<String> throwTypes,
    required List<String> checkpoints,
  }) async {
    for (final throwType in throwTypes) {
      for (final checkpoint in checkpoints) {
        for (final isSkeleton in [true, false]) {
          try {
            await loadReferenceImage(
              proPlayerId: proPlayerId,
              throwType: throwType,
              checkpoint: checkpoint,
              isSkeleton: isSkeleton,
            );
          } catch (e) {
            debugPrint(
                'Failed to predownload $proPlayerId $throwType $checkpoint: $e');
          }
        }
      }
    }
    debugPrint('Completed predownload for player: $proPlayerId');
  }
}
