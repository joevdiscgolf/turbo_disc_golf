import 'package:turbo_disc_golf/services/story_generator_service.dart';

/// Enum defining all feature flags with their remote keys and default values.
///
/// To add a new flag:
/// 1. Add an enum value with (remoteKey, defaultValue)
/// 2. Optionally add a convenience getter in FeatureFlagService
/// 3. Add the parameter in Firebase Remote Config console
enum FeatureFlag {
  // ===== UI & Animation Toggles =====
  shouldAnimateProgressIndicators('should_animate_progress_indicators', true),
  useRoundReviewScreenV2('use_round_review_screen_v2', true),
  useHeroAnimationsForRoundReview(
    'use_hero_animations_for_round_review',
    false,
  ),
  useCustomPageTransitionsForRoundReview(
    'use_custom_page_transitions_for_round_review',
    true,
  ),
  showRoundMetadataInfoBar('show_round_metadata_info_bar', true),
  useAddThrowPanelV2('use_add_throw_panel_v2', true),
  useAddRoundStepsPanel('use_add_round_steps_panel', true),
  autoStartListeningOnNextHole('auto_start_listening_on_next_hole', false),
  showInlineMiniHoleGrid('show_inline_mini_hole_grid', true),
  showHoleProgressLabel('show_hole_progress_label', false),
  useBottomNavigationBar('use_bottom_navigation_bar', false),
  useRoundHistoryRowV2('use_round_history_row_v2', true),
  useBeautifulDatePicker('use_beautiful_date_picker', true),
  showHoleDistancesInScorecard('show_hole_distances_in_scorecard', true),
  showDistancePreferences('show_distance_preferences', false),
  showProjectedScoreInRecordRound('show_projected_score_in_record_round', true),
  showHoleDetailCardInRecordRound(
    'show_hole_detail_card_in_record_round',
    false,
  ),
  useThrowCardV2('use_throw_card_v2', true),
  useFixedBottomNavInRecordRound('use_fixed_bottom_nav_in_record_round', true),
  useFlatMicrophoneButton('use_flat_microphone_button', true),
  useVideoInputBodyV2('use_video_input_body_v2', true),
  useRedesignedMentalGameCard('use_redesigned_mental_game_card', true),
  usePodiumDiscCard('use_podium_disc_card', true),
  drivesDetailScreenV2('drives_detail_screen_v2', true),
  useThrowTypeComparisonCard('use_throw_type_comparison_card', true),

  /// Throw card layout style: 'inline' for full-width with inline number badge,
  /// 'split' for left-right split layout, empty for default (v2 with timeline)
  throwCardLayoutStyle('throw_card_layout_style', 'split'),

  /// Throw timeline visual style: 'default', 'journey_rail', 'flow_connectors', or 'connected_arrows'
  /// - 'default': Current behavior with cards only
  /// - 'journey_rail': Left-side visual timeline with location badges
  /// - 'flow_connectors': Curved connectors between cards showing transitions
  /// - 'connected_arrows': Left-side circles showing landing spots connected by arrows
  throwTimelineStyle('throw_timeline_style', 'default'),
  showMissingThrowDetailsInScoreDetail(
    'show_missing_throw_details_in_score_detail',
    true,
  ),

  // ===== Voice Service =====
  useIosVoiceService('use_ios_voice_service', true),

  // ===== Course Search =====
  /// Debug-only: Uses test courses instead of MeiliSearch
  useTestCourseProvider('use_test_course_provider', false),

  /// Uses Supabase for course search instead of MeiliSearch
  useSupabaseSearchProvider('use_supabase_search_provider', true),

  /// Debug-only: Uses local Meili server on simulator
  useLocalMeiliSearchOnSimulator('use_local_meili_search_on_simulator', true),
  meiliLocalServerUrl('meili_local_server_url', 'http://192.168.0.131:7700'),

  // ===== Judgment/Roast Feature =====
  /// Debug-only: Uses mock judgment instead of real AI
  useMockJudgment('use_mock_judgment', false),

  /// Force a specific judgment type: 'roast', 'glaze', or empty for random
  forceJudgmentType('force_judgment_type', ''),
  showQrCodeOnShareCard('show_qr_code_on_share_card', false),
  useVerdictImages('use_verdict_images', true),
  shareCardQrUrl('share_card_qr_url', 'https://scoresensei.app'),
  useBottomShareActionBar('use_bottom_share_action_bar', true),
  showJudgmentPreparingAnimation('show_judgment_preparing_animation', false),
  enableFireEmojiSpin('enable_fire_emoji_spin', false),

  // ===== LLM Configuration =====
  /// Default LLM provider: 'gemini' or 'chatGPT'
  defaultLLMProvider('default_llm_provider', 'gemini'),

  /// Story generation LLM provider: 'gemini' or 'chatGPT'
  storyGenerationLLMProvider('story_generation_llm_provider', 'chatGPT'),
  useGeminiFallbackModel('use_gemini_fallback_model', false),
  generateAiContentFromBackend('generate_ai_content_from_backend', true),
  expectParsedRoundFromBackend('expect_parsed_round_from_backend', true),

  // ===== Story Feature =====
  showStoryLoadingAnimation('show_story_loading_animation', false),
  showElitePotentialCard('show_elite_potential_card', true),
  useStoryPosterShareCard('use_story_poster_share_card', true),
  showWhatCouldHaveBeenCard('show_what_could_have_been_card', true),
  showWhatCouldHaveBeenEncouragement(
    'show_what_could_have_been_encouragement',
    false,
  ),
  storyV2Enabled('story_v2_enabled', true),
  storyV3Enabled('story_v3_enabled', true),
  highlightActiveStorySection('highlight_active_story_section', true),
  showStoryShareButton('show_story_share_button', true),

  // ===== Scorecard Import =====
  /// Debug-only: Uses test scorecard for import testing
  useTestScorecardForImport('use_test_scorecard_for_import', false),
  testScorecardPath(
    'test_scorecard_path',
    'assets/test_scorecards/flingsgiving_round_2.jpeg',
  ),

  /// Debug-only: Uses mock scorecard data instead of AI parsing
  useMockScorecardData('use_mock_scorecard_data', false),

  // ===== Map/Location =====
  showMapLocationPicker('show_map_location_picker', true),

  /// Map provider: 'flutter_map' or 'google_maps'
  mapProvider('map_provider', 'flutter_map'),

  // ===== Form Analysis =====
  useFormAnalysisTab('use_form_analysis_tab', true),
  usePoseAnalysisBackend('use_pose_analysis_backend', true),
  poseAnalysisBaseUrl('pose_analysis_base_url', 'http://192.168.0.131:8080'),

  /// Debug-only: Shows test button in form analysis
  showFormAnalysisTestButton('show_form_analysis_test_button', true),
  testFormAnalysisVideoPath(
    'test_form_analysis_video_path',
    'assets/test_videos/joe_example_throw_2.mov',
  ),

  /// Debug-only: Uses mock form analysis response
  useMockFormAnalysisResponse('use_mock_form_analysis_response', true),
  showFormAnalysisScoreAndSummary('show_form_analysis_score_and_summary', true),
  saveFormAnalysisToFirestore('save_form_analysis_to_firestore', true),
  showFormAnalysisVideoComparison('show_form_analysis_video_comparison', false),
  showCheckpointTimelinePlayer('show_checkpoint_timeline_player', true),
  useSkeletonVideoInTimelinePlayer(
    'use_skeleton_video_in_timeline_player',
    true,
  ),

  /// Checkpoint timeline player UI style: 'darkSlateOverlay' or 'cleanSportMinimal'
  checkpointTimelinePlayerStyle(
    'checkpoint_timeline_player_style',
    'cleanSportMinimal',
  ),

  // ===== Admin/Force Upgrade =====
  /// Comma-separated list of admin UIDs
  adminUids('admin_uids', '9abVDwf3ZVM8unEzqMcWk95in2F3'),
  alwaysShowForceUpgradeScreen('always_show_force_upgrade_screen', false),
  alwaysShowFeatureWalkthrough('always_show_feature_walkthrough', false),
  alwaysShowOnboarding('always_show_onboarding', false);

  const FeatureFlag(this.remoteKey, this.defaultValue);

  /// The key used in Firebase Remote Config
  final String remoteKey;

  /// The default value used when remote config is unavailable
  final dynamic defaultValue;

  /// Whether this is a debug-only flag that should return false in release builds
  bool get isDebugOnly {
    switch (this) {
      case FeatureFlag.useTestCourseProvider:
      case FeatureFlag.useLocalMeiliSearchOnSimulator:
      case FeatureFlag.useMockJudgment:
      case FeatureFlag.useTestScorecardForImport:
      case FeatureFlag.useMockScorecardData:
      case FeatureFlag.showFormAnalysisTestButton:
      case FeatureFlag.useMockFormAnalysisResponse:
        return true;
      default:
        return false;
    }
  }
}

/// Extension to convert string values to LLMProvider enum
extension FeatureFlagLLMProvider on String {
  LLMProvider toLLMProvider() {
    switch (toLowerCase()) {
      case 'chatgpt':
        return LLMProvider.chatGPT;
      case 'gemini':
      default:
        return LLMProvider.gemini;
    }
  }
}
