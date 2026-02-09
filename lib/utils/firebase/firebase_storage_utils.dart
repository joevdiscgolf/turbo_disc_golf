import 'dart:async';
import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:turbo_disc_golf/utils/constants/timing_constants.dart';

/// Upload base64 image to Cloud Storage.
///
/// [path]: Storage path (e.g., 'form_analyses/userId/analysisId/image.jpg')
/// [base64Data]: Base64-encoded image data
/// [contentType]: MIME type (default: 'image/jpeg')
/// [timeoutDuration]: Upload timeout (default: 5 seconds)
///
/// Returns download URL on success, null on failure.
Future<String?> storageUploadImage({
  required String path,
  required String base64Data,
  String contentType = 'image/jpeg',
  Duration timeoutDuration = const Duration(seconds: 5),
}) async {
  try {
    // Decode base64 to bytes
    final Uint8List bytes = base64Decode(base64Data);
    debugPrint('[firebase][storage] Decoded ${bytes.length} bytes (~${(bytes.length / 1024).toStringAsFixed(1)} KB)');

    // Upload to Cloud Storage
    debugPrint('[firebase][storage] Uploading to: $path');
    debugPrint('[firebase][storage] Bucket: ${FirebaseStorage.instance.bucket}');
    final Reference ref = FirebaseStorage.instance.ref().child(path);

    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );

    // Listen to upload progress
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final double progress =
          snapshot.bytesTransferred / snapshot.totalBytes * 100;
      debugPrint('[firebase][storage] Upload progress: ${progress.toStringAsFixed(1)}%');
    });

    try {
      await uploadTask.timeout(
        timeoutDuration,
        onTimeout: () => throw TimeoutException(
          'Storage upload timed out for path: $path',
        ),
      );
    } catch (e) {
      debugPrint('[firebase][storage] ❌ Upload error type: ${e.runtimeType}');
      debugPrint('[firebase][storage] ❌ Upload error details: $e');
      rethrow;
    }

    debugPrint('[firebase][storage] Upload complete, getting download URL...');

    // Get download URL
    final String downloadUrl = await ref.getDownloadURL().timeout(
      timeoutDuration,
      onTimeout: () => throw TimeoutException(
        'Getting download URL timed out for path: $path',
      ),
    );

    debugPrint('[firebase][storage] ✅ Success! URL: ${downloadUrl.substring(0, downloadUrl.length > 60 ? 60 : downloadUrl.length)}...');
    return downloadUrl;
  } on TimeoutException catch (_) {
    debugPrint(
      '[firebase][storage][storageUploadImage] timeout, path: $path, duration: ${timeoutDuration.inSeconds}s',
    );
    return null;
  } catch (e, trace) {
    debugPrint(
      '[firebase][storage][storageUploadImage] ❌ Exception: $e',
    );
    FirebaseCrashlytics.instance.recordError(
      e,
      trace,
      reason: '[firebase][storage][storageUploadImage] exception, path: $path',
    );
    return null;
  }
}

/// Delete a file from Cloud Storage using its download URL.
///
/// [url]: The Firebase Storage download URL (must be a gs:// or firebasestorage.googleapis.com URL)
/// [timeoutDuration]: Timeout for the delete operation (default: 5 seconds)
///
/// Returns true if deletion succeeded or URL is not a Firebase Storage URL, false on failure.
Future<bool> storageDeleteByUrl(
  String url, {
  Duration timeoutDuration = const Duration(seconds: 5),
}) async {
  // Validate URL is a Firebase Storage URL before attempting deletion
  final bool isFirebaseStorageUrl = url.startsWith('gs://') ||
      url.contains('firebasestorage.googleapis.com') ||
      url.contains('storage.googleapis.com');

  if (!isFirebaseStorageUrl) {
    debugPrint('[StorageUtils] ⏭️  Skipping non-Firebase URL: ${_truncateUrl(url)}');
    debugPrint('[StorageUtils]    URL type: ${_identifyUrlType(url)}');
    return true; // Not an error - just not a Firebase Storage URL
  }

  debugPrint('[StorageUtils] 🗑️  Attempting to delete: ${_truncateUrl(url)}');
  debugPrint('[StorageUtils]    URL type: ${_identifyUrlType(url)}');

  try {
    final Reference ref = FirebaseStorage.instance.refFromURL(url);
    debugPrint('[StorageUtils]    Resolved path: ${ref.fullPath}');
    debugPrint('[StorageUtils]    Bucket: ${ref.bucket}');

    await ref.delete().timeout(timeoutDuration);
    debugPrint('[StorageUtils] ✅ Deleted: ${ref.fullPath}');
    return true;
  } on FirebaseException catch (e) {
    // object-not-found is not an error - file may already be deleted
    if (e.code == 'object-not-found') {
      debugPrint('[StorageUtils] ✅ File already deleted or not found');
      return true;
    }
    debugPrint('[StorageUtils] ❌ FirebaseException: code=${e.code}, message=${e.message}');
    debugPrint('[StorageUtils]    Plugin: ${e.plugin}');
    debugPrint('[StorageUtils]    Full URL: $url');
    return false;
  } catch (e, trace) {
    debugPrint('[StorageUtils] ❌ Exception type: ${e.runtimeType}');
    debugPrint('[StorageUtils]    Error: $e');
    debugPrint('[StorageUtils]    Full URL: $url');
    FirebaseCrashlytics.instance.recordError(
      e,
      trace,
      reason: '[firebase][storage][storageDeleteByUrl] exception, url: ${_truncateUrl(url)}',
    );
    return false;
  }
}

/// Truncate URL for logging (show first 80 chars).
String _truncateUrl(String url) {
  if (url.length <= 80) return url;
  return '${url.substring(0, 80)}...';
}

/// Identify the type of URL for debugging.
String _identifyUrlType(String url) {
  if (url.startsWith('gs://')) return 'gs:// (Firebase Storage)';
  if (url.contains('firebasestorage.googleapis.com')) return 'Firebase Storage download URL';
  if (url.contains('storage.googleapis.com')) return 'Google Cloud Storage URL';
  if (url.contains('cloudflare')) return 'Cloudflare URL';
  if (url.contains('amazonaws.com')) return 'AWS S3 URL';
  if (url.startsWith('http://localhost') || url.startsWith('http://127.0.0.1')) return 'Localhost URL';
  if (url.contains('/api/') || url.contains('/v1/') || url.contains('/v2/')) return 'API endpoint URL';
  return 'Unknown URL type';
}

/// Delete all files in a Cloud Storage folder (prefix-based deletion).
///
/// [folderPath]: Storage folder path (e.g., 'form_analyses/userId')
/// [timeoutDuration]: Timeout for operations (default: longTimeout)
///
/// Returns true if deletion succeeded, false on failure.
/// This function recursively deletes all files and subfolders.
Future<bool> storageDeleteFolder(
  String folderPath, {
  Duration timeoutDuration = longTimeout,
}) async {
  try {
    final Reference folderRef = FirebaseStorage.instance.ref().child(folderPath);
    final ListResult result = await folderRef.listAll().timeout(timeoutDuration);

    // Delete all files
    for (final Reference fileRef in result.items) {
      try {
        await fileRef.delete().timeout(const Duration(seconds: 5));
        debugPrint('[StorageUtils] Deleted: ${fileRef.fullPath}');
      } catch (e) {
        debugPrint('[StorageUtils] Failed to delete file ${fileRef.fullPath}: $e');
      }
    }

    // Recursively delete subfolders
    for (final Reference subfolderRef in result.prefixes) {
      await storageDeleteFolder(subfolderRef.fullPath, timeoutDuration: timeoutDuration);
    }

    debugPrint('[StorageUtils] Deleted folder: $folderPath');
    return true;
  } catch (e, trace) {
    debugPrint('[StorageUtils] Delete folder error: $e');
    FirebaseCrashlytics.instance.recordError(
      e,
      trace,
      reason: '[firebase][storage][storageDeleteFolder] exception, path: $folderPath',
    );
    return false;
  }
}
