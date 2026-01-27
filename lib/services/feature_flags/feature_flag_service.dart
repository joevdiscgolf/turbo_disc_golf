import 'package:flutter/foundation.dart';
import 'package:turbo_disc_golf/models/feature_flags/feature_flag.dart';
import 'package:turbo_disc_golf/protocols/feature_flag_provider.dart';
import 'package:turbo_disc_golf/services/story_generator_service.dart';

/// Service that manages feature flags with synchronous access.
///
/// Pre-fetches all flags at startup into memory for fast synchronous access.
/// Debug-only flags automatically return false in release builds.
///
/// Usage:
/// ```dart
/// final flags = locator.get<FeatureFlagService>();
/// if (flags.storyV3Enabled) { ... }
/// ```
class FeatureFlagService {
  final FeatureFlagProvider _provider;
  final Map<FeatureFlag, dynamic> _cache = {};
  bool _initialized = false;

  FeatureFlagService({required FeatureFlagProvider provider})
    : _provider = provider;

  /// Initialize the service and fetch initial values.
  Future<bool> initialize() async {
    if (_initialized) return true;

    final bool success = await _provider.initialize();
    if (success) {
      _cacheAllValues();
    }
    _initialized = true;

    debugPrint(
      '[FeatureFlagService] Initialized with ${_cache.length} cached values',
    );

    return success;
  }

  /// Refresh flag values from the remote config server.
  Future<bool> refresh() async {
    final bool success = await _provider.fetchAndActivate();
    if (success) {
      _cacheAllValues();
    }
    return success;
  }

  void _cacheAllValues() {
    _cache.clear();
    for (final FeatureFlag flag in FeatureFlag.values) {
      final dynamic defaultValue = flag.defaultValue;
      if (defaultValue is bool) {
        _cache[flag] = _provider.getBool(flag);
      } else if (defaultValue is String) {
        _cache[flag] = _provider.getString(flag);
      } else if (defaultValue is int) {
        _cache[flag] = _provider.getInt(flag);
      } else if (defaultValue is double) {
        _cache[flag] = _provider.getDouble(flag);
      } else {
        _cache[flag] = defaultValue;
      }
    }
  }

  // ===== Generic Getters =====

  /// Get a boolean flag value. Debug-only flags return false in release builds.
  bool getBool(FeatureFlag flag) {
    // Debug-only flags return false in release builds
    if (flag.isDebugOnly && !kDebugMode) {
      return false;
    }
    return _cache[flag] as bool? ?? flag.defaultValue as bool;
  }

  /// Get a string flag value.
  String getString(FeatureFlag flag) {
    return _cache[flag] as String? ?? flag.defaultValue as String;
  }

  /// Get an integer flag value.
  int getInt(FeatureFlag flag) {
    return _cache[flag] as int? ?? flag.defaultValue as int;
  }

  /// Get a double flag value.
  double getDouble(FeatureFlag flag) {
    return _cache[flag] as double? ?? flag.defaultValue as double;
  }

  // ===== UI & Animation Toggles =====

  bool get shouldAnimateProgressIndicators =>
      getBool(FeatureFlag.shouldAnimateProgressIndicators);

  bool get useRoundReviewScreenV2 =>
      getBool(FeatureFlag.useRoundReviewScreenV2);

  bool get useHeroAnimationsForRoundReview =>
      getBool(FeatureFlag.useHeroAnimationsForRoundReview);

  bool get useCustomPageTransitionsForRoundReview =>
      getBool(FeatureFlag.useCustomPageTransitionsForRoundReview);

  bool get showRoundMetadataInfoBar =>
      getBool(FeatureFlag.showRoundMetadataInfoBar);

  bool get useAddThrowPanelV2 => getBool(FeatureFlag.useAddThrowPanelV2);

  bool get useAddRoundStepsPanel => getBool(FeatureFlag.useAddRoundStepsPanel);

  bool get autoStartListeningOnNextHole =>
      getBool(FeatureFlag.autoStartListeningOnNextHole);

  bool get showInlineMiniHoleGrid =>
      getBool(FeatureFlag.showInlineMiniHoleGrid);

  bool get showHoleProgressLabel => getBool(FeatureFlag.showHoleProgressLabel);

  bool get useBottomNavigationBar =>
      getBool(FeatureFlag.useBottomNavigationBar);

  bool get useRoundHistoryRowV2 => getBool(FeatureFlag.useRoundHistoryRowV2);

  bool get useBeautifulDatePicker =>
      getBool(FeatureFlag.useBeautifulDatePicker);

  bool get showHoleDistancesInScorecard =>
      getBool(FeatureFlag.showHoleDistancesInScorecard);

  bool get showDistancePreferences =>
      getBool(FeatureFlag.showDistancePreferences);

  bool get showProjectedScoreInRecordRound =>
      getBool(FeatureFlag.showProjectedScoreInRecordRound);

  bool get showHoleDetailCardInRecordRound =>
      getBool(FeatureFlag.showHoleDetailCardInRecordRound);

  bool get useThrowCardV2 => getBool(FeatureFlag.useThrowCardV2);

  /// Throw card layout style: 'inline', 'split', or empty for default (v2 with timeline)
  String get throwCardLayoutStyle =>
      getString(FeatureFlag.throwCardLayoutStyle);

  /// Throw timeline visual style: 'default', 'journey_rail', or 'flow_connectors'
  String get throwTimelineStyle => getString(FeatureFlag.throwTimelineStyle);

  bool get showMissingThrowDetailsInScoreDetail =>
      getBool(FeatureFlag.showMissingThrowDetailsInScoreDetail);

  bool get useFixedBottomNavInRecordRound =>
      getBool(FeatureFlag.useFixedBottomNavInRecordRound);

  bool get useFlatMicrophoneButton =>
      getBool(FeatureFlag.useFlatMicrophoneButton);

  bool get useRedesignedMentalGameCard =>
      getBool(FeatureFlag.useRedesignedMentalGameCard);

  bool get usePodiumDiscCard => getBool(FeatureFlag.usePodiumDiscCard);

  bool get drivesDetailScreenV2 => getBool(FeatureFlag.drivesDetailScreenV2);

  bool get useThrowTypeComparisonCard =>
      getBool(FeatureFlag.useThrowTypeComparisonCard);

  // ===== Voice Service =====

  bool get useIosVoiceService => getBool(FeatureFlag.useIosVoiceService);

  // ===== Course Search =====

  /// Debug-only: Uses test courses instead of MeiliSearch.
  /// Always returns false in release builds.
  bool get useTestCourseProvider => getBool(FeatureFlag.useTestCourseProvider);

  /// Uses Supabase for course search instead of MeiliSearch.
  bool get useSupabaseSearchProvider =>
      getBool(FeatureFlag.useSupabaseSearchProvider);

  /// Debug-only: Uses local Meili server on simulator.
  /// Always returns false in release builds.
  bool get useLocalMeiliSearchOnSimulator =>
      getBool(FeatureFlag.useLocalMeiliSearchOnSimulator);

  String get meiliLocalServerUrl => getString(FeatureFlag.meiliLocalServerUrl);

  // ===== Judgment/Roast Feature =====

  /// Debug-only: Uses mock judgment instead of real AI.
  /// Always returns false in release builds.
  bool get useMockJudgment => getBool(FeatureFlag.useMockJudgment);

  /// Force judgment type: 'roast', 'glaze', or empty for random.
  String? get forceJudgmentType {
    final String value = getString(FeatureFlag.forceJudgmentType);
    return value.isEmpty ? null : value;
  }

  bool get showQrCodeOnShareCard => getBool(FeatureFlag.showQrCodeOnShareCard);

  bool get useVerdictImages => getBool(FeatureFlag.useVerdictImages);

  String get shareCardQrUrl => getString(FeatureFlag.shareCardQrUrl);

  bool get useBottomShareActionBar =>
      getBool(FeatureFlag.useBottomShareActionBar);

  bool get showJudgmentPreparingAnimation =>
      getBool(FeatureFlag.showJudgmentPreparingAnimation);

  bool get enableFireEmojiSpin => getBool(FeatureFlag.enableFireEmojiSpin);

  // ===== LLM Configuration =====

  LLMProvider get defaultLLMProvider =>
      getString(FeatureFlag.defaultLLMProvider).toLLMProvider();

  LLMProvider get storyGenerationLLMProvider =>
      getString(FeatureFlag.storyGenerationLLMProvider).toLLMProvider();

  bool get useGeminiFallbackModel =>
      getBool(FeatureFlag.useGeminiFallbackModel);

  bool get generateAiContentFromBackend =>
      getBool(FeatureFlag.generateAiContentFromBackend);

  bool get expectParsedRoundFromBackend =>
      getBool(FeatureFlag.expectParsedRoundFromBackend);

  // ===== Story Feature =====

  bool get showStoryLoadingAnimation =>
      getBool(FeatureFlag.showStoryLoadingAnimation);

  bool get showElitePotentialCard =>
      getBool(FeatureFlag.showElitePotentialCard);

  bool get useStoryPosterShareCard =>
      getBool(FeatureFlag.useStoryPosterShareCard);

  bool get showWhatCouldHaveBeenCard =>
      getBool(FeatureFlag.showWhatCouldHaveBeenCard);

  bool get showWhatCouldHaveBeenEncouragement =>
      getBool(FeatureFlag.showWhatCouldHaveBeenEncouragement);

  bool get storyV2Enabled => getBool(FeatureFlag.storyV2Enabled);

  bool get storyV3Enabled => getBool(FeatureFlag.storyV3Enabled);

  bool get highlightActiveStorySection =>
      getBool(FeatureFlag.highlightActiveStorySection);

  bool get showStoryShareButton =>
      getBool(FeatureFlag.showStoryShareButton);

  // ===== Scorecard Import =====

  /// Debug-only: Uses test scorecard for import testing.
  /// Always returns false in release builds.
  bool get useTestScorecardForImport =>
      getBool(FeatureFlag.useTestScorecardForImport);

  String get testScorecardPath => getString(FeatureFlag.testScorecardPath);

  /// Debug-only: Uses mock scorecard data instead of AI parsing.
  /// Always returns false in release builds.
  bool get useMockScorecardData => getBool(FeatureFlag.useMockScorecardData);

  // ===== Map/Location =====

  bool get showMapLocationPicker => getBool(FeatureFlag.showMapLocationPicker);

  String get mapProvider => getString(FeatureFlag.mapProvider);

  // ===== Form Analysis =====

  bool get useFormAnalysisTab => getBool(FeatureFlag.useFormAnalysisTab);

  bool get usePoseAnalysisBackend =>
      getBool(FeatureFlag.usePoseAnalysisBackend);

  String get poseAnalysisBaseUrl => getString(FeatureFlag.poseAnalysisBaseUrl);

  /// Debug-only: Shows test button in form analysis.
  /// Always returns false in release builds.
  bool get showFormAnalysisTestButton =>
      getBool(FeatureFlag.showFormAnalysisTestButton);

  String get testFormAnalysisVideoPath =>
      getString(FeatureFlag.testFormAnalysisVideoPath);

  /// Debug-only: Uses mock form analysis response.
  /// Always returns false in release builds.
  bool get useMockFormAnalysisResponse =>
      getBool(FeatureFlag.useMockFormAnalysisResponse);

  String get formAnalysisCoachingTips =>
      getString(FeatureFlag.formAnalysisCoachingTips);

  bool get showFormAnalysisScoreAndSummary =>
      getBool(FeatureFlag.showFormAnalysisScoreAndSummary);

  bool get saveFormAnalysisToFirestore =>
      getBool(FeatureFlag.saveFormAnalysisToFirestore);

  bool get showFormAnalysisVideoComparison =>
      getBool(FeatureFlag.showFormAnalysisVideoComparison);

  bool get showCheckpointTimelinePlayer =>
      getBool(FeatureFlag.showCheckpointTimelinePlayer);

  bool get useSkeletonVideoInTimelinePlayer =>
      getBool(FeatureFlag.useSkeletonVideoInTimelinePlayer);

  /// Checkpoint timeline player UI style: 'darkSlateOverlay' or 'cleanSportMinimal'
  String get checkpointTimelinePlayerStyle =>
      getString(FeatureFlag.checkpointTimelinePlayerStyle);

  /// Maximum video duration in seconds for form analysis uploads
  int get maxFormAnalysisVideoSeconds =>
      getInt(FeatureFlag.maxFormAnalysisVideoSeconds);

  // ===== Admin/Force Upgrade =====

  List<String> get adminUids {
    final String value = getString(FeatureFlag.adminUids);
    if (value.isEmpty) return [];
    return value.split(',').map((e) => e.trim()).toList();
  }

  bool get alwaysShowForceUpgradeScreen =>
      getBool(FeatureFlag.alwaysShowForceUpgradeScreen);

  bool get alwaysShowFeatureWalkthrough =>
      getBool(FeatureFlag.alwaysShowFeatureWalkthrough);

  bool get alwaysShowOnboarding => getBool(FeatureFlag.alwaysShowOnboarding);

  // ===== Debug Info =====

  /// Get all current flag values for debugging.
  Map<String, dynamic> getAllValues() => _provider.getAllValues();

  /// Whether remote values have been fetched at least once.
  bool get hasFetchedRemoteValues => _provider.hasFetchedRemoteValues;

  /// The last time values were fetched from remote config.
  DateTime? get lastFetchTime => _provider.lastFetchTime;
}
