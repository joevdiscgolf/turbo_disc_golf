import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/gemini_service.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';

class RoundParser extends ChangeNotifier {
  final GeminiService _geminiService;
  final BagService _bagService;

  DGRound? _parsedRound;
  bool _isProcessing = false;
  String _lastError = '';

  RoundParser({
    required GeminiService geminiService,
    required BagService bagService,
  }) : _geminiService = geminiService,
       _bagService = bagService;

  DGRound? get parsedRound => _parsedRound;
  bool get isProcessing => _isProcessing;
  String get lastError => _lastError;

  Future<bool> parseVoiceTranscript(
    String transcript, {
    String? courseName,
  }) async {
    if (transcript.trim().isEmpty) {
      _lastError = 'Transcript is empty';
      notifyListeners();
      return false;
    }

    print('=== SUBMITTING TRANSCRIPT FOR PARSING ===');
    print('Transcript length: ${transcript.length} characters');
    print('Course name: ${courseName ?? "Not specified"}');
    print('Raw transcript:');
    print(transcript);
    print('==========================================');

    _isProcessing = true;
    _lastError = '';
    notifyListeners();

    try {
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

    return DGRound(id: round.id, course: round.course, holes: enhancedHoles);
  }

  void updateHole(int holeIndex, DGHole updatedHole) {
    if (_parsedRound != null && holeIndex < _parsedRound!.holes.length) {
      final updatedHoles = List<DGHole>.from(_parsedRound!.holes);
      updatedHoles[holeIndex] = updatedHole;

      _parsedRound = DGRound(
        id: _parsedRound!.id,
        course: _parsedRound!.course,
        holes: updatedHoles,
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
