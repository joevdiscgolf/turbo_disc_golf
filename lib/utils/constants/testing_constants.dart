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

/// When true, uses gemini-1.5-flash-latest instead of gemini-2.5-flash for story generation.
/// Use this when hitting 2.5-flash quota limits.
const bool useGeminiFallbackModel = false;

const List<String> adminUids = ['9abVDwf3ZVM8unEzqMcWk95in2F3'];
