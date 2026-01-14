import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pose_analysis_response.dart';

/// Client for the Cloud Run pose analysis API
class PoseAnalysisApiClient {
  PoseAnalysisApiClient({
    String? baseUrl,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl ?? _defaultBaseUrl,
        _httpClient = httpClient ?? http.Client();

  // TODO: Update this to your Cloud Run URL after deployment
  static const String _defaultBaseUrl = 'http://localhost:8080';

  final String _baseUrl;
  final http.Client _httpClient;

  /// Analyze a video file for disc golf form
  ///
  /// [videoFile] - The video file to analyze
  /// [throwType] - Type of throw (currently only 'backhand' supported)
  /// [cameraAngle] - Camera angle enum value
  /// [sessionId] - Unique session identifier
  /// [userId] - User identifier
  Future<PoseAnalysisResponse> analyzeVideo({
    required File videoFile,
    required String throwType,
    required CameraAngle cameraAngle,
    required String sessionId,
    required String userId,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/form-analysis/analyze-file');

    // Create multipart request
    final http.MultipartRequest request = http.MultipartRequest('POST', uri);

    // Add video file
    request.files.add(
      await http.MultipartFile.fromPath('video', videoFile.path),
    );

    // Add form fields
    request.fields['throw_type'] = throwType;
    request.fields['camera_angle'] = cameraAngle.toApiString();
    request.fields['session_id'] = sessionId;
    request.fields['user_id'] = userId;

    try {
      // Send request with timeout
      final http.StreamedResponse streamedResponse = await request.send().timeout(
        const Duration(minutes: 5), // Video analysis can take time
        onTimeout: () {
          throw PoseAnalysisException(
            'Request timed out. Video analysis is taking too long.',
          );
        },
      );

      // Read response
      final http.Response response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;

        // Debug: Print raw response structure
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('📥 RAW POSE ANALYSIS RESPONSE:');
        debugPrint('Status: ${json['status']}');
        debugPrint('Checkpoints count: ${(json['checkpoints'] as List?)?.length ?? 0}');

        // 🔍 CHECK FOR THUMBNAIL - THIS IS CRITICAL
        debugPrint('');
        debugPrint('🖼️  THUMBNAIL CHECK:');
        debugPrint('   - round_thumbnail_base64 exists: ${json.containsKey('round_thumbnail_base64')}');
        if (json.containsKey('round_thumbnail_base64')) {
          final dynamic thumbnailValue = json['round_thumbnail_base64'];
          if (thumbnailValue == null) {
            debugPrint('   - Value: NULL');
          } else if (thumbnailValue is String) {
            debugPrint('   - Value type: String');
            debugPrint('   - Length: ${thumbnailValue.length} characters');
            debugPrint('   - First 50 chars: ${thumbnailValue.substring(0, thumbnailValue.length > 50 ? 50 : thumbnailValue.length)}...');
            debugPrint('   - Looks like base64: ${thumbnailValue.startsWith('/9j/') || thumbnailValue.startsWith('iVBORw')}');
          } else {
            debugPrint('   - Value type: ${thumbnailValue.runtimeType}');
          }
        } else {
          debugPrint('   - ❌ KEY NOT FOUND IN RESPONSE!');
          debugPrint('   - Available top-level keys: ${json.keys.toList()}');
        }
        debugPrint('');

        if (json['checkpoints'] != null && (json['checkpoints'] as List).isNotEmpty) {
          final Map<String, dynamic> firstCheckpoint = (json['checkpoints'] as List).first as Map<String, dynamic>;
          debugPrint('First checkpoint keys: ${firstCheckpoint.keys.toList()}');
          debugPrint('First checkpoint_id: ${firstCheckpoint['checkpoint_id']}');
          debugPrint('First checkpoint_name: ${firstCheckpoint['checkpoint_name']}');
          debugPrint('Deviations type: ${firstCheckpoint['deviations'].runtimeType}');
          debugPrint('Deviations: ${firstCheckpoint['deviations']}');
        }
        debugPrint('═══════════════════════════════════════════════════════');

        return PoseAnalysisResponse.fromJson(json);
      } else {
        // Try to parse error message from response
        String errorMessage = 'Analysis failed with status ${response.statusCode}';
        try {
          final Map<String, dynamic> errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorJson['detail'] as String? ?? errorMessage;
        } catch (_) {
          // Use default error message
        }
        throw PoseAnalysisException(errorMessage);
      }
    } on SocketException catch (e) {
      throw PoseAnalysisException(
        'Network error: Could not connect to analysis server. ${e.message}',
      );
    } on http.ClientException catch (e) {
      throw PoseAnalysisException(
        'HTTP error: ${e.message}',
      );
    }
  }

  /// Analyze a video using base64 encoding (alternative method)
  Future<PoseAnalysisResponse> analyzeVideoBase64({
    required File videoFile,
    required String throwType,
    required CameraAngle cameraAngle,
    required String sessionId,
    required String userId,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/form-analysis/analyze');

    // Read and encode video
    final List<int> videoBytes = await videoFile.readAsBytes();
    final String videoBase64 = base64Encode(videoBytes);

    // Get video format from extension
    final String extension = videoFile.path.split('.').last.toLowerCase();
    final String videoFormat = _mapExtensionToFormat(extension);

    final Map<String, dynamic> requestBody = {
      'video_base64': videoBase64,
      'video_format': videoFormat,
      'throw_type': throwType,
      'camera_angle': cameraAngle.toApiString(),
      'session_id': sessionId,
      'user_id': userId,
    };

    try {
      final http.Response response = await _httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw PoseAnalysisException(
            'Request timed out. Video analysis is taking too long.',
          );
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
        return PoseAnalysisResponse.fromJson(json);
      } else {
        String errorMessage = 'Analysis failed with status ${response.statusCode}';
        try {
          final Map<String, dynamic> errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorJson['detail'] as String? ?? errorMessage;
        } catch (_) {}
        throw PoseAnalysisException(errorMessage);
      }
    } on SocketException catch (e) {
      throw PoseAnalysisException(
        'Network error: Could not connect to analysis server. ${e.message}',
      );
    }
  }

  /// Check if the analysis server is healthy
  Future<bool> healthCheck() async {
    try {
      final Uri uri = Uri.parse('$_baseUrl/health');
      final http.Response response = await _httpClient.get(uri).timeout(
        const Duration(seconds: 10),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  String _mapExtensionToFormat(String extension) {
    switch (extension) {
      case 'mp4':
        return 'mp4';
      case 'mov':
        return 'mov';
      case 'avi':
        return 'avi';
      case 'webm':
        return 'webm';
      case 'm4v':
        return 'm4v';
      case '3gp':
        return '3gp';
      default:
        return 'mp4';
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

/// Exception for pose analysis errors
class PoseAnalysisException implements Exception {
  PoseAnalysisException(this.message);
  final String message;

  @override
  String toString() => 'PoseAnalysisException: $message';
}
