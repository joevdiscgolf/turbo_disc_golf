import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_constants.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';
import 'package:turbo_disc_golf/utils/constants/timing_constants.dart';
import 'package:turbo_disc_golf/utils/firebase/firebase_storage_utils.dart';
import 'package:turbo_disc_golf/utils/firebase/firebase_utils.dart';

abstract class FBFormAnalysisDataLoader {
  /// Save form analysis with images to Firestore and Cloud Storage.
  static Future<bool> saveAnalysis({
    required String uid,
    required String analysisId,
    required String throwType,
    required PoseAnalysisResponse poseAnalysis,
  }) async {
    // Check if saving is enabled
    if (!saveFormAnalysisToFirestore) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[FBFormAnalysisDataLoader] ⏭️  SAVE SKIPPED (saveFormAnalysisToFirestore = false)');
      debugPrint('[FBFormAnalysisDataLoader] Analysis ID: $analysisId');
      debugPrint('[FBFormAnalysisDataLoader] Analysis will be shown in UI but not saved to Firestore');
      debugPrint('═══════════════════════════════════════════════════════');
      return true; // Return true so the UI flow continues normally
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

        // Upload images to Cloud Storage
        final String? userImageUrl = await _uploadCheckpointImage(
          uid: uid,
          analysisId: analysisId,
          checkpointId: checkpoint.checkpointId,
          imageName: 'user',
          base64Data: checkpoint.userImageBase64,
        );

        final String? userSkeletonUrl = await _uploadCheckpointImage(
          uid: uid,
          analysisId: analysisId,
          checkpointId: checkpoint.checkpointId,
          imageName: 'user_skeleton',
          base64Data: checkpoint.userSkeletonOnlyBase64,
        );

        final String? referenceImageUrl = await _uploadCheckpointImage(
          uid: uid,
          analysisId: analysisId,
          checkpointId: checkpoint.checkpointId,
          imageName: 'reference',
          base64Data: checkpoint.referenceSilhouetteWithSkeletonBase64 ??
              checkpoint.referenceImageBase64,
        );

        final String? referenceSkeletonUrl = await _uploadCheckpointImage(
          uid: uid,
          analysisId: analysisId,
          checkpointId: checkpoint.checkpointId,
          imageName: 'reference_skeleton',
          base64Data: checkpoint.referenceSkeletonOnlyBase64,
        );

        // Validate that critical images uploaded successfully
        // Require at least userSkeletonUrl and referenceImageUrl
        if (userSkeletonUrl == null || referenceImageUrl == null) {
          debugPrint('[FBFormAnalysisDataLoader] ❌ Critical image upload failed for checkpoint ${checkpoint.checkpointId}');
          debugPrint('[FBFormAnalysisDataLoader] userSkeletonUrl: ${userSkeletonUrl != null ? "✅" : "❌"}');
          debugPrint('[FBFormAnalysisDataLoader] referenceImageUrl: ${referenceImageUrl != null ? "✅" : "❌"}');
          debugPrint('[FBFormAnalysisDataLoader] ⚠️  Aborting save - will not save to Firestore with missing images');
          return false;
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
        ));

        debugPrint('[FBFormAnalysisDataLoader] ✅ Checkpoint ${checkpoint.checkpointId} images uploaded successfully');
      }

      debugPrint('[FBFormAnalysisDataLoader] ✅ All checkpoint images uploaded successfully');

      // Determine worst deviation severity
      final String? worstSeverity = _getWorstSeverity(checkpointRecords);

      // Aggregate top coaching tips (max 3, unique)
      final List<String> topTips = _aggregateTopTips(checkpointRecords);

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
      } else {
        debugPrint('[FBFormAnalysisDataLoader][saveAnalysis] ❌ Failed to save analysis to Firestore: $analysisId');
      }

      return success;
    } catch (e, trace) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[FBFormAnalysisDataLoader] ❌ SAVE FAILED!');
      debugPrint('[FBFormAnalysisDataLoader] Error: $e');
      debugPrint('[FBFormAnalysisDataLoader] Stack trace: $trace');
      debugPrint('═══════════════════════════════════════════════════════');
      return false;
    }
  }

  /// Load recent form analyses for a user.
  static Future<List<FormAnalysisRecord>> loadRecentAnalyses(
    String uid, {
    int limit = 5,
  }) async {
    try {
      // Path: FormAnalyses/{uid}/FormAnalyses
      final String path = '$kFormAnalysesCollection/$uid/$kFormAnalysesCollection';
      final QuerySnapshot<Map<String, dynamic>>? snapshot =
          await firestoreQuery(
        path: path,
        orderBy: 'created_at',
        timeoutDuration: shortTimeout,
      );

      if (snapshot == null) {
        debugPrint('[FBFormAnalysisDataLoader][loadRecentAnalyses] Query returned null');
        return [];
      }

      // Sort descending and limit
      final List<FormAnalysisRecord> records = snapshot.docs
          .map((doc) => FormAnalysisRecord.fromJson(doc.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return records.take(limit).toList();
    } catch (e, trace) {
      debugPrint('[FBFormAnalysisDataLoader][loadRecentAnalyses] Exception: $e');
      debugPrint('[FBFormAnalysisDataLoader][loadRecentAnalyses] Stack: $trace');
      return [];
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
}
