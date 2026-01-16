import 'dart:convert';
import 'dart:io';

import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/protocols/llm_service.dart';

/// OpenAI ChatGPT service implementation
///
/// Uses GPT-4o-mini by default for best value (GPT-4 quality at 2x Gemini cost)
/// Optional GPT-4o model available for premium quality (25x Gemini cost)
class ChatGPTService implements LLMService {
  // Model configurations
  /// Default model for stories - best value (GPT-4 quality at 2x Gemini cost)
  static const String gptFourOMini = 'gpt-4o-mini';

  /// Premium model for exceptional quality (25x Gemini cost)
  static const String gptFourO = 'gpt-4o';

  String? _lastRawResponse;

  @override
  String? get lastRawResponse => _lastRawResponse;

  ChatGPTService({required String apiKey}) {
    OpenAI.apiKey = apiKey;
  }

  @override
  Future<String?> generateContent({
    required String prompt,
    bool useFullModel = false,
  }) async {
    try {
      // Use gpt-4o for premium quality, gpt-4o-mini for default
      final String model = useFullModel ? gptFourO : gptFourOMini;

      final OpenAIChatCompletionModel completion =
          await OpenAI.instance.chat.create(
        model: model,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
            ],
          ),
        ],
        temperature: 0.8, // Creative, storytelling
        maxTokens: 8192,
      );

      final String? content =
          completion.choices.first.message.content?.first.text;
      _lastRawResponse = content;
      return content;
    } catch (e, trace) {
      debugPrint('Error generating content with ChatGPT: $e');
      debugPrint(trace.toString());
      return null;
    }
  }

  @override
  Future<String?> generateContentWithVideo({
    required String prompt,
    required String videoPath,
  }) async {
    // OpenAI vision API doesn't support video in the same way as Gemini
    // Keep using Gemini for video analysis
    throw UnimplementedError(
      'Video analysis not supported by OpenAI API. Use GeminiService for video processing.',
    );
  }

  @override
  Future<String?> generateContentWithImage({
    required String prompt,
    required String imagePath,
  }) async {
    try {
      // Load image and convert to base64
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        debugPrint('Image file does not exist: $imagePath');
        return null;
      }

      final imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // Determine MIME type based on file extension
      final String extension = imagePath.split('.').last.toLowerCase();
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

      // Create image URL for OpenAI
      final String imageUrl = 'data:$mimeType;base64,$base64Image';

      final OpenAIChatCompletionModel completion =
          await OpenAI.instance.chat.create(
        model: gptFourO, // Use gpt-4o for vision tasks
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
              OpenAIChatCompletionChoiceMessageContentItemModel.imageUrl(
                imageUrl,
              ),
            ],
          ),
        ],
        temperature: 0.2, // Lower temperature for accurate analysis
        maxTokens: 8192,
      );

      final String? content =
          completion.choices.first.message.content?.first.text;
      _lastRawResponse = content;
      return content;
    } catch (e, trace) {
      debugPrint('Error generating content with image: $e');
      debugPrint(trace.toString());
      return null;
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      final String? response = await generateContent(
        prompt: 'Reply with just "OK" to confirm the connection works.',
        useFullModel: false,
      );
      return response?.contains('OK') ?? false;
    } catch (e) {
      debugPrint('ChatGPT connection test failed: $e');
      return false;
    }
  }
}
