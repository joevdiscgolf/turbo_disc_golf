/// Abstract protocol defining the contract for all LLM services
///
/// This protocol allows interchangeable use of different LLM providers
/// (Gemini, OpenAI, Claude, etc.) throughout the app.
abstract class LLMService {
  /// Get the last raw response from the LLM
  String? get lastRawResponse;

  /// Generate text content from a prompt
  ///
  /// [prompt] - The text prompt to send to the LLM
  /// [useFullModel] - Whether to use the full/flagship model vs lite version
  /// Returns generated text or null on failure
  Future<String?> generateContent({
    required String prompt,
    bool useFullModel = false,
  });

  /// Generate content with a video file
  ///
  /// [prompt] - The text prompt describing what to analyze
  /// [videoPath] - Absolute path to the video file
  /// Returns generated text or null on failure
  Future<String?> generateContentWithVideo({
    required String prompt,
    required String videoPath,
  });

  /// Generate content with an image file
  ///
  /// [prompt] - The text prompt describing what to analyze
  /// [imagePath] - Absolute path to the image file
  /// Returns generated text or null on failure
  Future<String?> generateContentWithImage({
    required String prompt,
    required String imagePath,
  });

  /// Test if the service is properly configured and can connect
  /// Returns true if connection succeeds
  Future<bool> testConnection();
}
