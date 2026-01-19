/// Enum representing different categories of errors in the application
enum AppErrorType {
  /// AI/LLM parsing failures (Gemini, ChatGPT responses)
  aiParsing,

  /// Story generation issues
  storyGeneration,

  /// Scorecard OCR extraction errors
  scorecardOCR,

  /// API/network errors
  network,

  /// Firebase/Firestore database errors
  database,

  /// Authentication errors
  authentication,

  /// Voice recognition service errors
  voiceRecognition,

  /// JSON/YAML data parsing errors
  dataParsing,

  /// UI/rendering errors
  ui,

  /// Uncategorized errors
  unknown;

  /// Get a human-readable display name for the error type
  String get displayName {
    switch (this) {
      case AppErrorType.aiParsing:
        return 'AI Parsing';
      case AppErrorType.storyGeneration:
        return 'Story Generation';
      case AppErrorType.scorecardOCR:
        return 'Scorecard OCR';
      case AppErrorType.network:
        return 'Network';
      case AppErrorType.database:
        return 'Database';
      case AppErrorType.authentication:
        return 'Authentication';
      case AppErrorType.voiceRecognition:
        return 'Voice Recognition';
      case AppErrorType.dataParsing:
        return 'Data Parsing';
      case AppErrorType.ui:
        return 'UI';
      case AppErrorType.unknown:
        return 'Unknown';
    }
  }
}
