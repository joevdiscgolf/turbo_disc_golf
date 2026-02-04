import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/camera_angle.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_analysis_response_v2.dart';
import 'package:turbo_disc_golf/models/error/app_error_type.dart';
import 'package:turbo_disc_golf/models/error/error_context.dart';
import 'package:turbo_disc_golf/models/handedness.dart';
import 'package:turbo_disc_golf/services/error_logging/error_logging_service.dart';

/// Client for the Cloud Run pose analysis API
class PoseAnalysisApiClient {
  PoseAnalysisApiClient({String? baseUrl, http.Client? httpClient})
    : _baseUrl = baseUrl ?? _localBaseUrl,
      _httpClient = httpClient ?? http.Client();

  static const String _productionUrl =
      'https://score-sensei-api-ys5bxtccka-uc.a.run.app';
  static const String _localBaseUrl = 'http://localhost:8080';

  final String _baseUrl;
  final http.Client _httpClient;

  /// Returns the appropriate base URL based on the runtime environment.
  /// - Physical device + release mode → production URL
  /// - Physical device + debug mode → LOCAL_API_URL from .env (required)
  /// - Simulator/emulator → localhost
  static Future<String> getDefaultBaseUrl() async {
    if (Platform.isIOS || Platform.isAndroid) {
      final bool isPhysical = await _isPhysicalDevice();
      if (isPhysical) {
        if (!kDebugMode) {
          return _productionUrl;
        }
        // Physical device in debug mode - use LOCAL_API_URL from .env
        final String? localApiUrl = dotenv.env['LOCAL_API_URL'];
        if (localApiUrl != null && localApiUrl.isNotEmpty) {
          debugPrint('📱 Physical device debug mode - using LOCAL_API_URL: $localApiUrl');
          return localApiUrl;
        }
        // No LOCAL_API_URL configured - warn and fall back to production
        debugPrint('⚠️ Physical device in debug mode but LOCAL_API_URL not set in .env');
        debugPrint('   Add LOCAL_API_URL=http://YOUR_MAC_IP:8080 to .env to use local backend');
        debugPrint('   Falling back to production URL');
        return _productionUrl;
      }
    }
    return _localBaseUrl;
  }

  static Future<bool> _isPhysicalDevice() async {
    if (Platform.isIOS) {
      final IosDeviceInfo info = await DeviceInfoPlugin().iosInfo;
      return info.isPhysicalDevice;
    }
    if (Platform.isAndroid) {
      final AndroidDeviceInfo info = await DeviceInfoPlugin().androidInfo;
      return info.isPhysicalDevice;
    }
    return false;
  }

  /// Returns auth headers for API requests.
  /// Always includes auth headers if user is authenticated.
  /// Throws if production URL and user is not authenticated.
  Future<Map<String, String>> _getAuthHeaders() async {
    final bool isProduction = _baseUrl.contains('run.app');

    final String? idToken = await FirebaseAuth.instance.currentUser
        ?.getIdToken();

    if (idToken == null) {
      if (isProduction) {
        throw PoseAnalysisException(
          'Authentication required. Please sign in to use form analysis.',
        );
      }
      // Local development without auth - return empty headers
      return {};
    }

    return {'Authorization': 'Bearer $idToken'};
  }

  /// Analyze a video file for disc golf form
  ///
  /// [videoFile] - The video file to analyze
  /// [throwType] - Type of throw (currently only 'backhand' supported)
  /// [cameraAngle] - Camera angle enum value
  /// [handedness] - Whether the player throws right or left-handed (null for auto-detect)
  /// [sessionId] - Unique session identifier
  /// [userId] - User identifier
  /// [proPlayerId] - Optional pro player ID for reference comparison (e.g., 'paul_mcbeth')
  Future<FormAnalysisResponseV2> analyzeVideo({
    required File videoFile,
    required String throwType,
    required CameraAngle cameraAngle,
    Handedness? handedness,
    required String sessionId,
    required String userId,
    String? proPlayerId,
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
    if (handedness != null) {
      request.fields['handedness'] = handedness.toApiString();
    }
    request.fields['session_id'] = sessionId;
    request.fields['user_id'] = userId;
    if (proPlayerId != null) {
      request.fields['pro_player_id'] = proPlayerId;
    }

    // Add auth headers for production
    final Map<String, String> authHeaders = await _getAuthHeaders();
    request.headers.addAll(authHeaders);

    // Debug: Log request details
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📤 POSE ANALYSIS REQUEST:');
    debugPrint('   URL: $uri');
    debugPrint('   Fields: ${request.fields}');
    debugPrint(
      '   Files: ${request.files.map((f) => '${f.field}: ${f.filename} (${f.length} bytes)').toList()}',
    );
    debugPrint('═══════════════════════════════════════════════════════');

    try {
      // Send request with timeout
      final http.StreamedResponse streamedResponse = await request
          .send()
          .timeout(const Duration(minutes: 5));

      // Read response
      final http.Response response = await http.Response.fromStream(
        streamedResponse,
      );

      // Debug: Log response details
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📥 POSE ANALYSIS RESPONSE:');
      debugPrint('   Status Code: ${response.statusCode}');
      debugPrint('   Headers: ${response.headers}');
      if (response.statusCode != 200) {
        debugPrint('   Body: ${response.body}');
      }
      debugPrint('═══════════════════════════════════════════════════════');

      if (response.statusCode == 200) {
        final Map<String, dynamic> json =
            jsonDecode(response.body) as Map<String, dynamic>;

        // Debug: Print raw response structure
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('📥 RAW POSE ANALYSIS RESPONSE:');
        debugPrint('Status: ${json['status']}');
        debugPrint(
          'Checkpoints count: ${(json['checkpoints'] as List?)?.length ?? 0}',
        );

        // 🔍 CHECK FOR THUMBNAIL - THIS IS CRITICAL
        debugPrint('');
        debugPrint('🖼️  THUMBNAIL CHECK:');
        debugPrint(
          '   - round_thumbnail_base64 exists: ${json.containsKey('round_thumbnail_base64')}',
        );
        if (json.containsKey('round_thumbnail_base64')) {
          final dynamic thumbnailValue = json['round_thumbnail_base64'];
          if (thumbnailValue == null) {
            debugPrint('   - Value: NULL');
          } else if (thumbnailValue is String) {
            debugPrint('   - Value type: String');
            debugPrint('   - Length: ${thumbnailValue.length} characters');
            debugPrint(
              '   - First 50 chars: ${thumbnailValue.substring(0, thumbnailValue.length > 50 ? 50 : thumbnailValue.length)}...',
            );
            debugPrint(
              '   - Looks like base64: ${thumbnailValue.startsWith('/9j/') || thumbnailValue.startsWith('iVBORw')}',
            );
          } else {
            debugPrint('   - Value type: ${thumbnailValue.runtimeType}');
          }
        } else {
          debugPrint('   - ❌ KEY NOT FOUND IN RESPONSE!');
          debugPrint('   - Available top-level keys: ${json.keys.toList()}');
        }
        debugPrint('');

        if (json['checkpoints'] != null &&
            (json['checkpoints'] as List).isNotEmpty) {
          final Map<String, dynamic> firstCheckpoint =
              (json['checkpoints'] as List).first as Map<String, dynamic>;
          debugPrint('First checkpoint keys: ${firstCheckpoint.keys.toList()}');
          debugPrint(
            'First checkpoint_id: ${firstCheckpoint['checkpoint_id']}',
          );
          debugPrint(
            'First checkpoint_name: ${firstCheckpoint['checkpoint_name']}',
          );
          debugPrint(
            'Deviations type: ${firstCheckpoint['deviations'].runtimeType}',
          );
          debugPrint('Deviations: ${firstCheckpoint['deviations']}');
        }
        debugPrint('═══════════════════════════════════════════════════════');

        return FormAnalysisResponseV2.fromJson(json);
      } else {
        // Log technical details for debugging
        debugPrint('❌ POSE ANALYSIS ERROR:');
        debugPrint('   Status: ${response.statusCode}');
        debugPrint('   Raw body: ${response.body}');
        String? serverMessage;
        try {
          final Map<String, dynamic> errorJson =
              jsonDecode(response.body) as Map<String, dynamic>;
          debugPrint('   Parsed error JSON: $errorJson');
          serverMessage =
              errorJson['detail'] as String? ??
              errorJson['error_message'] as String? ??
              errorJson['message'] as String?;
          debugPrint('   Server message: $serverMessage');
        } catch (parseError) {
          debugPrint('   Failed to parse error body: $parseError');
        }

        // Log to Crashlytics
        final ErrorLoggingService errorLogger = locator
            .get<ErrorLoggingService>();
        await errorLogger.logError(
          exception: Exception(
            'Form analysis API error: ${response.statusCode} - $serverMessage',
          ),
          type: AppErrorType.network,
          reason: 'Form analysis API returned status ${response.statusCode}',
          context: ErrorContext(
            screenName: 'Form Analysis',
            customData: {
              'status_code': response.statusCode,
              'server_message': serverMessage,
              'session_id': sessionId,
              'camera_angle': cameraAngle.toApiString(),
              'handedness': handedness?.toApiString() ?? 'auto',
            },
          ),
        );

        // User-friendly error message
        throw PoseAnalysisException(
          'Something went wrong analyzing your video. Please try again.',
        );
      }
    } on TimeoutException catch (e, stackTrace) {
      debugPrint('❌ Request timed out after 5 minutes');

      // Log to Crashlytics
      final ErrorLoggingService errorLogger = locator
          .get<ErrorLoggingService>();
      await errorLogger.logError(
        exception: e,
        stackTrace: stackTrace,
        type: AppErrorType.network,
        reason: 'Form analysis request timed out',
        context: ErrorContext(
          screenName: 'Form Analysis',
          customData: {
            'timeout_duration': '5 minutes',
            'session_id': sessionId,
            'camera_angle': cameraAngle.toApiString(),
            'handedness': handedness?.toApiString() ?? 'auto',
          },
        ),
      );

      throw PoseAnalysisException(
        'Analysis is taking longer than expected. Please try again with a shorter video.',
      );
    } on SocketException catch (e, stackTrace) {
      debugPrint('❌ SOCKET EXCEPTION: ${e.message}');
      debugPrint('   Address: ${e.address}');
      debugPrint('   Port: ${e.port}');
      debugPrint('   OS Error: ${e.osError}');

      // Log to Crashlytics
      final ErrorLoggingService errorLogger = locator
          .get<ErrorLoggingService>();
      await errorLogger.logError(
        exception: e,
        stackTrace: stackTrace,
        type: AppErrorType.network,
        reason: 'Socket exception during form analysis',
        context: ErrorContext(
          screenName: 'Form Analysis',
          customData: {
            'socket_message': e.message,
            'address': e.address?.toString(),
            'port': e.port,
            'os_error': e.osError?.toString(),
            'session_id': sessionId,
          },
        ),
      );

      throw PoseAnalysisException(
        'Unable to reach the analysis service. Please check your connection and try again.',
      );
    } on http.ClientException catch (e, stackTrace) {
      debugPrint('❌ HTTP CLIENT EXCEPTION: ${e.message}');
      debugPrint('   URI: ${e.uri}');

      // Log to Crashlytics
      final ErrorLoggingService errorLogger = locator
          .get<ErrorLoggingService>();
      await errorLogger.logError(
        exception: e,
        stackTrace: stackTrace,
        type: AppErrorType.network,
        reason: 'HTTP client exception during form analysis',
        context: ErrorContext(
          screenName: 'Form Analysis',
          customData: {
            'http_message': e.message,
            'uri': e.uri?.toString(),
            'session_id': sessionId,
          },
        ),
      );

      throw PoseAnalysisException(
        'Unable to reach the analysis service. Please check your connection and try again.',
      );
    } on PoseAnalysisException {
      // Re-throw PoseAnalysisException without additional logging (already logged above)
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ UNEXPECTED ERROR: $e');
      debugPrint('   Stack trace: $stackTrace');

      // Log to Crashlytics
      final ErrorLoggingService errorLogger = locator
          .get<ErrorLoggingService>();
      await errorLogger.logError(
        exception: e,
        stackTrace: stackTrace,
        type: AppErrorType.network,
        reason: 'Unexpected error during form analysis',
        context: ErrorContext(
          screenName: 'Form Analysis',
          customData: {
            'session_id': sessionId,
            'camera_angle': cameraAngle.toApiString(),
            'handedness': handedness?.toApiString() ?? 'auto',
          },
        ),
      );

      throw PoseAnalysisException(
        'Something went wrong analyzing your video. Please try again.',
      );
    }
  }

  /// Analyze a video using base64 encoding (alternative method)
  Future<FormAnalysisResponseV2> analyzeVideoBase64({
    required File videoFile,
    required String throwType,
    required CameraAngle cameraAngle,
    Handedness? handedness,
    required String sessionId,
    required String userId,
    String? proPlayerId,
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
      if (handedness != null) 'handedness': handedness.toApiString(),
      'session_id': sessionId,
      'user_id': userId,
      if (proPlayerId != null) 'pro_player_id': proPlayerId,
    };

    // Add auth headers for production
    final Map<String, String> authHeaders = await _getAuthHeaders();

    // Debug: Log request details (without the base64 data)
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📤 POSE ANALYSIS REQUEST (Base64):');
    debugPrint('   URL: $uri');
    debugPrint('   video_format: $videoFormat');
    debugPrint('   video_base64 length: ${videoBase64.length} chars');
    debugPrint('   throw_type: $throwType');
    debugPrint('   camera_angle: ${cameraAngle.toApiString()}');
    debugPrint('   handedness: ${handedness?.toApiString() ?? 'auto'}');
    debugPrint('   session_id: $sessionId');
    debugPrint('   user_id: $userId');
    debugPrint('   pro_player_id: $proPlayerId');
    debugPrint('═══════════════════════════════════════════════════════');

    try {
      final http.Response response = await _httpClient
          .post(
            uri,
            headers: {'Content-Type': 'application/json', ...authHeaders},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(minutes: 5));

      // Debug: Log response details
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📥 POSE ANALYSIS RESPONSE (Base64):');
      debugPrint('   Status Code: ${response.statusCode}');
      debugPrint('   Headers: ${response.headers}');
      if (response.statusCode != 200) {
        debugPrint('   Body: ${response.body}');
      }
      debugPrint('═══════════════════════════════════════════════════════');

      if (response.statusCode == 200) {
        final Map<String, dynamic> json =
            jsonDecode(response.body) as Map<String, dynamic>;
        return FormAnalysisResponseV2.fromJson(json);
      } else {
        // Log technical details for debugging
        debugPrint('❌ POSE ANALYSIS ERROR (Base64):');
        debugPrint('   Status: ${response.statusCode}');
        debugPrint('   Raw body: ${response.body}');
        String? serverMessage;
        try {
          final Map<String, dynamic> errorJson =
              jsonDecode(response.body) as Map<String, dynamic>;
          debugPrint('   Parsed error JSON: $errorJson');
          serverMessage =
              errorJson['detail'] as String? ??
              errorJson['error_message'] as String? ??
              errorJson['message'] as String?;
          debugPrint('   Server message: $serverMessage');
        } catch (parseError) {
          debugPrint('   Failed to parse error body: $parseError');
        }

        // Log to Crashlytics
        final ErrorLoggingService errorLogger = locator
            .get<ErrorLoggingService>();
        await errorLogger.logError(
          exception: Exception(
            'Form analysis API error (Base64): ${response.statusCode} - $serverMessage',
          ),
          type: AppErrorType.network,
          reason:
              'Form analysis API (Base64) returned status ${response.statusCode}',
          context: ErrorContext(
            screenName: 'Form Analysis',
            customData: {
              'status_code': response.statusCode,
              'server_message': serverMessage,
              'session_id': sessionId,
              'camera_angle': cameraAngle.toApiString(),
              'handedness': handedness?.toApiString() ?? 'auto',
            },
          ),
        );

        // User-friendly error message
        throw PoseAnalysisException(
          'Something went wrong analyzing your video. Please try again.',
        );
      }
    } on TimeoutException catch (e, stackTrace) {
      debugPrint('❌ Request timed out after 5 minutes (Base64)');

      // Log to Crashlytics
      final ErrorLoggingService errorLogger = locator
          .get<ErrorLoggingService>();
      await errorLogger.logError(
        exception: e,
        stackTrace: stackTrace,
        type: AppErrorType.network,
        reason: 'Form analysis request timed out (Base64)',
        context: ErrorContext(
          screenName: 'Form Analysis',
          customData: {
            'timeout_duration': '5 minutes',
            'session_id': sessionId,
            'camera_angle': cameraAngle.toApiString(),
            'handedness': handedness?.toApiString() ?? 'auto',
          },
        ),
      );

      throw PoseAnalysisException(
        'Analysis is taking longer than expected. Please try again with a shorter video.',
      );
    } on SocketException catch (e, stackTrace) {
      debugPrint('❌ SOCKET EXCEPTION (Base64): ${e.message}');
      debugPrint('   Address: ${e.address}');
      debugPrint('   Port: ${e.port}');
      debugPrint('   OS Error: ${e.osError}');

      // Log to Crashlytics
      final ErrorLoggingService errorLogger = locator
          .get<ErrorLoggingService>();
      await errorLogger.logError(
        exception: e,
        stackTrace: stackTrace,
        type: AppErrorType.network,
        reason: 'Socket exception during form analysis (Base64)',
        context: ErrorContext(
          screenName: 'Form Analysis',
          customData: {
            'socket_message': e.message,
            'address': e.address?.toString(),
            'port': e.port,
            'os_error': e.osError?.toString(),
            'session_id': sessionId,
          },
        ),
      );

      throw PoseAnalysisException(
        'Unable to reach the analysis service. Please check your connection and try again.',
      );
    } on http.ClientException catch (e, stackTrace) {
      debugPrint('❌ HTTP CLIENT EXCEPTION (Base64): ${e.message}');
      debugPrint('   URI: ${e.uri}');

      // Log to Crashlytics
      final ErrorLoggingService errorLogger = locator
          .get<ErrorLoggingService>();
      await errorLogger.logError(
        exception: e,
        stackTrace: stackTrace,
        type: AppErrorType.network,
        reason: 'HTTP client exception during form analysis (Base64)',
        context: ErrorContext(
          screenName: 'Form Analysis',
          customData: {
            'http_message': e.message,
            'uri': e.uri?.toString(),
            'session_id': sessionId,
          },
        ),
      );

      throw PoseAnalysisException(
        'Unable to reach the analysis service. Please check your connection and try again.',
      );
    } on PoseAnalysisException {
      // Re-throw PoseAnalysisException without additional logging (already logged above)
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ UNEXPECTED ERROR (Base64): $e');
      debugPrint('   Stack trace: $stackTrace');

      // Log to Crashlytics
      final ErrorLoggingService errorLogger = locator
          .get<ErrorLoggingService>();
      await errorLogger.logError(
        exception: e,
        stackTrace: stackTrace,
        type: AppErrorType.network,
        reason: 'Unexpected error during form analysis (Base64)',
        context: ErrorContext(
          screenName: 'Form Analysis',
          customData: {
            'session_id': sessionId,
            'camera_angle': cameraAngle.toApiString(),
            'handedness': handedness?.toApiString() ?? 'auto',
          },
        ),
      );

      throw PoseAnalysisException(
        'Something went wrong analyzing your video. Please try again.',
      );
    }
  }

  /// Check if the analysis server is healthy
  Future<bool> healthCheck() async {
    try {
      final Uri uri = Uri.parse('$_baseUrl/health');
      final Map<String, String> authHeaders = await _getAuthHeaders();
      final http.Response response = await _httpClient
          .get(uri, headers: authHeaders)
          .timeout(const Duration(seconds: 10));
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
