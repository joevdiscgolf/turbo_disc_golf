import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';

class RoundParser extends ChangeNotifier implements ClearOnLogoutProtocol {
  PotentialDGRound? _potentialRound;
  DGRound? _parsedRound;
  bool _isProcessing = false;
  bool _isReadyToNavigate = false;
  String _lastError = '';
  bool _shouldNavigateToReview = false;

  PotentialDGRound? get potentialRound => _potentialRound;
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
    Course? selectedCourse,
    required String? selectedLayoutId,
    int numHoles = 18,
    bool useSharedPreferences = false,
    List<HoleMetadata>?
    preParsedHoles, // NEW: Pre-parsed hole metadata from image
  }) async {
    final BagService bagService = locator.get<BagService>();

    // Extract course info from Course object
    final String courseName = selectedCourse?.name ?? 'Unknown Course';
    final String courseId = selectedCourse?.id ?? 'unknown';
    // Use selected layout ID, or fall back to default layout ID, or 'default' as last resort
    final String layoutId =
        selectedLayoutId ?? (selectedCourse?.defaultLayout.id) ?? 'default';

    debugPrint(
      'parsing voice transcript in round parser, selectedLayoutId: $selectedLayoutId, layoutId variable :$layoutId',
    );

    debugPrint(
      '🎯 parseVoiceTranscript: selectedLayoutId=$selectedLayoutId, resolved layoutId=$layoutId',
    );
    debugPrint(
      '🎯 selectedCourse.defaultLayout: ${selectedCourse?.defaultLayout.name} (${selectedCourse?.defaultLayout.id})',
    );

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

          // For cached rounds, we already have a complete DGRound
          // So we skip the potential round stage
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
      debugPrint('Course name: $courseName');
      debugPrint('Raw transcript:');
      debugPrint(transcript);
      debugPrint('==========================================');

      _isProcessing = true;
      _lastError = '';
      notifyListeners();

      // Check if transcript is empty (only needed if we're actually parsing)
      if (transcript.trim().isEmpty) {
        _lastError =
            'Transcript is empty. Please record descriptions for your holes.';
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      // Check if transcript only contains hole labels without actual descriptions
      final String cleanTranscript = transcript
          .replaceAll(RegExp(r'Hole \d+:'), '')
          .trim();
      if (cleanTranscript.isEmpty) {
        _lastError =
            'No hole descriptions provided. Please add details for at least one hole.';
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

      // Parse with Gemini - returns PotentialDGRound with optional fields
      debugPrint('Calling Gemini API to parse round...');
      _potentialRound = await locator
          .get<AiParsingService>()
          .parseRoundDescription(
            voiceTranscript: transcript,
            userBag: bagService.userBag,
            course: selectedCourse,
            layoutId: layoutId,
            numHoles: numHoles,
            preParsedHoles: preParsedHoles, // Pass through pre-parsed holes
          );

      debugPrint('Gemini parsing completed');
      debugPrint(
        'Potential round is ${_potentialRound == null ? 'NULL' : 'valid'}',
      );
      if (_potentialRound != null) {
        debugPrint(
          'Potential round has ${_potentialRound!.holes?.length ?? 0} holes',
        );

        // Enhance holes with course layout data (fill missing par/distance/holeType)
        List<PotentialDGHole>? enhancedHoles;
        if (selectedCourse != null && _potentialRound!.holes != null) {
          enhancedHoles = _enhanceHolesWithCourseLayout(
            _potentialRound!.holes!,
            selectedCourse,
            layoutId,
          );
        }

        // Add course data to potential round (AI service doesn't know about it)
        final String? uid = locator.get<AuthService>().currentUid;
        if (uid != null) {
          _potentialRound = PotentialDGRound(
            uid: uid,
            id: _potentialRound!.id,
            courseName: courseName,
            courseId: courseId,
            course: selectedCourse,
            layoutId: layoutId,
            holes: enhancedHoles ?? _potentialRound!.holes,
            versionId: _potentialRound!.versionId,
            analysis: _potentialRound!.analysis,
            aiSummary: _potentialRound!.aiSummary,
            aiCoachSuggestion: _potentialRound!.aiCoachSuggestion,
            createdAt: _potentialRound!.createdAt,
            playedRoundAt: _potentialRound!.playedRoundAt,
          );
        }
      }

      if (_potentialRound == null) {
        _lastError = 'Failed to parse round. Check console for details.';
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      // Don't validate, enhance, analyze, or save yet
      // That happens after confirmation in finalizeRound()
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

  DGRound _validateAndEnhanceRound(String uid, DGRound round) {
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
              customPenaltyStrokes: workingThrow.customPenaltyStrokes,
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
                customPenaltyStrokes: workingThrow.customPenaltyStrokes,
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
      uid: uid,
      courseId: round.courseId,
      courseName: round.courseName,
      course: round.course,
      layoutId: round.layoutId,
      holes: enhancedHoles,
      id: round.id,
      versionId: round.versionId,
      createdAt: DateTime.now().toIso8601String(),
      playedRoundAt: DateTime.now().toIso8601String(),
    );
  }

  void updateHole(String uid, int holeIndex, DGHole updatedHole) {
    if (_parsedRound != null && holeIndex < _parsedRound!.holes.length) {
      final updatedHoles = List<DGHole>.from(_parsedRound!.holes);
      updatedHoles[holeIndex] = updatedHole;

      _parsedRound = DGRound(
        uid: uid,
        courseId: _parsedRound!.courseId,
        courseName: _parsedRound!.courseName,
        course: _parsedRound!.course,
        layoutId: _parsedRound!.layoutId,
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
    final String? uid = locator.get<AuthService>().currentUid;
    if (uid == null) return;

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

      updateHole(uid, holeIndex, updatedHole);
    }
  }

  /// Adds empty holes to the potential round (for round confirmation workflow)
  void addEmptyHolesToPotentialRound(Set<int> holeNumbers, {int? defaultPar}) {
    final String? uid = locator.get<AuthService>().currentUid;

    if (uid == null ||
        _potentialRound == null ||
        _potentialRound!.holes == null) {
      debugPrint('Cannot add empty holes: no potential round exists');
      return;
    }

    final List<PotentialDGHole> updatedHoles = List<PotentialDGHole>.from(
      _potentialRound!.holes!,
    );

    // Get existing hole numbers to check for duplicates
    final Set<int> existingHoleNumbers = updatedHoles
        .where((h) => h.number != null)
        .map((h) => h.number!)
        .toSet();

    // Get course layout data for filling empty holes
    final CourseLayout? layout =
        _potentialRound!.course?.getLayoutById(
          _potentialRound!.layoutId ?? '',
        ) ??
        _potentialRound!.course?.defaultLayout;

    debugPrint(
      '🎯 addEmptyHolesToPotentialRound: Using layout ${layout?.name} (${layout?.id})',
    );

    for (final int holeNumber in holeNumbers) {
      // Check if hole already exists
      if (existingHoleNumbers.contains(holeNumber)) {
        debugPrint('Hole $holeNumber already exists, skipping...');
        continue;
      }

      // Try to get hole metadata from course layout
      final CourseHole? courseHole = layout?.holes
          .cast<CourseHole?>()
          .firstWhere((h) => h?.holeNumber == holeNumber, orElse: () => null);

      // Use course layout data if available, otherwise use defaults
      final int? holePar = defaultPar ?? courseHole?.par;
      final int? holeFeet = courseHole?.feet;
      final HoleType? holeType = courseHole?.holeType;

      // Log when using course layout data
      if (courseHole != null) {
        if (defaultPar == null) {
          debugPrint(
            '✓ Using par from course layout for hole $holeNumber: ${courseHole.par}',
          );
        }
        debugPrint(
          '✓ Using distance from course layout for hole $holeNumber: ${courseHole.feet} ft',
        );
      }

      // Create empty potential hole
      final PotentialDGHole emptyHole = PotentialDGHole(
        number: holeNumber,
        par: holePar,
        feet: holeFeet,
        throws: [], // Empty throws list
        holeType: holeType,
      );

      // Find correct insertion position (maintain hole number order)
      int insertIndex = updatedHoles.length;
      for (int i = 0; i < updatedHoles.length; i++) {
        if (updatedHoles[i].number != null &&
            updatedHoles[i].number! > holeNumber) {
          insertIndex = i;
          break;
        }
      }

      updatedHoles.insert(insertIndex, emptyHole);
      existingHoleNumbers.add(holeNumber); // Track newly added hole
    }

    _potentialRound = PotentialDGRound(
      uid: uid,
      id: _potentialRound!.id,
      courseName: _potentialRound!.courseName,
      courseId: _potentialRound!.courseId,
      course: _potentialRound!.course,
      layoutId: _potentialRound!.layoutId,
      holes: updatedHoles,
      versionId: _potentialRound!.versionId,
      analysis: _potentialRound!.analysis,
      aiSummary: _potentialRound!.aiSummary,
      aiCoachSuggestion: _potentialRound!.aiCoachSuggestion,
      createdAt: _potentialRound!.createdAt,
      playedRoundAt: _potentialRound!.playedRoundAt,
    );

    notifyListeners();
  }

  /// Re-process a single hole with new voice description
  Future<bool> reProcessHole({
    required int holeIndex,
    required String voiceTranscript,
  }) async {
    final String? uid = locator.get<AuthService>().currentUid;
    if (uid == null) return false;

    // Can work with either parsed round or potential round
    final bool hasParsedRound =
        _parsedRound != null && holeIndex < _parsedRound!.holes.length;
    final bool hasPotentialRound =
        _potentialRound != null &&
        _potentialRound!.holes != null &&
        holeIndex < _potentialRound!.holes!.length;

    if (!hasParsedRound && !hasPotentialRound) {
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

      // Get hole info from whichever round we have
      final int holeNumber;
      final int holePar;
      final int? holeFeet;
      final String courseName;

      if (hasParsedRound) {
        final hole = _parsedRound!.holes[holeIndex];
        holeNumber = hole.number;
        holePar = hole.par;
        holeFeet = hole.feet;
        courseName = _parsedRound!.courseName;
      } else {
        final hole = _potentialRound!.holes![holeIndex];
        holeNumber = hole.number ?? (holeIndex + 1);
        holePar = hole.par ?? 0; // Use 0 as sentinel for unknown par
        holeFeet = hole.feet;
        courseName = _potentialRound!.courseName ?? 'Unknown Course';
      }

      debugPrint('=== RE-PROCESSING HOLE $holeNumber ===');
      debugPrint('Voice transcript: $voiceTranscript');

      // Parse the single hole with Gemini - returns PotentialDGHole
      final potentialHole = await locator
          .get<AiParsingService>()
          .parseSingleHole(
            voiceTranscript: voiceTranscript,
            userBag: bagService.userBag,
            holeNumber: holeNumber,
            existingHolePar: holePar,
            existingHoleFeet: holeFeet,
            courseName: courseName,
          );

      if (potentialHole == null) {
        _lastError = 'Failed to re-parse hole. Check console for details.';
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      debugPrint('Successfully re-parsed hole $holeNumber');

      // Enhance hole with course layout data if needed
      PotentialDGHole enhancedHole = potentialHole;
      if (potentialHole.par == null ||
          potentialHole.feet == null ||
          potentialHole.holeType == null) {
        final Course? course = hasParsedRound
            ? _parsedRound!.course
            : _potentialRound?.course;

        if (course != null) {
          // Get the correct layoutId from either parsed round or potential round
          final String? correctLayoutId = hasParsedRound
              ? _parsedRound!.layoutId
              : _potentialRound?.layoutId;

          final CourseLayout layout =
              course.getLayoutById(correctLayoutId ?? '') ??
              course.defaultLayout;

          debugPrint(
            '🎯 reProcessHole: Using layout ${layout.name} (${layout.id}) for hole $holeNumber',
          );

          final CourseHole? courseHole = layout.holes
              .cast<CourseHole?>()
              .firstWhere(
                (h) => h?.holeNumber == holeNumber,
                orElse: () => null,
              );

          if (courseHole != null) {
            final bool needsPar = potentialHole.par == null;
            final bool needsFeet = potentialHole.feet == null;
            final bool needsHoleType = potentialHole.holeType == null;

            enhancedHole = PotentialDGHole(
              number: potentialHole.number,
              par: potentialHole.par ?? courseHole.par,
              feet: potentialHole.feet ?? courseHole.feet,
              throws: potentialHole.throws,
              holeType: potentialHole.holeType ?? courseHole.holeType,
            );

            // Log what was filled
            if (needsPar) {
              debugPrint(
                '✓ Filled par for hole $holeNumber from course layout: ${courseHole.par}',
              );
            }
            if (needsFeet) {
              debugPrint(
                '✓ Filled distance for hole $holeNumber from course layout: ${courseHole.feet} ft',
              );
            }
            if (needsHoleType && courseHole.holeType != null) {
              debugPrint(
                '✓ Filled holeType for hole $holeNumber from course layout: ${courseHole.holeType?.name}',
              );
            }
          }
        }
      }

      // If we have a parsed round, convert and update it
      if (hasParsedRound) {
        // Check if potential hole has required fields
        if (!enhancedHole.hasRequiredFields) {
          _lastError =
              'Re-parsed hole is missing required fields: ${enhancedHole.getMissingFields().join(', ')}';
          _isProcessing = false;
          notifyListeners();
          return false;
        }

        // Convert to DGHole and update
        final newHole = enhancedHole.toDGHole();
        updateHole(uid, holeIndex, newHole);

        // Re-validate and enhance the entire round
        _parsedRound = _validateAndEnhanceRound(uid, _parsedRound!);

        // Save updated round to shared preferences
        debugPrint('Saving updated round to shared preferences...');
        await locator.get<RoundStorageService>().saveRound(_parsedRound!);
      } else {
        // Update potential round
        final updatedHoles = List<PotentialDGHole>.from(
          _potentialRound!.holes!,
        );
        updatedHoles[holeIndex] = enhancedHole;

        _potentialRound = PotentialDGRound(
          uid: uid,
          id: _potentialRound!.id,
          courseName: _potentialRound!.courseName,
          courseId: _potentialRound!.courseId,
          holes: updatedHoles,
          versionId: _potentialRound!.versionId,
        );
      }

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
    _potentialRound = null;
    _parsedRound = null;
    _lastError = '';
    notifyListeners();
  }

  /// Update a potential hole's basic metadata (number, par, distance)
  void updatePotentialHoleMetadata(
    int holeIndex, {
    int? number,
    int? par,
    int? feet,
  }) {
    final String? uid = locator.get<AuthService>().currentUid;
    if (uid == null) return;

    if (_potentialRound == null || _potentialRound!.holes == null) {
      debugPrint('Cannot update potential hole: no potential round exists');
      return;
    }

    if (holeIndex >= _potentialRound!.holes!.length) {
      debugPrint('Cannot update potential hole: invalid hole index');
      return;
    }

    final PotentialDGHole currentHole = _potentialRound!.holes![holeIndex];

    // Create updated hole with new metadata
    final PotentialDGHole updatedHole = PotentialDGHole(
      number: number ?? currentHole.number,
      par: par ?? currentHole.par,
      feet: feet ?? currentHole.feet,
      throws: currentHole.throws,
      holeType: currentHole.holeType,
    );

    // Update the holes list
    final List<PotentialDGHole> updatedHoles = List<PotentialDGHole>.from(
      _potentialRound!.holes!,
    );
    updatedHoles[holeIndex] = updatedHole;

    _potentialRound = PotentialDGRound(
      uid: uid,
      id: _potentialRound!.id,
      courseName: _potentialRound!.courseName,
      courseId: _potentialRound!.courseId,
      course: _potentialRound!.course,
      layoutId: _potentialRound!.layoutId,
      holes: updatedHoles,
      versionId: _potentialRound!.versionId,
      analysis: _potentialRound!.analysis,
      aiSummary: _potentialRound!.aiSummary,
      aiCoachSuggestion: _potentialRound!.aiCoachSuggestion,
      createdAt: _potentialRound!.createdAt,
      playedRoundAt: _potentialRound!.playedRoundAt,
    );

    // Check if hole is now complete, and if so, auto-convert
    if (updatedHole.hasRequiredFields) {
      debugPrint('Hole $holeIndex is now complete, auto-converting to DGHole');
      _convertHoleToDGHole(holeIndex);
    }

    notifyListeners();
  }

  /// Update an entire potential hole including its throws
  void updatePotentialHole(int holeIndex, PotentialDGHole updatedHole) {
    final String? uid = locator.get<AuthService>().currentUid;

    if (uid == null ||
        _potentialRound == null ||
        _potentialRound!.holes == null) {
      debugPrint('Cannot update potential hole: no potential round exists');
      return;
    }

    if (holeIndex >= _potentialRound!.holes!.length) {
      debugPrint('Cannot update potential hole: invalid hole index');
      return;
    }

    // Update the holes list
    final List<PotentialDGHole> updatedHoles = List<PotentialDGHole>.from(
      _potentialRound!.holes!,
    );
    updatedHoles[holeIndex] = updatedHole;

    _potentialRound = PotentialDGRound(
      uid: uid,
      id: _potentialRound!.id,
      courseName: _potentialRound!.courseName,
      courseId: _potentialRound!.courseId,
      course: _potentialRound!.course,
      layoutId: _potentialRound!.layoutId,
      holes: updatedHoles,
      versionId: _potentialRound!.versionId,
      analysis: _potentialRound!.analysis,
      aiSummary: _potentialRound!.aiSummary,
      aiCoachSuggestion: _potentialRound!.aiCoachSuggestion,
      createdAt: _potentialRound!.createdAt,
      playedRoundAt: _potentialRound!.playedRoundAt,
    );

    // Check if hole is now complete, and if so, auto-convert
    if (updatedHole.hasRequiredFields) {
      debugPrint('Hole $holeIndex is now complete, auto-converting to DGHole');
      _convertHoleToDGHole(holeIndex);
    }

    notifyListeners();
  }

  /// Convert a validated potential hole to final DGHole
  void _convertHoleToDGHole(int holeIndex) {
    if (_potentialRound == null || _potentialRound!.holes == null) {
      return;
    }

    if (holeIndex >= _potentialRound!.holes!.length) {
      return;
    }

    final PotentialDGHole potentialHole = _potentialRound!.holes![holeIndex];

    if (!potentialHole.hasRequiredFields) {
      debugPrint('Cannot convert hole $holeIndex: missing required fields');
      return;
    }

    try {
      // Convert to DGHole (validation check)
      final DGHole validatedHole = potentialHole.toDGHole();

      // Validate and enhance the hole (for validation only, result not used yet)
      _validateAndEnhanceSingleHole(validatedHole);

      debugPrint('Successfully converted hole $holeIndex to DGHole');

      // Note: For now, we keep it in the potential round but mark it as validated
      // The complete conversion to DGRound happens in finalizeRound()
      // This is intentional to maintain the potential round state until final confirmation

      notifyListeners();
    } catch (e) {
      debugPrint('Error converting hole $holeIndex to DGHole: $e');
    }
  }

  /// Validate and enhance a single hole (extracted from _validateAndEnhanceRound)
  DGHole _validateAndEnhanceSingleHole(DGHole hole) {
    final bagService = locator.get<BagService>();

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
            customPenaltyStrokes: workingThrow.customPenaltyStrokes,
            notes: workingThrow.notes,
            rawText: workingThrow.rawText,
            parseConfidence: workingThrow.parseConfidence,
            discName: workingThrow.discName,
            disc: matchedDisc,
          );
        }
      }

      // Validate and correct landingSpot based on distanceFeetAfterThrow
      if (workingThrow.distanceFeetAfterThrow != null) {
        final distance = workingThrow.distanceFeetAfterThrow!;
        final currentSpot = workingThrow.landingSpot;

        // NEVER override OB or off_fairway
        if (currentSpot == LandingSpot.outOfBounds ||
            currentSpot == LandingSpot.offFairway) {
          debugPrint(
            '✓ Preserving ${currentSpot?.name} for throw ${workingThrow.index} in hole ${hole.number}',
          );
        } else {
          // Correct other landing spots based on distance
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
            if (currentSpot == LandingSpot.parked ||
                currentSpot == LandingSpot.circle1 ||
                currentSpot == LandingSpot.circle2) {
              correctLandingSpot = LandingSpot.fairway;
            }
          }

          if (correctLandingSpot != null && correctLandingSpot != currentSpot) {
            debugPrint(
              '⚠️ Correcting landingSpot for throw ${workingThrow.index} in hole ${hole.number}: '
              '${currentSpot?.name} → ${correctLandingSpot.name}',
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
              customPenaltyStrokes: workingThrow.customPenaltyStrokes,
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
      holeType: hole.holeType,
    );
  }

  /// Enhance holes with par, distance, and holeType from course layout
  /// Course layout data is the source of truth
  List<PotentialDGHole> _enhanceHolesWithCourseLayout(
    List<PotentialDGHole> holes,
    Course course,
    String? layoutId,
  ) {
    final CourseLayout layout =
        course.getLayoutById(layoutId ?? 'default') ?? course.defaultLayout;

    final List<PotentialDGHole> enhancedHoles = [];

    for (final PotentialDGHole hole in holes) {
      if (hole.number == null) {
        enhancedHoles.add(hole);
        continue;
      }

      final int holeNumber = hole.number!;

      final CourseHole? courseLayoutHole = layout.holes
          .cast<CourseHole?>()
          .firstWhere((h) => h?.holeNumber == holeNumber, orElse: () => null);

      if (courseLayoutHole == null) {
        enhancedHoles.add(hole);
        continue;
      }

      debugPrint(
        'Hole $holeNumber: par ${hole.par} → ${courseLayoutHole.par}, '
        'distance ${hole.feet}ft → ${courseLayoutHole.feet}ft, '
        'type ${hole.holeType?.name} → ${courseLayoutHole.holeType?.name}',
      );

      final PotentialDGHole enhancedHole = PotentialDGHole(
        number: hole.number,
        par: courseLayoutHole.par,
        feet: courseLayoutHole.feet,
        throws: hole.throws,
        holeType: courseLayoutHole.holeType,
      );

      enhancedHoles.add(enhancedHole);
    }

    return enhancedHoles;
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

  @override
  Future<void> clearOnLogout() async {
    _potentialRound = null;
    _parsedRound = null;
    _isProcessing = false;
    _isReadyToNavigate = false;
    _shouldNavigateToReview = false;
    _lastError = '';
    notifyListeners();
  }
}
