import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_round_service.dart';
import 'package:turbo_disc_golf/services/gemini_service.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';

class RoundParser extends ChangeNotifier {
  final GeminiService _geminiService;
  final BagService _bagService;
  final RoundStorageService _storageService;

  DGRound? _parsedRound;
  bool _isProcessing = false;
  String _lastError = '';

  RoundParser({
    required GeminiService geminiService,
    required BagService bagService,
    RoundStorageService? storageService,
  }) : _geminiService = geminiService,
       _bagService = bagService,
       _storageService = storageService ?? RoundStorageService();

  DGRound? get parsedRound => _parsedRound;
  bool get isProcessing => _isProcessing;
  String get lastError => _lastError;

  /// Set an existing round (e.g., when loading from history)
  void setRound(DGRound round) {
    _parsedRound = round;
    notifyListeners();
  }

  Future<bool> parseVoiceTranscript(
    String transcript, {
    String? courseName,
    bool useSharedPreferences = false,
  }) async {
    if (transcript.trim().isEmpty) {
      _lastError = 'Transcript is empty';
      notifyListeners();
      return false;
    }

    debugPrint('=== SUBMITTING TRANSCRIPT FOR PARSING ===');
    debugPrint('Use shared preferences: $useSharedPreferences');
    debugPrint('Transcript length: ${transcript.length} characters');
    debugPrint('Course name: ${courseName ?? "Not specified"}');
    debugPrint('Raw transcript:');
    debugPrint(transcript);
    debugPrint('==========================================');

    _isProcessing = true;
    _lastError = '';
    notifyListeners();

    try {
      // If using shared preferences, try to load cached round first
      if (useSharedPreferences) {
        debugPrint('Attempting to load round from shared preferences...');
        final cachedRound = await _storageService.loadRound();

        if (cachedRound != null) {
          debugPrint(
            'Successfully loaded cached round from shared preferences',
          );
          _parsedRound = cachedRound;
          _isProcessing = false;
          notifyListeners();
          return true;
        } else {
          debugPrint('No cached round found in shared preferences');
          _lastError = 'No cached round found. Parse a round first.';
          _isProcessing = false;
          notifyListeners();
          return false;
        }
      }

      // Load user's bag if not already loaded
      if (_bagService.userBag.isEmpty) {
        await _bagService.loadBag();

        // If still empty, load sample bag for testing
        if (_bagService.userBag.isEmpty) {
          _bagService.loadSampleBag();
        }
      }

      // Parse with Gemini
      _parsedRound = await _geminiService.parseRoundDescription(
        voiceTranscript: transcript,
        userBag: _bagService.userBag,
        courseName: courseName,
      );

      if (_parsedRound == null) {
        _lastError = 'Failed to parse round. Check console for details.';
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      // Validate and enhance the parsed data
      _parsedRound = _validateAndEnhanceRound(_parsedRound!);

      // Save to shared preferences for future use
      debugPrint('Saving parsed round to shared preferences...');
      final savedLocally = await _storageService.saveRound(_parsedRound!);
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
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Error parsing round: $e';
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  DGRound _validateAndEnhanceRound(DGRound round) {
    // Ensure all throws have valid disc references
    final enhancedHoles = round.holes.map((hole) {
      final enhancedThrows = hole.throws.map((discThrow) {
        // If disc name is provided but not found in bag, try to match
        // if (discThrow.discName != null && discThrow.discId == null) {
        //   final matchedDisc = _bagService.findDiscByName(discThrow.discName!);
        //   if (matchedDisc != null) {
        //     return DiscThrow(
        //       distanceFeet: discThrow.distanceFeet,
        //       index: discThrow.index,
        //       purpose: discThrow.purpose,
        //       technique: discThrow.technique,
        //       puttStyle: discThrow.puttStyle,
        //       shotShape: discThrow.shotShape,
        //       stance: discThrow.stance,
        //       power: discThrow.power,
        //       elevationChangeFeet: discThrow.elevationChangeFeet,
        //       windDirection: discThrow.windDirection,
        //       windStrength: discThrow.windStrength,
        //       resultRating: discThrow.resultRating,
        //       landingSpot: discThrow.landingSpot,
        //       fairwayWidth: discThrow.fairwayWidth,
        //       notes: discThrow.notes,
        //       rawText: discThrow.rawText,
        //       parseConfidence: discThrow.parseConfidence,
        //     );
        //   }
        // }
        return discThrow;
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
