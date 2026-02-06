import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/services/ai_generation_service.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';
import 'package:turbo_disc_golf/services/auth/auth_service.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';

class RoundParser extends ChangeNotifier implements ClearOnLogoutProtocol {
  PotentialDGRound? _potentialRound;
  bool _isProcessing = false;
  String _lastError = '';

  PotentialDGRound? get potentialRound => _potentialRound;
  bool get isProcessing => _isProcessing;
  String get lastError => _lastError;

  Future<bool> parseVoiceTranscript(
    String transcript, {
    Course? selectedCourse,
    required String? selectedLayoutId,
    int numHoles = 18,
    List<HoleMetadata>? preParsedHoles,
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

      // Parse round transcript using unified AI service (handles backend/frontend selection)
      debugPrint('Calling AI service to parse round...');
      _potentialRound = await locator
          .get<AIGenerationService>()
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
  /// Only works with potential rounds (before finalization)
  Future<bool> reProcessHole({
    required int holeIndex,
    required String voiceTranscript,
  }) async {
    final String? uid = locator.get<AuthService>().currentUid;
    if (uid == null) return false;

    // Only work with potential rounds
    final bool hasPotentialRound =
        _potentialRound != null &&
        _potentialRound!.holes != null &&
        holeIndex < _potentialRound!.holes!.length;

    if (!hasPotentialRound) {
      _lastError = 'Invalid hole index or no potential round loaded';
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

      // Get hole info from potential round
      final PotentialDGHole hole = _potentialRound!.holes![holeIndex];
      final int holeNumber = hole.number ?? (holeIndex + 1);
      final int holePar = hole.par ?? 0; // Use 0 as sentinel for unknown par
      final int? holeFeet = hole.feet;
      final String courseName = _potentialRound!.courseName ?? 'Unknown Course';

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
        final Course? course = _potentialRound?.course;

        if (course != null) {
          // Get the correct layoutId from potential round
          final String? correctLayoutId = _potentialRound?.layoutId;

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

      // Update potential round with enhanced hole
      final updatedHoles = List<PotentialDGHole>.from(
        _potentialRound!.holes!,
      );
      updatedHoles[holeIndex] = enhancedHole;

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

  void clearPotentialRound() {
    _potentialRound = null;
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

    notifyListeners();
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
    _isProcessing = false;
    _lastError = '';
    notifyListeners();
  }
}
