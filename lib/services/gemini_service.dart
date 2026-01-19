import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/error/app_error_type.dart';
import 'package:turbo_disc_golf/models/error/error_context.dart';
import 'package:turbo_disc_golf/models/error/error_severity.dart';
import 'package:turbo_disc_golf/protocols/llm_service.dart';
import 'package:turbo_disc_golf/services/error_logging/error_logging_service.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

class GeminiService implements LLMService {
  late final GenerativeModel _textModel; // For text parsing
  late final GenerativeModel _visionModel; // For image + text (multimodal)

  static const String twoPointFiveFlashLiteModel = 'gemini-2.5-flash-lite';
  static const String twoPointFiveFlashModel = 'gemini-2.5-flash';
  static const String twoPointZeroFlashExpModel = 'gemini-2.0-flash-exp';
  static const String onePointFiveFlashModel = 'gemini-1.5-flash';
  static const String onePointFiveFlashLatestModel = 'gemini-1.5-flash-latest';
  static const String onePointZeroProVisionModel =
      'models/gemini-1.0-pro-vision';

  late final String _apiKey;

  String? _lastRawResponse; // Store the last raw response

  @override
  String? get lastRawResponse => _lastRawResponse;

  GeminiService({required String apiKey}) {
    _apiKey = apiKey;
    // Text model for voice transcript parsing
    _textModel = GenerativeModel(
      model: twoPointFiveFlashLiteModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3, // Lower temperature for more consistent parsing
        topK: 20,
        topP: 0.8,
        maxOutputTokens: 4096,
        // Removed responseMimeType to allow YAML responses
      ),
    );

    // Vision model for scorecard image and video processing
    // Using gemini-2.5-flash for multimodal tasks
    _visionModel = GenerativeModel(
      model: twoPointFiveFlashModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.2, // Low temperature for accurate but complete output
        topK: 20,
        topP: 0.9,
        maxOutputTokens: 8192, // Increased for complete form analysis YAML
      ),
    );
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

  @override
  Future<String?> generateContent({
    required String prompt,
    bool useFullModel = false,
  }) async {
    try {
      // Use full flash model if requested, otherwise use lite model
      if (useFullModel) {
        final String modelToUse = useGeminiFallbackModel
            ? twoPointZeroFlashExpModel
            : twoPointFiveFlashModel;
        final fullModel = GenerativeModel(
          model: modelToUse,
          apiKey: _apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.8, // Balanced for creative but complete output
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 8192, // Increased for complete YAML responses
          ),
        );
        return fullModel
            .generateContent([Content.text(prompt)])
            .then((response) => response.text);
      } else {
        return _textModel
            .generateContent([Content.text(prompt)])
            .then((response) => response.text);
      }
    } catch (e, trace) {
      debugPrint('Error generating content with Gemini');
      debugPrint(e.toString());
      debugPrint(trace.toString());

      _logError(
        e,
        trace,
        operation: 'generateContent',
        customData: {
          'use_full_model': useFullModel,
          'model_name': useFullModel
              ? (useGeminiFallbackModel
                  ? twoPointZeroFlashExpModel
                  : twoPointFiveFlashModel)
              : twoPointFiveFlashLiteModel,
        },
      );

      return null;
    }
  }

  /// Generate content with video (multimodal) - uses vision model
  /// Gemini 2.5 Flash supports video input up to 1 hour
  @override
  Future<String?> generateContentWithVideo({
    required String prompt,
    required String videoPath,
  }) async {
    try {
      // Load video bytes
      final File videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        debugPrint('Video file does not exist: $videoPath');
        return null;
      }

      final videoBytes = await videoFile.readAsBytes();

      // Determine MIME type based on file extension
      final String extension = videoPath.split('.').last.toLowerCase();
      String mimeType;
      switch (extension) {
        case 'mp4':
          mimeType = 'video/mp4';
          break;
        case 'mov':
          mimeType = 'video/quicktime';
          break;
        case 'avi':
          mimeType = 'video/x-msvideo';
          break;
        case 'webm':
          mimeType = 'video/webm';
          break;
        case 'm4v':
          mimeType = 'video/x-m4v';
          break;
        case '3gp':
          mimeType = 'video/3gpp';
          break;
        default:
          mimeType = 'video/mp4'; // Default fallback
      }

      debugPrint(
        'Sending video to Gemini: ${videoBytes.length} bytes, $mimeType',
      );

      // Create multimodal content with video
      final Content content = Content.multi([
        TextPart(prompt),
        DataPart(mimeType, videoBytes),
      ]);

      // Use vision model which supports video
      final GenerateContentResponse response = await _visionModel
          .generateContent([content]);
      _lastRawResponse = response.text;
      return response.text;
    } catch (e, trace) {
      debugPrint('Error generating content with video: $e');
      debugPrint(trace.toString());

      final Map<String, dynamic> customData = {
        'video_path': videoPath,
      };

      // Add video size if we successfully read it before the error
      try {
        final File videoFile = File(videoPath);
        if (await videoFile.exists()) {
          final videoBytes = await videoFile.readAsBytes();
          customData['video_size_bytes'] = videoBytes.length;
        }
      } catch (_) {}

      _logError(e, trace, operation: 'generateContentWithVideo', customData: customData);

      return null;
    }
  }

  /// Generate content with image (multimodal) - uses vision model
  @override
  Future<String?> generateContentWithImage({
    required String prompt,
    required String imagePath,
  }) async {
    try {
      // Load image bytes
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        debugPrint('Image file does not exist: $imagePath');
        return null;
      }

      final imageBytes = await imageFile.readAsBytes();

      // Determine MIME type based on file extension
      final extension = imagePath.split('.').last.toLowerCase();
      String mimeType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // Default fallback
      }

      // Create multimodal content
      final content = Content.multi([
        TextPart(prompt),
        DataPart(mimeType, imageBytes),
      ]);

      final response = await _visionModel.generateContent([content]);
      return response.text;
    } catch (e, trace) {
      debugPrint('Error generating content with image: $e');
      debugPrint(trace.toString());

      _logError(
        e,
        trace,
        operation: 'generateContentWithImage',
        customData: {'image_path': imagePath},
      );

      return null;
    }
  }

  // Test method to validate the service
  @override
  Future<bool> testConnection() async {
    try {
      final response = await _textModel.generateContent([
        Content.text('Reply with just "OK" to confirm the connection works.'),
      ]);
      return response.text?.contains('OK') ?? false;
    } catch (e) {
      debugPrint('Gemini connection test failed: $e');
      return false;
    }
  }
}
