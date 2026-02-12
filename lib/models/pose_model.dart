import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

/// Pose detection mode for form analysis.
///
/// Controls the accuracy vs speed tradeoff for pose detection.
enum PoseModel {
  /// Standard pose detection mode.
  /// Faster processing with good accuracy.
  @JsonValue('standard')
  standard,

  /// Precise pose detection mode.
  /// Higher accuracy but slower processing.
  @JsonValue('advanced')
  advanced,

  /// Professional pose detection mode.
  /// Highest accuracy, slowest processing.
  @JsonValue('professional')
  professional;

  /// Returns a human-readable display name.
  String get displayName {
    switch (this) {
      case PoseModel.standard:
        return 'Standard';
      case PoseModel.advanced:
        return 'Advanced';
      case PoseModel.professional:
        return 'Pro';
    }
  }

  /// Returns the icon for this pose model.
  IconData get icon => Icons.auto_awesome;

  /// Returns the primary (darker) color for this pose model.
  Color get color {
    switch (this) {
      case PoseModel.standard:
        return const Color(0xFF137e66); // Teal (matches handedness auto)
      case PoseModel.advanced:
        return const Color(0xFF3A6BA6); // Darker blue
      case PoseModel.professional:
        return const Color(0xFF9A7A28); // Darker gold
    }
  }

  /// Returns the light color for gradient (right side).
  Color get lightColor {
    switch (this) {
      case PoseModel.standard:
        return const Color(0xFF1A9E80); // Teal light (matches handedness auto)
      case PoseModel.advanced:
        return const Color(0xFF5A8AC8); // Blue light
      case PoseModel.professional:
        return const Color(0xFFC4A048); // Gold light
    }
  }

  /// Returns a description of what the pose model represents.
  String get description {
    switch (this) {
      case PoseModel.standard:
        return 'Faster processing with good accuracy';
      case PoseModel.advanced:
        return 'Higher accuracy but slower processing';
      case PoseModel.professional:
        return 'Highest accuracy, slowest processing';
    }
  }

  /// Returns the API/JSON string value.
  /// This is the value sent to the backend and stored in Firestore.
  String toApiString() {
    switch (this) {
      case PoseModel.standard:
        return 'standard';
      case PoseModel.advanced:
        return 'advanced';
      case PoseModel.professional:
        return 'professional';
    }
  }

  /// Parses API string values: "standard", "advanced", or "professional"
  static PoseModel? fromApiString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'standard':
        return PoseModel.standard;
      case 'advanced':
        return PoseModel.advanced;
      case 'professional':
        return PoseModel.professional;
      default:
        return null;
    }
  }
}
