import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_record.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_constants.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final FirebaseStorage _storage = FirebaseStorage.instance;

/// Repository for form analysis history storage.
/// Stores analysis metadata in Firestore and images in Cloud Storage.
class FormAnalysisRepository {
  /// Save a form analysis to Firestore with images in Cloud Storage.
  ///
  /// [uid] - User's UID
  /// [analysisId] - Unique ID for this analysis
  /// [throwType] - "backhand" or "forehand"
  /// [poseAnalysis] - The pose analysis response from the backend
  Future<bool> saveAnalysis({
    required String uid,
    required String analysisId,
    required String throwType,
    required PoseAnalysisResponse poseAnalysis,
  }) async {
    try {
      debugPrint('[FormAnalysisRepo] Saving analysis $analysisId for user $uid');

      // Build checkpoint records with uploaded image URLs
      final List<CheckpointRecord> checkpointRecords = [];

      for (final checkpoint in poseAnalysis.checkpoints) {
        // Upload images to Cloud Storage and get URLs
        final String? userImageUrl = await _uploadImage(
          uid: uid,
          analysisId: analysisId,
          checkpointId: checkpoint.checkpointId,
          imageName: 'user',
          base64Data: checkpoint.userImageBase64,
        );

        final String? userSkeletonUrl = await _uploadImage(
          uid: uid,
          analysisId: analysisId,
          checkpointId: checkpoint.checkpointId,
          imageName: 'user_skeleton',
          base64Data: checkpoint.userSkeletonOnlyBase64,
        );

        final String? referenceImageUrl = await _uploadImage(
          uid: uid,
          analysisId: analysisId,
          checkpointId: checkpoint.checkpointId,
          imageName: 'reference',
          base64Data: checkpoint.referenceSilhouetteWithSkeletonBase64 ??
              checkpoint.referenceImageBase64,
        );

        // Build angle deviations map
        final Map<String, double>? angleDeviations =
            _buildAngleDeviationsMap(checkpoint.deviationsRaw);

        checkpointRecords.add(CheckpointRecord(
          checkpointId: checkpoint.checkpointId,
          checkpointName: checkpoint.checkpointName,
          deviationSeverity: checkpoint.deviationSeverity,
          coachingTips: checkpoint.coachingTips,
          angleDeviations: angleDeviations,
          userImageUrl: userImageUrl,
          userSkeletonUrl: userSkeletonUrl,
          referenceImageUrl: referenceImageUrl,
        ));
      }

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

      // Save to Firestore
      await _firestore
          .collection('$kUsersCollection/$uid/$kFormAnalysesCollection')
          .doc(analysisId)
          .set(record.toJson())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('[FormAnalysisRepo] Timeout saving to Firestore');
              throw Exception('Timeout saving analysis');
            },
          );

      debugPrint('[FormAnalysisRepo] Successfully saved analysis $analysisId');
      return true;
    } catch (e, trace) {
      debugPrint('[FormAnalysisRepo] Error saving analysis: $e');
      debugPrint(trace.toString());
      return false;
    }
  }

  /// Load recent form analyses for a user.
  ///
  /// [uid] - User's UID
  /// [limit] - Maximum number of analyses to return (default 5)
  Future<List<FormAnalysisRecord>> loadRecentAnalyses(
    String uid, {
    int limit = 5,
  }) async {
    try {
      debugPrint('[FormAnalysisRepo] Loading recent analyses for user $uid');

      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('$kUsersCollection/$uid/$kFormAnalysesCollection')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('[FormAnalysisRepo] Timeout loading analyses');
              throw Exception('Timeout loading analyses');
            },
          );

      final List<FormAnalysisRecord> records = snapshot.docs
          .map((doc) => FormAnalysisRecord.fromJson(doc.data()))
          .toList();

      debugPrint('[FormAnalysisRepo] Loaded ${records.length} analyses');
      return records;
    } catch (e, trace) {
      debugPrint('[FormAnalysisRepo] Error loading analyses: $e');
      debugPrint(trace.toString());
      return [];
    }
  }

  /// Load a specific form analysis by ID.
  ///
  /// [uid] - User's UID
  /// [analysisId] - The analysis ID to load
  Future<FormAnalysisRecord?> loadAnalysisById(
    String uid,
    String analysisId,
  ) async {
    try {
      debugPrint('[FormAnalysisRepo] Loading analysis $analysisId');

      final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection('$kUsersCollection/$uid/$kFormAnalysesCollection')
          .doc(analysisId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('[FormAnalysisRepo] Timeout loading analysis');
              throw Exception('Timeout loading analysis');
            },
          );

      if (!doc.exists || doc.data() == null) {
        debugPrint('[FormAnalysisRepo] Analysis not found');
        return null;
      }

      return FormAnalysisRecord.fromJson(doc.data()!);
    } catch (e, trace) {
      debugPrint('[FormAnalysisRepo] Error loading analysis: $e');
      debugPrint(trace.toString());
      return null;
    }
  }

  /// Upload an image to Cloud Storage and return the download URL.
  Future<String?> _uploadImage({
    required String uid,
    required String analysisId,
    required String checkpointId,
    required String imageName,
    String? base64Data,
  }) async {
    if (base64Data == null || base64Data.isEmpty) {
      return null;
    }

    try {
      // Decode base64 to bytes
      final Uint8List bytes = base64Decode(base64Data);

      // Upload to Cloud Storage
      final String path =
          'form_analyses/$uid/$analysisId/${checkpointId}_$imageName.jpg';
      final Reference ref = _storage.ref().child(path);

      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Get download URL
      final String downloadUrl = await ref.getDownloadURL();
      debugPrint('[FormAnalysisRepo] Uploaded image: $path');
      return downloadUrl;
    } catch (e) {
      debugPrint('[FormAnalysisRepo] Error uploading image $imageName: $e');
      return null;
    }
  }

  /// Build angle deviations map from AngleDeviations object.
  Map<String, double>? _buildAngleDeviationsMap(AngleDeviations deviations) {
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
  String? _getWorstSeverity(List<CheckpointRecord> checkpoints) {
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
  List<String> _aggregateTopTips(List<CheckpointRecord> checkpoints) {
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
