import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_constants.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';
import 'package:turbo_disc_golf/utils/constants/timing_constants.dart';
import 'package:turbo_disc_golf/utils/firebase/firebase_storage_utils.dart';
import 'package:turbo_disc_golf/utils/firebase/firebase_utils.dart';

abstract class FBFormAnalysisDataLoader {
  /// Save form analysis with images to Firestore and Cloud Storage.
  /// Returns the saved FormAnalysisRecord on success, null on failure.
  static Future<FormAnalysisRecord?> saveAnalysis({
    required String uid,
    required String analysisId,
    required String throwType,
    required CameraAngle cameraAngle,
    required PoseAnalysisResponse poseAnalysis,
  }) async {
    // Check if saving is enabled
    if (!saveFormAnalysisToFirestore) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[FBFormAnalysisDataLoader] ⏭️  SAVE SKIPPED (saveFormAnalysisToFirestore = false)');
      debugPrint('[FBFormAnalysisDataLoader] Analysis ID: $analysisId');
      debugPrint('[FBFormAnalysisDataLoader] Analysis will be shown in UI but not saved to Firestore');
      debugPrint('═══════════════════════════════════════════════════════');
      // Return null since nothing was saved (testing mode)
      return null;
    }

    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[FBFormAnalysisDataLoader] 💾 SAVE START');
      debugPrint('[FBFormAnalysisDataLoader] Analysis ID: $analysisId');
      debugPrint('[FBFormAnalysisDataLoader] User ID: $uid');
      debugPrint('[FBFormAnalysisDataLoader] Throw type: $throwType');
      debugPrint('[FBFormAnalysisDataLoader] Checkpoints to save: ${poseAnalysis.checkpoints.length}');
      debugPrint('═══════════════════════════════════════════════════════');

      // Build checkpoint records with uploaded image URLs
      final List<CheckpointRecord> checkpointRecords = [];

      for (int i = 0; i < poseAnalysis.checkpoints.length; i++) {
        final checkpoint = poseAnalysis.checkpoints[i];
        debugPrint('');
        debugPrint('[FBFormAnalysisDataLoader] Processing checkpoint ${i + 1}/${poseAnalysis.checkpoints.length}: ${checkpoint.checkpointId}');

        // Upload images to Cloud Storage in parallel for better performance
        // Pro reference images are loaded via ProReferenceLoader (bundled assets/cache/cloud)
        // They are NOT uploaded per-analysis to save bandwidth and storage
        // Legacy analyses may still have uploaded reference images
        final List<String?> uploadResults = await Future.wait([
          _uploadCheckpointImage(
            uid: uid,
            analysisId: analysisId,
            checkpointId: checkpoint.checkpointId,
            imageName: 'user',
            base64Data: checkpoint.userImageBase64,
          ),
          _uploadCheckpointImage(
            uid: uid,
            analysisId: analysisId,
            checkpointId: checkpoint.checkpointId,
            imageName: 'user_skeleton',
            base64Data: checkpoint.userSkeletonOnlyBase64,
          ),
          _uploadCheckpointImage(
            uid: uid,
            analysisId: analysisId,
            checkpointId: checkpoint.checkpointId,
            imageName: 'reference',
            base64Data: checkpoint.referenceSilhouetteWithSkeletonBase64 ??
                checkpoint.referenceImageBase64,
          ),
          _uploadCheckpointImage(
            uid: uid,
            analysisId: analysisId,
            checkpointId: checkpoint.checkpointId,
            imageName: 'reference_skeleton',
            base64Data: checkpoint.referenceSkeletonOnlyBase64,
          ),
        ]);

        final String? userImageUrl = uploadResults[0];
        final String? userSkeletonUrl = uploadResults[1];
        final String? referenceImageUrl = uploadResults[2];
        final String? referenceSkeletonUrl = uploadResults[3];

        // Validate that critical user skeleton image uploaded successfully
        // Note: Pro reference images are NOT uploaded - they are loaded via ProReferenceLoader
        if (userSkeletonUrl == null) {
          debugPrint('[FBFormAnalysisDataLoader] ❌ Critical image upload failed for checkpoint ${checkpoint.checkpointId}');
          debugPrint('[FBFormAnalysisDataLoader] userSkeletonUrl is null - this is required');
          debugPrint('[FBFormAnalysisDataLoader] ⚠️  Aborting save - will not save to Firestore with missing images');
          return null;
        }

        // Log the reference loading strategy being used
        if (checkpoint.proPlayerId != null) {
          debugPrint('[FBFormAnalysisDataLoader] ✅ Using ProReferenceLoader with proPlayerId: ${checkpoint.proPlayerId}');
        } else if (referenceImageUrl != null) {
          debugPrint('[FBFormAnalysisDataLoader] ✅ Using legacy referenceImageUrl (uploaded to Cloud Storage)');
        } else {
          debugPrint('[FBFormAnalysisDataLoader] ⚠️  No reference image strategy - checkpoint will have no pro comparison');
        }

        // Build angle deviations map
        final Map<String, double>? angleDeviations =
            _buildAngleDeviationsMap(checkpoint.deviationsRaw);

        // Create checkpoint record
        checkpointRecords.add(CheckpointRecord(
          checkpointId: checkpoint.checkpointId,
          checkpointName: checkpoint.checkpointName,
          deviationSeverity: checkpoint.deviationSeverity,
          coachingTips: checkpoint.coachingTips,
          angleDeviations: angleDeviations,
          userImageUrl: userImageUrl,
          userSkeletonUrl: userSkeletonUrl,
          referenceImageUrl: referenceImageUrl,
          referenceSkeletonUrl: referenceSkeletonUrl,
          // New hybrid asset loading fields
          proPlayerId: checkpoint.proPlayerId ?? 'paul_mcbeth', // Default to Paul McBeth
          referenceHorizontalOffsetPercent:
              checkpoint.referenceHorizontalOffsetPercent,
        ));

        debugPrint('[FBFormAnalysisDataLoader] ✅ Checkpoint ${checkpoint.checkpointId} images uploaded successfully');
      }

      debugPrint('[FBFormAnalysisDataLoader] ✅ All checkpoint images uploaded successfully');

      // Determine worst deviation severity
      final String? worstSeverity = _getWorstSeverity(checkpointRecords);

      // Aggregate top coaching tips (max 3, unique)
      final List<String> topTips = _aggregateTopTips(checkpointRecords);

      // Use ONLY backend-generated thumbnail (256x256, centered on body, Heisman position with skeleton overlay)
      debugPrint('');
      debugPrint('[FBFormAnalysisDataLoader] ═══ THUMBNAIL HANDLING ═══');
      debugPrint('[FBFormAnalysisDataLoader] Checking poseAnalysis.roundThumbnailBase64...');
      debugPrint('[FBFormAnalysisDataLoader] - Is null: ${poseAnalysis.roundThumbnailBase64 == null}');
      if (poseAnalysis.roundThumbnailBase64 != null) {
        debugPrint('[FBFormAnalysisDataLoader] - Length: ${poseAnalysis.roundThumbnailBase64!.length} chars');
        debugPrint('[FBFormAnalysisDataLoader] - First 30 chars: ${poseAnalysis.roundThumbnailBase64!.substring(0, poseAnalysis.roundThumbnailBase64!.length > 30 ? 30 : poseAnalysis.roundThumbnailBase64!.length)}');
      }

      String? thumbnailBase64;

      if (poseAnalysis.roundThumbnailBase64 != null &&
          poseAnalysis.roundThumbnailBase64!.isNotEmpty) {
        thumbnailBase64 = poseAnalysis.roundThumbnailBase64;
        final int thumbnailSize = poseAnalysis.roundThumbnailBase64!.length;
        debugPrint('[FBFormAnalysisDataLoader] ✅ Using backend-generated thumbnail (~${(thumbnailSize / 1024).toStringAsFixed(1)} KB)');
      } else {
        // Backend didn't provide thumbnail - log warning and continue without thumbnail
        debugPrint('[FBFormAnalysisDataLoader] ❌ Backend thumbnail NOT available');
        debugPrint('[FBFormAnalysisDataLoader] - roundThumbnailBase64 is ${poseAnalysis.roundThumbnailBase64 == null ? "NULL" : "EMPTY STRING"}');
        debugPrint('[FBFormAnalysisDataLoader] ⚠️  Analysis will be saved WITHOUT thumbnail');
        debugPrint('[FBFormAnalysisDataLoader] ⚠️  Frontend no longer generates fallback thumbnails');
      }
      debugPrint('[FBFormAnalysisDataLoader] ═══════════════════════════');

      // Create the record
      final FormAnalysisRecord record = FormAnalysisRecord(
        id: analysisId,
        uid: uid,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        throwType: throwType,
        overallFormScore: poseAnalysis.overallFormScore,
        worstDeviationSeverity: worstSeverity,
        checkpoints: checkpointRecords,
        topCoachingTips: topTips.isEmpty ? null : topTips,
        thumbnailBase64: thumbnailBase64,
        cameraAngle: cameraAngle,
      );

      // Save to Firestore using utility
      // Path: FormAnalyses/{uid}/FormAnalyses/{analysisId}
      final String firestorePath =
          '$kFormAnalysesCollection/$uid/$kFormAnalysesCollection/$analysisId';
      final bool success = await firestoreWrite(
        firestorePath,
        record.toJson(),
        merge: false,
        timeoutDuration: shortTimeout,
      );

      if (success) {
        debugPrint('[FBFormAnalysisDataLoader][saveAnalysis] ✅ Successfully saved analysis: $analysisId');
        return record; // Return the saved record
      } else {
        debugPrint('[FBFormAnalysisDataLoader][saveAnalysis] ❌ Failed to save analysis to Firestore: $analysisId');
        return null;
      }
    } catch (e, trace) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[FBFormAnalysisDataLoader] ❌ SAVE FAILED!');
      debugPrint('[FBFormAnalysisDataLoader] Error: $e');
      debugPrint('[FBFormAnalysisDataLoader] Stack trace: $trace');
      debugPrint('═══════════════════════════════════════════════════════');
      return null;
    }
  }

  /// Load recent form analyses for a user with pagination support.
  /// Returns a tuple of (analyses, hasMore) where hasMore indicates if there are more documents.
  static Future<(List<FormAnalysisRecord>, bool)> loadRecentAnalyses(
    String uid, {
    int limit = 15,
    String? startAfterTimestamp,
  }) async {
    try {
      // Path: FormAnalyses/{uid}/FormAnalyses
      final String path = '$kFormAnalysesCollection/$uid/$kFormAnalysesCollection';

      // Build the query
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection(path)
          .orderBy('created_at', descending: true)
          .limit(limit + 1); // Request one extra to check if there are more

      // If we have a cursor, start after it
      if (startAfterTimestamp != null && startAfterTimestamp.isNotEmpty) {
        query = query.startAfter([startAfterTimestamp]);
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot = await query
          .get()
          .timeout(
            standardTimeout,
            onTimeout: () => throw TimeoutException(
              'Query timed out for path: $path',
            ),
          );

      if (snapshot.docs.isEmpty) {
        debugPrint(
            '[FBFormAnalysisDataLoader][loadRecentAnalyses] No documents found');
        return (<FormAnalysisRecord>[], false);
      }

      // Parse documents
      final List<FormAnalysisRecord> allRecords = snapshot.docs
          .map((doc) => FormAnalysisRecord.fromJson(doc.data()))
          .toList();

      // Check if there are more documents
      final bool hasMore = allRecords.length > limit;

      // Return only the requested limit
      final List<FormAnalysisRecord> records =
          hasMore ? allRecords.take(limit).toList() : allRecords;

      debugPrint(
          '[FBFormAnalysisDataLoader][loadRecentAnalyses] Loaded ${records.length} analyses, hasMore: $hasMore');

      return (records, hasMore);
    } catch (e, trace) {
      debugPrint('[FBFormAnalysisDataLoader][loadRecentAnalyses] Exception: $e');
      debugPrint('[FBFormAnalysisDataLoader][loadRecentAnalyses] Stack: $trace');
      return (<FormAnalysisRecord>[], false);
    }
  }

  /// Load a specific form analysis by ID.
  static Future<FormAnalysisRecord?> loadAnalysisById(
    String uid,
    String analysisId,
  ) async {
    try {
      // Path: FormAnalyses/{uid}/FormAnalyses/{analysisId}
      final String path =
          '$kFormAnalysesCollection/$uid/$kFormAnalysesCollection/$analysisId';
      final DocumentSnapshot<Map<String, dynamic>>? snapshot =
          await firestoreFetch(
        path,
        timeoutDuration: shortTimeout,
      );

      if (snapshot == null || !snapshot.exists || snapshot.data() == null) {
        debugPrint('[FBFormAnalysisDataLoader][loadAnalysisById] Analysis not found: $analysisId');
        return null;
      }

      return FormAnalysisRecord.fromJson(snapshot.data()!);
    } catch (e, trace) {
      debugPrint('[FBFormAnalysisDataLoader][loadAnalysisById] Exception: $e');
      debugPrint('[FBFormAnalysisDataLoader][loadAnalysisById] Stack: $trace');
      return null;
    }
  }

  /// Upload a checkpoint image to Cloud Storage.
  static Future<String?> _uploadCheckpointImage({
    required String uid,
    required String analysisId,
    required String checkpointId,
    required String imageName,
    String? base64Data,
  }) async {
    if (base64Data == null || base64Data.isEmpty) {
      debugPrint('[FBFormAnalysisDataLoader] ⏭️  Skipping $imageName (no data)');
      return null;
    }

    debugPrint('[FBFormAnalysisDataLoader] ⬆️  Uploading $imageName...');
    final String path =
        'form_analyses/$uid/$analysisId/${checkpointId}_$imageName.jpg';

    final String? url = await storageUploadImage(
      path: path,
      base64Data: base64Data,
      contentType: 'image/jpeg',
      timeoutDuration: const Duration(seconds: 5),
    );

    if (url != null) {
      debugPrint('[FBFormAnalysisDataLoader] ✅ Uploaded $imageName');
    } else {
      debugPrint('[FBFormAnalysisDataLoader] ❌ Failed to upload $imageName');
    }

    return url;
  }

  /// Build angle deviations map from AngleDeviations object.
  static Map<String, double>? _buildAngleDeviationsMap(
      AngleDeviations deviations) {
    final Map<String, double> map = {};

    if (deviations.shoulderRotation != null) {
      map['shoulder_rotation'] = deviations.shoulderRotation!;
    }
    if (deviations.elbowAngle != null) {
      map['elbow_angle'] = deviations.elbowAngle!;
    }
    if (deviations.hipRotation != null) {
      map['hip_rotation'] = deviations.hipRotation!;
    }
    if (deviations.kneeBend != null) {
      map['knee_bend'] = deviations.kneeBend!;
    }
    if (deviations.spineTilt != null) {
      map['spine_tilt'] = deviations.spineTilt!;
    }

    return map.isEmpty ? null : map;
  }

  /// Get the worst severity from all checkpoints.
  static String? _getWorstSeverity(List<CheckpointRecord> checkpoints) {
    if (checkpoints.isEmpty) return null;

    const List<String> severityOrder = [
      'good',
      'minor',
      'moderate',
      'significant',
    ];

    String? worstSeverity;
    int worstIndex = -1;

    for (final checkpoint in checkpoints) {
      final int index =
          severityOrder.indexOf(checkpoint.deviationSeverity.toLowerCase());
      if (index > worstIndex) {
        worstIndex = index;
        worstSeverity = checkpoint.deviationSeverity;
      }
    }

    return worstSeverity;
  }

  /// Aggregate top coaching tips from all checkpoints (max 3, unique).
  static List<String> _aggregateTopTips(List<CheckpointRecord> checkpoints) {
    final Set<String> uniqueTips = {};

    for (final checkpoint in checkpoints) {
      for (final tip in checkpoint.coachingTips) {
        if (uniqueTips.length < 3) {
          uniqueTips.add(tip);
        }
      }
    }

    return uniqueTips.toList();
  }

  /// Delete a single form analysis and its associated images.
  /// Returns true on success, false on failure.
  static Future<bool> deleteAnalysis({
    required String uid,
    required String analysisId,
  }) async {
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[FBFormAnalysisDataLoader] 🗑️  DELETE SINGLE ANALYSIS');
      debugPrint('[FBFormAnalysisDataLoader] User ID: $uid');
      debugPrint('[FBFormAnalysisDataLoader] Analysis ID: $analysisId');
      debugPrint('═══════════════════════════════════════════════════════');

      // Step 1: Delete Firestore document
      final String firestorePath =
          '$kFormAnalysesCollection/$uid/$kFormAnalysesCollection/$analysisId';
      debugPrint(
          '[FBFormAnalysisDataLoader] Deleting Firestore doc: $firestorePath');

      final bool firestoreSuccess = await firestoreDelete(
        firestorePath,
        timeoutDuration: shortTimeout,
      );

      if (!firestoreSuccess) {
        debugPrint('[FBFormAnalysisDataLoader] ❌ Firestore deletion failed');
        return false;
      }

      debugPrint('[FBFormAnalysisDataLoader] ✅ Firestore deletion complete');

      // Step 2: Delete Cloud Storage images for this analysis
      final String storagePath = 'form_analyses/$uid/$analysisId';
      debugPrint(
          '[FBFormAnalysisDataLoader] Deleting Cloud Storage folder: $storagePath');

      final bool storageSuccess = await storageDeleteFolder(
        storagePath,
        timeoutDuration: shortTimeout,
      );

      if (!storageSuccess) {
        debugPrint(
            '[FBFormAnalysisDataLoader] ⚠️  Cloud Storage deletion had errors');
      } else {
        debugPrint(
            '[FBFormAnalysisDataLoader] ✅ Cloud Storage deletion complete');
      }

      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[FBFormAnalysisDataLoader] ✅ DELETE COMPLETE');
      debugPrint('═══════════════════════════════════════════════════════');

      return true;
    } catch (e, trace) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[FBFormAnalysisDataLoader] ❌ DELETE FAILED!');
      debugPrint('[FBFormAnalysisDataLoader] Error: $e');
      debugPrint('[FBFormAnalysisDataLoader] Stack trace: $trace');
      debugPrint('═══════════════════════════════════════════════════════');
      return false;
    }
  }

  /// Delete all form analyses and associated images for a user.
  /// This is a DESTRUCTIVE operation - use only in debug mode.
  static Future<bool> deleteAllAnalysesForUser(String uid) async {
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[FBFormAnalysisDataLoader] 🗑️  DELETE ALL START');
      debugPrint('[FBFormAnalysisDataLoader] User ID: $uid');
      debugPrint('═══════════════════════════════════════════════════════');

      // Step 1: Delete all Firestore documents
      final String firestorePath = '$kFormAnalysesCollection/$uid/$kFormAnalysesCollection';
      debugPrint('[FBFormAnalysisDataLoader] Deleting Firestore collection: $firestorePath');

      final bool firestoreSuccess = await firestoreDeleteCollection(
        firestorePath,
        timeoutDuration: longTimeout,
      );

      if (!firestoreSuccess) {
        debugPrint('[FBFormAnalysisDataLoader] ❌ Firestore deletion failed');
        return false;
      }

      debugPrint('[FBFormAnalysisDataLoader] ✅ Firestore deletion complete');

      // Step 2: Delete all Cloud Storage images
      final String storagePath = 'form_analyses/$uid';
      debugPrint('[FBFormAnalysisDataLoader] Deleting Cloud Storage folder: $storagePath');

      final bool storageSuccess = await storageDeleteFolder(
        storagePath,
        timeoutDuration: longTimeout,
      );

      if (!storageSuccess) {
        debugPrint('[FBFormAnalysisDataLoader] ⚠️  Cloud Storage deletion had errors (may be partial)');
      } else {
        debugPrint('[FBFormAnalysisDataLoader] ✅ Cloud Storage deletion complete');
      }

      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[FBFormAnalysisDataLoader] ✅ DELETE ALL COMPLETE');
      debugPrint('═══════════════════════════════════════════════════════');

      return true;
    } catch (e, trace) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[FBFormAnalysisDataLoader] ❌ DELETE ALL FAILED!');
      debugPrint('[FBFormAnalysisDataLoader] Error: $e');
      debugPrint('[FBFormAnalysisDataLoader] Stack trace: $trace');
      debugPrint('═══════════════════════════════════════════════════════');
      return false;
    }
  }
}
