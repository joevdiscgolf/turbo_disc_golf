import 'package:flutter/foundation.dart';

/// Represents a progress update from the SSE stream during form analysis.
@immutable
class AnalysisProgress {
  const AnalysisProgress({
    required this.step,
    required this.progress,
    required this.message,
    this.timestamp,
  });

  /// The current step in the analysis pipeline (e.g., "uploading", "extracting", "analyzing")
  final String step;

  /// Progress as a decimal from 0.0 to 1.0
  final double progress;

  /// User-friendly message describing current activity
  final String message;

  /// Optional timestamp from the server
  final String? timestamp;

  /// Create an AnalysisProgress from JSON data
  factory AnalysisProgress.fromJson(Map<String, dynamic> json) {
    return AnalysisProgress(
      step: json['step'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] as String?,
    );
  }

  @override
  String toString() =>
      'AnalysisProgress(step: $step, progress: $progress, message: $message)';
}
