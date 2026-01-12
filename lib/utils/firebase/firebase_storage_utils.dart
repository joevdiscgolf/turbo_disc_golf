import 'dart:async';
import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

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
