import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/alignment_metadata.dart';
import 'package:turbo_disc_golf/services/form_analysis/pro_player_constants.dart';

/// Service for loading professional player reference images using a three-tier strategy:
/// 1. Bundled assets (fastest - for Paul McBeth)
/// 2. Local cache (fast - for previously downloaded players)
/// 3. Central cloud storage (one-time download - for new players)
class ProReferenceLoader {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// In-memory cache for alignment metadata to avoid repeated parsing
  final Map<String, AlignmentMetadata> _metadataCache = {};

  /// Helper method to get the camera angle folder name
  ///
  /// Returns 'side' or 'rear' based on the camera angle
  static String _getAngleFolderName(CameraAngle cameraAngle) {
    return cameraAngle.toApiString(); // 'side' or 'rear'
  }

  /// Main method to load a reference image with fallback strategy
  ///
  /// [proPlayerId] - ID of the professional player (e.g., 'paul_mcbeth')
  /// [throwType] - Type of throw: 'backhand' or 'forehand'
  /// [checkpoint] - Checkpoint name (e.g., 'heisman', 'loaded', 'magic', 'pro')
  /// [isSkeleton] - true for skeleton-only overlay, false for silhouette with skeleton
  /// [cameraAngle] - Camera angle used for video capture (defaults to side view)
  Future<ImageProvider> loadReferenceImage({
    required String proPlayerId,
    required String throwType,
    required String checkpoint,
    required bool isSkeleton,
    CameraAngle cameraAngle = CameraAngle.side,
  }) async {
    final String imageType = isSkeleton ? 'skeleton' : 'silhouette';
    final String angleFolderName = _getAngleFolderName(cameraAngle);

    // Tier 1: Check bundled assets (instant loading)
    if (ProPlayerConstants.bundledPlayers.contains(proPlayerId)) {
      final String assetPath =
          'assets/pro_references/$proPlayerId/$throwType/$angleFolderName/${checkpoint}_$imageType.png';

      // For rear-view, fall back to side view if rear assets don't exist yet
      if (cameraAngle == CameraAngle.rear) {
        try {
          return AssetImage(assetPath);
        } catch (e) {
          debugPrint(
            '⚠️ Rear-view assets not found, falling back to side view: $assetPath',
          );
          final String sideViewPath =
              'assets/pro_references/$proPlayerId/$throwType/side/${checkpoint}_$imageType.png';
          return AssetImage(sideViewPath);
        }
      }

      return AssetImage(assetPath);
    }

    // Tier 2: Check local cache (fast disk read)
    final File cachedFile = await _getCachedFilePath(
      proPlayerId,
      throwType,
      checkpoint,
      imageType,
      cameraAngle,
    );

    // TODO: Re-enable cache check once cloud images are finalized
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
        cameraAngle,
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
  /// Downloads from: gs://bucket/pro_references/{player}/{throwType}/{angle}/{checkpoint}_{type}.png
  /// Saves to: {appDocsDir}/pro_references_cache/{player}/{throwType}/{angle}/{checkpoint}_{type}.png
  Future<void> _downloadAndCache(
    String proPlayerId,
    String throwType,
    String checkpoint,
    String imageType,
    CameraAngle cameraAngle,
    File targetFile,
  ) async {
    final String angleFolderName = _getAngleFolderName(cameraAngle);

    // Cloud storage path (central location, NOT per-analysis!)
    final String cloudPath =
        'pro_references/$proPlayerId/$throwType/$angleFolderName/${checkpoint}_$imageType.png';

    try {
      final Reference ref = _storage.ref(cloudPath);

      // Create parent directories if they don't exist
      await targetFile.parent.create(recursive: true);

      // Download and save to cache
      await ref.writeToFile(targetFile);

      debugPrint(
        'Successfully downloaded and cached pro reference: $cloudPath',
      );
    } catch (e) {
      debugPrint('Error downloading pro reference from $cloudPath: $e');
      rethrow;
    }
  }

  /// Gets the local cache file path for a reference image
  ///
  /// Cache structure: {appDocsDir}/pro_references_cache/{player}/{throwType}/{angle}/{checkpoint}_{type}.png
  Future<File> _getCachedFilePath(
    String proPlayerId,
    String throwType,
    String checkpoint,
    String imageType,
    CameraAngle cameraAngle,
  ) async {
    final String angleFolderName = _getAngleFolderName(cameraAngle);
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String cachePath =
        '${appDir.path}/pro_references_cache/$proPlayerId/$throwType/$angleFolderName/${checkpoint}_$imageType.png';
    return File(cachePath);
  }

  /// Clears the local cache for a specific player (useful for updates or debugging)
  Future<void> clearCacheForPlayer(String proPlayerId) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory playerCacheDir = Directory(
      '${appDir.path}/pro_references_cache/$proPlayerId',
    );

    if (await playerCacheDir.exists()) {
      await playerCacheDir.delete(recursive: true);
      debugPrint('Cleared cache for player: $proPlayerId');
    }
  }

  /// Clears all cached pro reference images
  Future<void> clearAllCache() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory cacheDir = Directory('${appDir.path}/pro_references_cache');

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
              'Failed to predownload $proPlayerId $throwType $checkpoint: $e',
            );
          }
        }
      }
    }
    debugPrint('Completed predownload for player: $proPlayerId');
  }

  /// Loads alignment metadata for a specific pro player reference video
  ///
  /// Loading strategy:
  /// 1. In-memory cache (fastest - persists for session)
  /// 2. Cloud storage download (fresh on each app restart)
  ///
  /// Returns null if metadata is not available for this player/throwType/angle combination
  Future<AlignmentMetadata?> loadAlignmentMetadata({
    required String proPlayerId,
    required String throwType,
    required CameraAngle cameraAngle,
  }) async {
    final String angleFolderName = _getAngleFolderName(cameraAngle);
    final String cacheKey = '$proPlayerId/$throwType/$angleFolderName';

    debugPrint(
      '🎯 [AlignmentMetadata] Loading metadata for: $proPlayerId/$throwType/$angleFolderName',
    );

    // Check in-memory cache first (persists for session)
    if (_metadataCache.containsKey(cacheKey)) {
      debugPrint('✅ [AlignmentMetadata] Found in memory cache');
      return _metadataCache[cacheKey];
    }

    // Download from cloud storage
    debugPrint('☁️ [AlignmentMetadata] Downloading from cloud storage');
    try {
      final String cloudPath =
          'pro_references/$proPlayerId/$throwType/$angleFolderName/alignment_metadata.json';

      debugPrint('   Cloud path: $cloudPath');

      final Reference ref = _storage.ref(cloudPath);
      final Uint8List? data = await ref.getData();

      if (data == null) {
        debugPrint('❌ [AlignmentMetadata] No data returned from cloud storage');
        return null;
      }

      final String jsonString = utf8.decode(data);
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final AlignmentMetadata metadata = AlignmentMetadata.fromJson(json);

      // Cache in memory for this session
      _metadataCache[cacheKey] = metadata;
      debugPrint('✅ [AlignmentMetadata] Downloaded and cached in memory');
      debugPrint('   Checkpoints: ${metadata.checkpoints.keys.join(", ")}');
      return metadata;
    } catch (e) {
      debugPrint(
        '❌ [AlignmentMetadata] Failed to download from cloud storage: $e',
      );
      return null;
    }
  }

  /// Clears the in-memory metadata cache
  void clearMetadataCache() {
    _metadataCache.clear();
    debugPrint('Cleared alignment metadata cache');
  }
}
