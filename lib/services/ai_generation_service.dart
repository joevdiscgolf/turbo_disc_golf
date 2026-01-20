import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';

/// Unified interface for AI content generation.
///
/// This abstraction allows swapping between backend (cloud functions) and
/// frontend (local LLM) implementations transparently. The service locator
/// determines which implementation to use based on feature flags.
///
/// All methods return fully parsed, validated data - consumers don't need
/// to worry about YAML parsing or retry logic.
abstract class AIGenerationService {
  /// Generate a round story, automatically selecting the version (V1, V2, or V3)
  /// based on feature flags.
  ///
  /// Returns a complete [AIContent] object with the appropriate structured
  /// content field populated (structuredContent, structuredContentV2, or
  /// structuredContentV3).
  ///
  /// Returns null if generation fails after all retries.
  Future<AIContent?> generateRoundStory({
    required DGRound round,
    required RoundAnalysis analysis,
  });

  /// Generate a V3 story specifically.
  ///
  /// Use this when you explicitly want V3 format, regardless of feature flags.
  /// For most cases, prefer [generateRoundStory] which handles version selection.
  Future<AIContent?> generateRoundStoryV3({
    required DGRound round,
    required RoundAnalysis analysis,
  });

  /// Parse a voice transcript into structured round data.
  ///
  /// Returns a [PotentialDGRound] with parsed hole data, or null if parsing fails.
  ///
  /// Parameters:
  /// - [voiceTranscript]: The voice-to-text transcript to parse
  /// - [userBag]: User's disc bag for disc name matching
  /// - [course]: Optional course for context
  /// - [layoutId]: Optional layout ID for the course
  /// - [numHoles]: Expected number of holes (default 18)
  /// - [preParsedHoles]: Optional pre-parsed hole metadata from scorecard image
  Future<PotentialDGRound?> parseRoundDescription({
    required String voiceTranscript,
    required List<DGDisc> userBag,
    Course? course,
    String? layoutId,
    int numHoles = 18,
    List<HoleMetadata>? preParsedHoles,
  });

  /// Generate a judgment (roast or glaze) for a round.
  ///
  /// Returns the raw judgment content string (YAML format), or null if
  /// generation fails.
  ///
  /// Parameters:
  /// - [round]: The round to judge
  /// - [analysis]: Round analysis data
  /// - [shouldGlaze]: true for compliment (glaze), false for roast
  Future<String?> generateRoundJudgment({
    required DGRound round,
    required RoundAnalysis analysis,
    required bool shouldGlaze,
  });
}
