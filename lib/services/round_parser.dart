import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_round_service.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';
import 'package:turbo_disc_golf/utils/date_formatter.dart';

class RoundParser extends ChangeNotifier {
  DGRound? _parsedRound;
  bool _isProcessing = false;
  bool _isReadyToNavigate = false;
  String _lastError = '';
  bool _shouldNavigateToReview = false;

  DGRound? get parsedRound => _parsedRound;
  bool get isProcessing => _isProcessing;
  bool get isReadyToNavigate => _isReadyToNavigate;
  String get lastError => _lastError;
  bool get shouldNavigateToReview => _shouldNavigateToReview;

  /// Set an existing round (e.g., when loading from history)
  /// This does NOT trigger navigation to review screen
  void setRound(DGRound round) {
    _parsedRound = round;
    _shouldNavigateToReview = false;
    notifyListeners();
  }

  /// Resets the navigation flag after navigation has occurred
  void clearNavigationFlag() {
    _shouldNavigateToReview = false;
    _isReadyToNavigate = false;
  }

  /// Signals that processing is complete and ready to navigate
  /// This gives the UI time to show the loading animation before transitioning
  void _setReadyToNavigate() {
    _isReadyToNavigate = true;
    notifyListeners();

    // Add a small delay before allowing navigation to let the loading animation play
    Future.delayed(const Duration(milliseconds: 800), () {
      _shouldNavigateToReview = true;
      notifyListeners();
    });
  }

  Future<bool> parseVoiceTranscript(
    String transcript, {
    String? courseName,
    bool useSharedPreferences = false,
    List<HoleMetadata>?
    preParsedHoles, // NEW: Pre-parsed hole metadata from image
  }) async {
    final BagService bagService = locator.get<BagService>();

    try {
      // If using shared preferences, try to load cached round first
      if (useSharedPreferences) {
        _isProcessing = true;
        _lastError = '';
        notifyListeners();

        debugPrint('Attempting to load round from shared preferences...');
        final cachedRound = await locator
            .get<RoundStorageService>()
            .loadRound();

        if (cachedRound != null) {
          debugPrint(
            'Successfully loaded cached round from shared preferences',
          );

          // Add a 3-second delay to show the loading animation
          await Future.delayed(const Duration(seconds: 3));

          _parsedRound = cachedRound;
          _isProcessing = false;
          _setReadyToNavigate(); // Signal that we're ready to navigate with a delay
          return true;
        } else {
          debugPrint('No cached round found in shared preferences');
          _lastError = 'No cached round found. Parse a round first.';
          _isProcessing = false;
          notifyListeners();
          return false;
        }
      }

      // Only print these logs when we're actually parsing with Gemini
      debugPrint('=== SUBMITTING TRANSCRIPT FOR PARSING ===');
      debugPrint('Transcript length: ${transcript.length} characters');
      debugPrint('Course name: ${courseName ?? "Not specified"}');
      // debugPrint('Raw transcript:');
      // debugPrint(transcript);
      // debugPrint('==========================================');

      _isProcessing = true;
      _lastError = '';
      notifyListeners();

      // Check if transcript is empty (only needed if we're actually parsing)
      if (transcript.trim().isEmpty) {
        _lastError = 'Transcript is empty';
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      // Load user's bag if not already loaded
      if (bagService.userBag.isEmpty) {
        await bagService.loadBag();

        // If still empty, load sample bag for testing
        if (bagService.userBag.isEmpty) {
          bagService.loadSampleBag();
        }
      }

      // Parse with Gemini
      _parsedRound = await locator
          .get<AiParsingService>()
          .parseRoundDescription(
            voiceTranscript: transcript,
            userBag: bagService.userBag,
            courseName: courseName,
            preParsedHoles: preParsedHoles, // Pass through pre-parsed holes
          );

      if (_parsedRound == null) {
        _lastError = 'Failed to parse round. Check console for details.';
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      // Validate and enhance the parsed data
      _parsedRound = _validateAndEnhanceRound(_parsedRound!);

      // Generate analysis from round data
      debugPrint('Generating round analysis...');
      final analysis = RoundAnalysisGenerator.generateAnalysis(_parsedRound!);

      // Generate AI insights (summary and coaching)
      debugPrint('Generating AI summary and coaching...');
      final insights = await locator
          .get<AiParsingService>()
          .generateRoundInsights(round: _parsedRound!, analysis: analysis);

      // Update round with analysis and insights
      final String currentTimestamp = getCurrentISOString();
      _parsedRound = DGRound(
        id: _parsedRound!.id,
        courseName: _parsedRound!.courseName,
        courseId: _parsedRound!.courseId,
        holes: _parsedRound!.holes,
        analysis: analysis,
        aiSummary: insights['summary'],
        aiCoachSuggestion: insights['coaching'],
        versionId: 1, // Set initial version ID
        createdAt: currentTimestamp,
        playedRoundAt: currentTimestamp,
      );

      // Save to shared preferences for future use
      debugPrint('Saving parsed round to shared preferences...');
      final savedLocally = await locator.get<RoundStorageService>().saveRound(
        _parsedRound!,
      );
      if (savedLocally) {
        debugPrint('Successfully saved round to shared preferences');
      } else {
        debugPrint('Failed to save round to shared preferences');
      }

      // Save to Firestore
      debugPrint('Saving parsed round to Firestore...');
      final firestoreSuccess = await locator
          .get<FirestoreRoundService>()
          .addRound(_parsedRound!);
      if (firestoreSuccess) {
        debugPrint('Successfully saved round to Firestore');
      } else {
        debugPrint('Failed to save round to Firestore');
      }

      _isProcessing = false;
      _setReadyToNavigate(); // Signal that we're ready to navigate with a delay
      return true;
    } catch (e) {
      _lastError = 'Error parsing round: $e';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  DGRound _validateAndEnhanceRound(DGRound round) {
    final bagService = locator.get<BagService>();

    // Ensure all throws have valid disc references
    final enhancedHoles = round.holes.map((hole) {
      final enhancedThrows = hole.throws.map((discThrow) {
        DiscThrow workingThrow = discThrow;

        // If disc name is provided, try to match it to the user's bag
        if (workingThrow.discName != null && workingThrow.disc == null) {
          final matchedDisc = bagService.findDiscByName(workingThrow.discName!);
          if (matchedDisc != null) {
            workingThrow = DiscThrow(
              index: workingThrow.index,
              purpose: workingThrow.purpose,
              technique: workingThrow.technique,
              puttStyle: workingThrow.puttStyle,
              shotShape: workingThrow.shotShape,
              stance: workingThrow.stance,
              power: workingThrow.power,
              distanceFeetBeforeThrow: workingThrow.distanceFeetBeforeThrow,
              distanceFeetAfterThrow: workingThrow.distanceFeetAfterThrow,
              elevationChangeFeet: workingThrow.elevationChangeFeet,
              windDirection: workingThrow.windDirection,
              windStrength: workingThrow.windStrength,
              resultRating: workingThrow.resultRating,
              landingSpot: workingThrow.landingSpot,
              fairwayWidth: workingThrow.fairwayWidth,
              penaltyStrokes: workingThrow.penaltyStrokes,
              notes: workingThrow.notes,
              rawText: workingThrow.rawText,
              parseConfidence: workingThrow.parseConfidence,
              discName: workingThrow.discName,
              disc: matchedDisc,
            );
          }
        }

        // Validate and correct landingSpot based on distanceFeetAfterThrow
        // CRITICAL: NEVER override out_of_bounds or off_fairway - these are always correct
        if (workingThrow.distanceFeetAfterThrow != null) {
          final distance = workingThrow.distanceFeetAfterThrow!;
          final currentSpot = workingThrow.landingSpot;

          // NEVER override OB or off_fairway regardless of distance
          if (currentSpot == LandingSpot.outOfBounds ||
              currentSpot == LandingSpot.offFairway) {
            // These are intentional and correct - do not modify
            debugPrint(
              '✓ Preserving ${currentSpot?.name} for throw ${workingThrow.index} in hole ${hole.number} '
              '(distance: $distance ft) - not overriding intentional landing spot',
            );
          } else {
            // Only correct other landing spots based on distance
            LandingSpot? correctLandingSpot;

            if (distance == 0) {
              correctLandingSpot = LandingSpot.inBasket;
            } else if (distance <= 10) {
              correctLandingSpot = LandingSpot.parked;
            } else if (distance <= 33) {
              correctLandingSpot = LandingSpot.circle1;
            } else if (distance <= 66) {
              correctLandingSpot = LandingSpot.circle2;
            } else {
              // For distances > 66 feet, keep the AI's decision between fairway/other
              // Only correct if it was incorrectly set to a circle
              if (currentSpot == LandingSpot.parked ||
                  currentSpot == LandingSpot.circle1 ||
                  currentSpot == LandingSpot.circle2) {
                correctLandingSpot = LandingSpot.fairway;
              }
            }

            // If we determined a correction is needed, apply it
            if (correctLandingSpot != null &&
                correctLandingSpot != currentSpot) {
              debugPrint(
                '⚠️ Correcting landingSpot for throw ${workingThrow.index} in hole ${hole.number}: '
                '${currentSpot?.name} → ${correctLandingSpot.name} '
                '(distance: $distance ft)',
              );

              workingThrow = DiscThrow(
                index: workingThrow.index,
                purpose: workingThrow.purpose,
                technique: workingThrow.technique,
                puttStyle: workingThrow.puttStyle,
                shotShape: workingThrow.shotShape,
                stance: workingThrow.stance,
                power: workingThrow.power,
                distanceFeetBeforeThrow: workingThrow.distanceFeetBeforeThrow,
                distanceFeetAfterThrow: workingThrow.distanceFeetAfterThrow,
                elevationChangeFeet: workingThrow.elevationChangeFeet,
                windDirection: workingThrow.windDirection,
                windStrength: workingThrow.windStrength,
                resultRating: workingThrow.resultRating,
                landingSpot: correctLandingSpot,
                fairwayWidth: workingThrow.fairwayWidth,
                penaltyStrokes: workingThrow.penaltyStrokes,
                notes: workingThrow.notes,
                rawText: workingThrow.rawText,
                parseConfidence: workingThrow.parseConfidence,
                discName: workingThrow.discName,
                disc: workingThrow.disc,
              );
            }
          }
        }

        return workingThrow;
      }).toList();

      return DGHole(
        number: hole.number,
        par: hole.par,
        feet: hole.feet,
        throws: enhancedThrows,
      );
    }).toList();

    return DGRound(
      courseName: round.courseName,
      holes: enhancedHoles,
      id: round.id,
      versionId: round.versionId,
    );
  }

  void updateHole(int holeIndex, DGHole updatedHole) {
    if (_parsedRound != null && holeIndex < _parsedRound!.holes.length) {
      final updatedHoles = List<DGHole>.from(_parsedRound!.holes);
      updatedHoles[holeIndex] = updatedHole;

      _parsedRound = DGRound(
        courseName: _parsedRound!.courseName,
        holes: updatedHoles,
        id: _parsedRound!.id,
        analysis: _parsedRound!.analysis,
        aiSummary: _parsedRound!.aiSummary,
        aiCoachSuggestion: _parsedRound!.aiCoachSuggestion,
        versionId: _parsedRound!.versionId + 1, // Increment version on edit
        createdAt: _parsedRound!.createdAt,
        playedRoundAt: _parsedRound!.playedRoundAt,
      );

      notifyListeners();
    }
  }

  void updateThrow(int holeIndex, int throwIndex, DiscThrow updatedThrow) {
    if (_parsedRound != null &&
        holeIndex < _parsedRound!.holes.length &&
        throwIndex < _parsedRound!.holes[holeIndex].throws.length) {
      final hole = _parsedRound!.holes[holeIndex];
      final updatedThrows = List<DiscThrow>.from(hole.throws);
      updatedThrows[throwIndex] = updatedThrow;

      final updatedHole = DGHole(
        number: hole.number,
        par: hole.par,
        feet: hole.feet,
        throws: updatedThrows,
      );

      updateHole(holeIndex, updatedHole);
    }
  }

  /// Adds an empty hole to the round at the correct position based on hole number
  void addEmptyHole(int holeNumber, {int? par, int? feet}) {
    if (_parsedRound == null) return;

    // Create empty hole
    final DGHole emptyHole = DGHole(
      number: holeNumber,
      par: par ?? 3, // Default to par 3
      feet: feet,
      throws: [], // Empty throws list
    );

    // Find correct insertion position (maintain hole number order)
    final List<DGHole> updatedHoles = List<DGHole>.from(_parsedRound!.holes);

    // Find index where this hole should be inserted
    int insertIndex = updatedHoles.length;
    for (int i = 0; i < updatedHoles.length; i++) {
      if (updatedHoles[i].number > holeNumber) {
        insertIndex = i;
        break;
      }
    }

    updatedHoles.insert(insertIndex, emptyHole);

    _parsedRound = DGRound(
      courseName: _parsedRound!.courseName,
      holes: updatedHoles,
      id: _parsedRound!.id,
      analysis: _parsedRound!.analysis,
      aiSummary: _parsedRound!.aiSummary,
      aiCoachSuggestion: _parsedRound!.aiCoachSuggestion,
      versionId: _parsedRound!.versionId + 1, // Increment version on edit
      createdAt: _parsedRound!.createdAt,
      playedRoundAt: _parsedRound!.playedRoundAt,
    );

    notifyListeners();
  }

  /// Adds multiple empty holes at once
  void addMissingHoles(Set<int> holeNumbers, {int? defaultPar}) {
    for (final holeNumber in holeNumbers) {
      addEmptyHole(holeNumber, par: defaultPar);
    }
  }

  /// Re-process a single hole with new voice description
  Future<bool> reProcessHole({
    required int holeIndex,
    required String voiceTranscript,
  }) async {
    if (_parsedRound == null || holeIndex >= _parsedRound!.holes.length) {
      _lastError = 'Invalid hole index or no round loaded';
      return false;
    }

    final BagService bagService = locator.get<BagService>();

    try {
      _isProcessing = true;
      _lastError = '';
      notifyListeners();

      // Load user's bag if not already loaded
      if (bagService.userBag.isEmpty) {
        await bagService.loadBag();
        if (bagService.userBag.isEmpty) {
          bagService.loadSampleBag();
        }
      }

      final hole = _parsedRound!.holes[holeIndex];

      debugPrint('=== RE-PROCESSING HOLE ${hole.number} ===');
      debugPrint('Voice transcript: $voiceTranscript');

      // Parse the single hole with Gemini
      final newHole = await locator
          .get<AiParsingService>()
          .parseSingleHole(
            voiceTranscript: voiceTranscript,
            userBag: bagService.userBag,
            holeNumber: hole.number,
            holePar: hole.par,
            holeFeet: hole.feet,
            courseName: _parsedRound!.courseName,
          );

      if (newHole == null) {
        _lastError = 'Failed to re-parse hole. Check console for details.';
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      debugPrint('Successfully re-parsed hole ${hole.number}');

      // Update the hole in the round
      updateHole(holeIndex, newHole);

      // Re-validate and enhance the entire round
      _parsedRound = _validateAndEnhanceRound(_parsedRound!);

      // Save updated round to shared preferences
      debugPrint('Saving updated round to shared preferences...');
      await locator.get<RoundStorageService>().saveRound(_parsedRound!);

      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Error re-processing hole: $e';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  void clearParsedRound() {
    _parsedRound = null;
    _lastError = '';
    notifyListeners();
  }

  String getScoreName(int score) {
    switch (score) {
      case -3:
        return 'Albatross';
      case -2:
        return 'Eagle';
      case -1:
        return 'Birdie';
      case 0:
        return 'Par';
      case 1:
        return 'Bogey';
      case 2:
        return 'Double Bogey';
      case 3:
        return 'Triple Bogey';
      default:
        if (score < -3) return 'Ace';
        return '+$score';
    }
  }

  int getTotalScore() {
    if (_parsedRound == null) return 0;

    return _parsedRound!.holes.fold(0, (total, hole) {
      return total + hole.holeScore;
    });
  }

  int getTotalPar() {
    if (_parsedRound == null) return 0;

    return _parsedRound!.holes.fold(0, (total, hole) {
      return total + hole.par;
    });
  }

  int getRelativeToPar() {
    return getTotalScore() - getTotalPar();
  }
}
