import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/endpoints/ai_endpoints.dart';
import 'package:turbo_disc_golf/models/error/app_error_type.dart';
import 'package:turbo_disc_golf/models/error/error_context.dart';
import 'package:turbo_disc_golf/models/error/error_severity.dart';
import 'package:turbo_disc_golf/services/error_logging/error_logging_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';

class BackendLLMService {
  /// Converts a request object to a Firebase-safe JSON map.
  /// Uses jsonEncode/jsonDecode to ensure all nested types are primitive JSON types.
  Map<String, dynamic> _toFirebaseSafeJson(Map<String, dynamic> json) {
    return jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
  }

  Future<ParseRoundDataResponse?> parseRoundData({
    required ParseRoundDataRequest request,
  }) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'parseRoundData',
      );
      final Map<String, dynamic> safeJson = _toFirebaseSafeJson(
        request.toJson(),
      );
      final HttpsCallableResult result = await callable.call(safeJson);
      return ParseRoundDataResponse.fromJson(
        Map<String, dynamic>.from(result.data as Map),
      );
    } catch (e, trace) {
      if (!_handleRateLimitError(e)) {
        _logError(e, trace, operation: 'parseRoundData');
      }
      return null;
    }
  }

  Future<GenerateRoundStoryResponse?> generateRoundStory({
    required GenerateRoundStoryRequest request,
  }) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'generateRoundStory',
      );

      final Map<String, dynamic> safeJson = _toFirebaseSafeJson(
        request.toJson(),
      );
      final HttpsCallableResult result = await callable.call(safeJson);

      debugPrint('got round story response, raw data:');
      debugPrint(result.data.toString());
      return GenerateRoundStoryResponse.fromJson(
        Map<String, dynamic>.from(result.data as Map),
      );
    } catch (e, trace) {
      if (!_handleRateLimitError(e)) {
        _logError(e, trace, operation: 'generateRoundStory');
      }
      return null;
    }
  }

  Future<GenerateRoundJudgmentResponse?> generateRoundJudgment({
    required GenerateRoundJudgmentRequest request,
  }) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'generateRoundJudgment',
      );
      debugPrint('[generateRoundJudgment] request json: ${request.toJson()}');
      final Map<String, dynamic> safeJson = _toFirebaseSafeJson(
        request.toJson(),
      );
      final HttpsCallableResult result = await callable.call(safeJson);
      return GenerateRoundJudgmentResponse.fromJson(
        Map<String, dynamic>.from(result.data as Map),
      );
    } catch (e, trace) {
      if (!_handleRateLimitError(e)) {
        _logError(e, trace, operation: 'generateRoundJudgment');
      }
      return null;
    }
  }

  /// Returns true if the error was a rate limit error and was handled.
  bool _handleRateLimitError(dynamic e) {
    if (e is FirebaseFunctionsException && e.code == 'resource-exhausted') {
      final Map<String, dynamic>? details =
          e.details != null ? Map<String, dynamic>.from(e.details as Map) : null;
      final int retryAfterSeconds = details?['retryAfterSeconds'] as int? ?? 60;

      String message;
      if (retryAfterSeconds >= 60) {
        final int minutes = (retryAfterSeconds / 60).ceil();
        message = 'Too many requests. Try again in $minutes minute${minutes > 1 ? 's' : ''}.';
      } else {
        message = 'Too many requests. Try again in $retryAfterSeconds seconds.';
      }

      locator.get<ToastService>().showWarning(message);
      return true;
    }
    return false;
  }

  /// Log LLM errors to Crashlytics with context
  void _logError(
    dynamic exception,
    StackTrace stackTrace, {
    required String operation,
    Map<String, dynamic>? customData,
  }) {
    try {
      locator.get<ErrorLoggingService>().logError(
        exception: exception,
        stackTrace: stackTrace,
        type: AppErrorType.network,
        severity: ErrorSeverity.error,
        context: ErrorContext(
          customData: {
            'llm_service': 'gemini',
            'operation': operation,
            ...?customData,
          },
        ),
        reason: 'Gemini API call failed: $operation',
      );
    } catch (e) {
      // Error logging should never crash the app
      debugPrint('Failed to log error to Crashlytics: $e');
    }
  }
}
