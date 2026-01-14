import 'package:flutter/foundation.dart';

const bool shouldAnimateProgressIndicators = true;
const bool useRoundReviewScreenV2 = true;
const bool useHeroAnimationsForRoundReview = false;
const bool useCustomPageTransitionsForRoundReview = true;
const bool useAddThrowPanelV2 = true;
const bool useAddRoundStepsPanel = true;
const bool autoStartListeningOnNextHole = false;
const bool showInlineMiniHoleGrid = true;
const bool showHoleProgressLabel = false;
const bool useIosVoiceService = true;
const bool kUseMeiliCourseSearch = kDebugMode;
const bool useMockJudgment = false;

/// Force judgment type for testing. Set to 'roast', 'glaze', or null for random.
const String? forceJudgmentType = null; // 'roast', 'glaze', or null

/// When true, shows a QR code on the judgment share card linking to the app.
const bool showQrCodeOnShareCard = false;

/// When true, uses PNG images for "You got glazed/roasted" instead of text.
/// Images are in assets/judge_tab/glazed_clear_crop.png and roasted_clear_crop.png
const bool useVerdictImages = true;

/// The URL encoded in the share card QR code (placeholder for now).
const String shareCardQrUrl = 'https://scoresensei.app';

/// When true, uses gemini-2.0-flash-exp instead of gemini-2.5-flash for story generation.
/// Use this when hitting 2.5-flash quota limits.
const bool useGeminiFallbackModel = false;

/// When true, always shows the story loading animation for testing/refinement.
const bool showStoryLoadingAnimation = false;

/// When true, uses the new bottom action bar layout for judgment share.
/// When false, uses the original inline share button layout.
const bool useBottomShareActionBar = true;

/// When true, shows the judgment preparing animation while waiting for API.
/// When false, skips directly to the spinning state.
const bool showJudgmentPreparingAnimation = false;

/// When true, fire emojis spin as they fall during roast celebration.
/// When false, they fall straight down without rotation (for performance testing).
const bool enableFireEmojiSpin = false;

/// When true, shows the "How Close to Elite?" card in the structured story renderer.
/// This card shows potential score if blow-ups were just bogeys.
const bool showElitePotentialCard = true;

/// When true (and in debug mode), automatically uses the test scorecard image
/// instead of prompting for image selection. Also prints parsed data for debugging.
const bool useTestScorecardForImport = true;

/// Path to the test scorecard image used when useTestScorecardForImport is true.
const String testScorecardPath =
    'assets/test_scorecards/flingsgiving_round_2.jpeg';

/// When true (and in debug mode), uses hardcoded test scorecard data instead
/// of calling the AI parsing service. This avoids API calls during testing.
const bool useMockScorecardData = true;

/// Hardcoded test scorecard data for Flingsgiving Round 2.
/// Used when useMockScorecardData is true to skip AI parsing.
const List<Map<String, int>> testScorecardData = [
  {'holeNumber': 1, 'score': 3, 'par': 4, 'distanceFeet': 572},
  {'holeNumber': 2, 'score': 2, 'par': 3, 'distanceFeet': 192},
  {'holeNumber': 3, 'score': 4, 'par': 3, 'distanceFeet': 375},
  {'holeNumber': 4, 'score': 3, 'par': 3, 'distanceFeet': 390},
  {'holeNumber': 5, 'score': 3, 'par': 4, 'distanceFeet': 461},
  {'holeNumber': 6, 'score': 2, 'par': 3, 'distanceFeet': 335},
  {'holeNumber': 7, 'score': 7, 'par': 4, 'distanceFeet': 512},
  {'holeNumber': 8, 'score': 2, 'par': 3, 'distanceFeet': 225},
  {'holeNumber': 9, 'score': 2, 'par': 3, 'distanceFeet': 335},
  {'holeNumber': 10, 'score': 3, 'par': 4, 'distanceFeet': 610},
  {'holeNumber': 11, 'score': 2, 'par': 3, 'distanceFeet': 325},
  {'holeNumber': 12, 'score': 2, 'par': 3, 'distanceFeet': 220},
  {'holeNumber': 13, 'score': 4, 'par': 5, 'distanceFeet': 796},
  {'holeNumber': 14, 'score': 3, 'par': 3, 'distanceFeet': 346},
  {'holeNumber': 15, 'score': 3, 'par': 3, 'distanceFeet': 271},
  {'holeNumber': 16, 'score': 2, 'par': 3, 'distanceFeet': 198},
  {'holeNumber': 17, 'score': 5, 'par': 4, 'distanceFeet': 706},
  {'holeNumber': 18, 'score': 3, 'par': 3, 'distanceFeet': 373},
];

/// When true, shows the bottom navigation bar with all tabs.
/// When false, the app opens directly to the Round History screen.
const bool useBottomNavigationBar = false;

const List<String> adminUids = ['9abVDwf3ZVM8unEzqMcWk95in2F3'];

/// When true, uses RoundHistoryRowV2 with score distribution bar and date.
/// When false, uses the original RoundHistoryRow layout.
const bool useRoundHistoryRowV2 = true;

/// When true, uses the Story Poster with Score Journey graph for sharing.
/// When false, uses the compact Story Highlights Card.
const bool useStoryPosterShareCard = true;

/// When true, shows the "What Could Have Been" card in the story.
/// When false, hides the entire card.
const bool showWhatCouldHaveBeenCard = true;

/// When true, shows the encouragement message in the "What Could Have Been" card.
/// When false, hides it to save vertical space.
const bool showWhatCouldHaveBeenEncouragement = false;

/// When true, shows the map location picker in the Create Course screen.
/// When false, only text fields for city/state/country are shown.
const bool showMapLocationPicker = true;

/// Map provider to use for the location picker.
/// Options: 'flutter_map' (free, OpenStreetMap) or 'google_maps' (requires API key).
const String mapProvider = 'flutter_map';

/// When true, uses a beautiful calendar date/time picker in a bottom sheet.
/// When false, uses the standard Material showDatePicker/showTimePicker dialogs.
const bool useBeautifulDatePicker = true;

/// When true, shows Form Analysis tab alongside Round History in MainWrapper.
/// When false, Form Analysis is not accessible (feature hidden).
const bool useFormAnalysisTab = true;

/// When true, uses the Cloud Run pose analysis backend instead of Gemini-only.
/// When false, uses only Gemini for form analysis (no pose comparison).
const bool usePoseAnalysisBackend = true;

/// Base URL for the pose analysis Cloud Run service.
/// For iOS simulator testing: Use your Mac's IP (localhost doesn't work)
/// For production: Set to your Cloud Run URL
const String poseAnalysisBaseUrl = 'http://192.168.0.131:8080';

/// When true (and in debug mode), shows a "Test with Example" button in Form Analysis
/// that uses a bundled test video instead of requiring gallery selection.
const bool showFormAnalysisTestButton = kDebugMode;

/// Path to the test video for form analysis testing.
/// This video is bundled in assets and copied to temp storage for testing.
const String testFormAnalysisVideoPath =
    'assets/test_videos/joe_example_throw_2.mov';

/// When true (and in debug mode), skips the Gemini API call for form analysis
/// and returns a mock response. Use this when testing checkpoint UI without
/// needing actual AI analysis.
const bool useMockFormAnalysisResponse = true;

/// When true, shows the overall score header and summary section in form analysis results.
/// When false, only the pose comparison section is displayed (for focused testing).
const bool showFormAnalysisScoreAndSummary = false;

/// When true, saves form analyses to Firestore and uploads images to Cloud Storage.
/// When false, skips saving to prevent cluttering the database during testing.
/// Analysis results will still be shown in the UI, just not persisted.
const bool saveFormAnalysisToFirestore = true;

/// When true, always shows the Force Upgrade screen regardless of version check.
/// This is useful for testing the upgrade UI without modifying Firestore.
/// Set to false in production.
const bool alwaysShowForceUpgradeScreen = false;
