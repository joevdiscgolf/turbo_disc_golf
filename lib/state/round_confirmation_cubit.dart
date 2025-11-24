import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_round_service.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';
import 'package:turbo_disc_golf/state/round_confirmation_state.dart';
import 'package:turbo_disc_golf/utils/date_formatter.dart';

/// Cubit for managing round confirmation workflow state
/// Tracks the potential round being edited and the current hole being edited
class RoundConfirmationCubit extends Cubit<RoundConfirmationState> {
  RoundConfirmationCubit() : super(const ConfirmingRoundInactive());

  void startRoundConfirmation(
    BuildContext context,
    PotentialDGRound potentialRound,
  ) {
    emit(
      ConfirmingRoundActive(
        potentialRound: potentialRound,
        currentEditingHoleIndex: null,
      ),
    );
  }

  void clearRoundConfirmation() {
    emit(ConfirmingRoundInactive());
  }

  void setCurrentEditingHole(int holeIndex) {
    if (state is! ConfirmingRoundActive) {
      return;
    }
    final ConfirmingRoundActive activeState = state as ConfirmingRoundActive;

    if (activeState.potentialRound.holes == null ||
        holeIndex >= activeState.potentialRound.holes!.length) {
      return;
    }

    emit(activeState.copyWith(currentEditingHoleIndex: holeIndex));
  }

  /// Clear the current editing hole
  void clearCurrentEditingHole() {
    if (state is! ConfirmingRoundActive) {
      return;
    }
    final ConfirmingRoundActive activeState = state as ConfirmingRoundActive;

    emit(activeState.copyWith(clearCurrentEditingHole: true));
  }

  /// Update a potential hole's basic metadata (number, par, distance)
  void updatePotentialHoleMetadata(
    int holeIndex, {
    int? number,
    int? par,
    int? feet,
  }) {
    if (state is! ConfirmingRoundActive) {
      return;
    }
    final ConfirmingRoundActive activeState = state as ConfirmingRoundActive;

    if (activeState.potentialRound.holes == null ||
        holeIndex >= activeState.potentialRound.holes!.length) {
      return;
    }

    final PotentialDGHole currentHole =
        activeState.potentialRound.holes![holeIndex];

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
      activeState.potentialRound.holes!,
    );
    updatedHoles[holeIndex] = updatedHole;

    final updatedRound = PotentialDGRound(
      id: activeState.potentialRound.id,
      courseName: activeState.potentialRound.courseName,
      courseId: activeState.potentialRound.courseId,
      holes: updatedHoles,
      versionId: activeState.potentialRound.versionId,
      analysis: activeState.potentialRound.analysis,
      aiSummary: activeState.potentialRound.aiSummary,
      aiCoachSuggestion: activeState.potentialRound.aiCoachSuggestion,
      createdAt: activeState.potentialRound.createdAt,
      playedRoundAt: activeState.potentialRound.playedRoundAt,
    );

    emit(activeState.copyWith(potentialRound: updatedRound));
  }

  /// Update an entire potential hole including its throws
  void updatePotentialHole(int holeIndex, PotentialDGHole updatedHole) {
    if (state is! ConfirmingRoundActive) {
      return;
    }
    final ConfirmingRoundActive activeState = state as ConfirmingRoundActive;

    if (activeState.potentialRound.holes == null ||
        holeIndex >= activeState.potentialRound.holes!.length) {
      return;
    }

    // Update the holes list
    final List<PotentialDGHole> updatedHoles = List<PotentialDGHole>.from(
      activeState.potentialRound.holes!,
    );
    updatedHoles[holeIndex] = updatedHole;

    final updatedRound = PotentialDGRound(
      id: activeState.potentialRound.id,
      courseName: activeState.potentialRound.courseName,
      courseId: activeState.potentialRound.courseId,
      holes: updatedHoles,
      versionId: activeState.potentialRound.versionId,
      analysis: activeState.potentialRound.analysis,
      aiSummary: activeState.potentialRound.aiSummary,
      aiCoachSuggestion: activeState.potentialRound.aiCoachSuggestion,
      createdAt: activeState.potentialRound.createdAt,
      playedRoundAt: activeState.potentialRound.playedRoundAt,
    );

    emit(activeState.copyWith(potentialRound: updatedRound));
  }

  /// Add a throw to a hole
  /// [addAfterThrowIndex] indicates which throw to insert after (null = append to end)
  /// Semantic convention: addAfterThrowIndex=0 means insert after throw 0 (becomes throw 1)
  void addThrow(int holeIndex, DiscThrow newThrow, {int? addAfterThrowIndex}) {
    if (state is! ConfirmingRoundActive) {
      return;
    }
    final ConfirmingRoundActive activeState = state as ConfirmingRoundActive;

    if (activeState.potentialRound.holes == null ||
        holeIndex >= activeState.potentialRound.holes!.length) {
      return;
    }

    final PotentialDGHole currentHole =
        activeState.potentialRound.holes![holeIndex];
    final List<DiscThrow> updatedThrows = List<DiscThrow>.from(
      currentHole.throws ?? [],
    );

    // Calculate insertion position
    // Semantic convention: addAfterThrowIndex means "insert AFTER throw at this index"
    // - If addAfterThrowIndex=0: insert after throw 0 → insertIndex=1
    // - If addAfterThrowIndex=1: insert after throw 1 → insertIndex=2
    // - If addAfterThrowIndex=null: append to end → insertIndex=length
    // Clamp to safely handle edge cases where index might exceed list bounds
    final int insertIndex = addAfterThrowIndex != null
        ? (addAfterThrowIndex + 1).clamp(0, updatedThrows.length)
        : updatedThrows.length;

    // Insert the new throw
    updatedThrows.insert(
      insertIndex,
      DiscThrow(
        index: insertIndex, // Will be re-indexed below
        purpose: newThrow.purpose,
        technique: newThrow.technique,
        puttStyle: newThrow.puttStyle,
        shotShape: newThrow.shotShape,
        stance: newThrow.stance,
        power: newThrow.power,
        distanceFeetBeforeThrow: newThrow.distanceFeetBeforeThrow,
        distanceFeetAfterThrow: newThrow.distanceFeetAfterThrow,
        elevationChangeFeet: newThrow.elevationChangeFeet,
        windDirection: newThrow.windDirection,
        windStrength: newThrow.windStrength,
        resultRating: newThrow.resultRating,
        landingSpot: newThrow.landingSpot,
        fairwayWidth: newThrow.fairwayWidth,
        penaltyStrokes: newThrow.penaltyStrokes,
        notes: newThrow.notes,
        rawText: newThrow.rawText,
        parseConfidence: newThrow.parseConfidence,
        discName: newThrow.discName,
        disc: newThrow.disc,
      ),
    );

    // Reindex all throws after insertion to ensure sequential indices
    // This ensures throw indices are 0, 1, 2, ... regardless of insertion order
    final List<DiscThrow> reindexedThrows = _reindexThrows(updatedThrows);

    final PotentialDGHole updatedHole = PotentialDGHole(
      number: currentHole.number,
      par: currentHole.par,
      feet: currentHole.feet,
      throws: reindexedThrows,
      holeType: currentHole.holeType,
    );

    updatePotentialHole(holeIndex, updatedHole);
  }

  /// Delete a throw from a hole
  void deleteThrow(int holeIndex, int throwIndex) {
    if (state is! ConfirmingRoundActive) {
      return;
    }
    final ConfirmingRoundActive activeState = state as ConfirmingRoundActive;

    if (activeState.potentialRound.holes == null ||
        holeIndex >= activeState.potentialRound.holes!.length) {
      return;
    }

    final PotentialDGHole currentHole =
        activeState.potentialRound.holes![holeIndex];
    if (currentHole.throws == null ||
        throwIndex >= currentHole.throws!.length) {
      return;
    }

    final List<DiscThrow> updatedThrows = List<DiscThrow>.from(
      currentHole.throws!,
    );
    updatedThrows.removeAt(throwIndex);

    // Reindex remaining throws to ensure sequential indices
    final List<DiscThrow> reindexedThrows = _reindexThrows(updatedThrows);

    final PotentialDGHole updatedHole = PotentialDGHole(
      number: currentHole.number,
      par: currentHole.par,
      feet: currentHole.feet,
      throws: reindexedThrows,
      holeType: currentHole.holeType,
    );

    updatePotentialHole(holeIndex, updatedHole);
  }

  /// Update a throw within a hole
  void updateThrow(int holeIndex, int throwIndex, DiscThrow updatedThrow) {
    if (state is! ConfirmingRoundActive) {
      return;
    }
    final ConfirmingRoundActive activeState = state as ConfirmingRoundActive;

    if (activeState.potentialRound.holes == null ||
        holeIndex >= activeState.potentialRound.holes!.length) {
      return;
    }

    final hole = activeState.potentialRound.holes![holeIndex];
    if (hole.throws == null || throwIndex >= hole.throws!.length) {
      return;
    }

    final updatedThrows = List<DiscThrow>.from(hole.throws!);
    updatedThrows[throwIndex] = DiscThrow(
      index: updatedThrow.index,
      purpose: updatedThrow.purpose,
      technique: updatedThrow.technique,
      puttStyle: updatedThrow.puttStyle,
      shotShape: updatedThrow.shotShape,
      stance: updatedThrow.stance,
      power: updatedThrow.power,
      distanceFeetBeforeThrow: updatedThrow.distanceFeetBeforeThrow,
      distanceFeetAfterThrow: updatedThrow.distanceFeetAfterThrow,
      elevationChangeFeet: updatedThrow.elevationChangeFeet,
      windDirection: updatedThrow.windDirection,
      windStrength: updatedThrow.windStrength,
      resultRating: updatedThrow.resultRating,
      landingSpot: updatedThrow.landingSpot,
      fairwayWidth: updatedThrow.fairwayWidth,
      penaltyStrokes: updatedThrow.penaltyStrokes,
      notes: updatedThrow.notes,
      rawText: updatedThrow.rawText,
      parseConfidence: updatedThrow.parseConfidence,
      discName: updatedThrow.discName,
      disc: updatedThrow.disc,
    );

    final updatedHole = PotentialDGHole(
      number: hole.number,
      par: hole.par,
      feet: hole.feet,
      throws: updatedThrows,
      holeType: hole.holeType,
    );

    updatePotentialHole(holeIndex, updatedHole);
  }

  /// Reorder throws within a hole
  void reorderThrows(int holeIndex, int oldIndex, int newIndex) {
    if (state is! ConfirmingRoundActive) {
      return;
    }
    final ConfirmingRoundActive activeState = state as ConfirmingRoundActive;

    if (activeState.potentialRound.holes == null ||
        holeIndex >= activeState.potentialRound.holes!.length) {
      return;
    }

    final PotentialDGHole currentHole =
        activeState.potentialRound.holes![holeIndex];
    if (currentHole.throws == null ||
        oldIndex >= currentHole.throws!.length ||
        newIndex >= currentHole.throws!.length) {
      return;
    }

    final List<DiscThrow> updatedThrows = List<DiscThrow>.from(
      currentHole.throws!,
    );

    // Remove the throw from the old position
    final DiscThrow movedThrow = updatedThrows.removeAt(oldIndex);

    // Insert it at the new position
    updatedThrows.insert(newIndex, movedThrow);

    // Reindex all throws to ensure sequential indices
    final List<DiscThrow> reindexedThrows = _reindexThrows(updatedThrows);

    final PotentialDGHole updatedHole = PotentialDGHole(
      number: currentHole.number,
      par: currentHole.par,
      feet: currentHole.feet,
      throws: reindexedThrows,
      holeType: currentHole.holeType,
    );

    updatePotentialHole(holeIndex, updatedHole);
  }

  /// Helper method to reindex throws to ensure sequential indices (0, 1, 2, ...)
  List<DiscThrow> _reindexThrows(List<DiscThrow> throws) {
    return throws.asMap().entries.map((entry) {
      final DiscThrow throw_ = entry.value;
      return DiscThrow(
        index: entry.key,
        purpose: throw_.purpose,
        technique: throw_.technique,
        puttStyle: throw_.puttStyle,
        shotShape: throw_.shotShape,
        stance: throw_.stance,
        power: throw_.power,
        distanceFeetBeforeThrow: throw_.distanceFeetBeforeThrow,
        distanceFeetAfterThrow: throw_.distanceFeetAfterThrow,
        elevationChangeFeet: throw_.elevationChangeFeet,
        windDirection: throw_.windDirection,
        windStrength: throw_.windStrength,
        resultRating: throw_.resultRating,
        landingSpot: throw_.landingSpot,
        fairwayWidth: throw_.fairwayWidth,
        penaltyStrokes: throw_.penaltyStrokes,
        notes: throw_.notes,
        rawText: throw_.rawText,
        parseConfidence: throw_.parseConfidence,
        discName: throw_.discName,
        disc: throw_.disc,
      );
    }).toList();
  }

  /// Finalize the potential round after confirmation
  /// Converts PotentialDGRound to DGRound, validates, enhances, and saves
  /// Returns the finalized DGRound or null if validation fails
  Future<DGRound?> finalizeRound() async {
    if (state is! ConfirmingRoundActive) {
      debugPrint('Cannot finalize: no active round confirmation');
      return null;
    }

    final ConfirmingRoundActive activeState = state as ConfirmingRoundActive;
    final PotentialDGRound potentialRound = activeState.potentialRound;

    // Check if potential round has all required fields
    if (!potentialRound.hasRequiredFields) {
      debugPrint(
        'Round is missing required fields: ${potentialRound.getMissingFields().join(', ')}',
      );
      return null;
    }

    debugPrint('Converting PotentialDGRound to DGRound...');

    // Convert to final DGRound
    DGRound parsedRound;
    try {
      parsedRound = potentialRound.toDGRound();
    } catch (e) {
      debugPrint('Failed to convert round: $e');
      return null;
    }

    // Validate and enhance the parsed data
    parsedRound = _validateAndEnhanceRound(parsedRound);

    // Generate analysis from round data
    debugPrint('Generating round analysis...');
    final analysis = RoundAnalysisGenerator.generateAnalysis(parsedRound);

    // Generate AI insights (summary and coaching)
    debugPrint('Generating AI summary and coaching...');
    final insights = await locator
        .get<AiParsingService>()
        .generateRoundInsights(
          round: parsedRound,
          analysis: analysis,
        );

    // Update round with analysis and insights
    final String currentTimestamp = getCurrentISOString();
    parsedRound = DGRound(
      id: parsedRound.id,
      courseName: parsedRound.courseName,
      courseId: parsedRound.courseId,
      holes: parsedRound.holes,
      analysis: analysis,
      aiSummary: insights['summary'],
      aiCoachSuggestion: insights['coaching'],
      versionId: 1, // Set initial version ID
      createdAt: currentTimestamp,
      playedRoundAt: currentTimestamp,
    );

    // Save to shared preferences for future use
    debugPrint('Saving parsed round to shared preferences...');
    final savedLocally = await locator
        .get<RoundStorageService>()
        .saveRound(parsedRound);
    if (savedLocally) {
      debugPrint('Successfully saved round to shared preferences');
    } else {
      debugPrint('Failed to save round to shared preferences');
    }

    // Save to Firestore
    debugPrint('Saving parsed round to Firestore...');
    final firestoreSuccess = await locator
        .get<FirestoreRoundService>()
        .addRound(parsedRound);
    if (firestoreSuccess) {
      debugPrint('Successfully saved round to Firestore');
    } else {
      debugPrint('Failed to save round to Firestore');
    }

    return parsedRound;
  }

  /// Validate and enhance a round
  /// Ensures all throws have valid disc references and correct landing spots
  DGRound _validateAndEnhanceRound(DGRound round) {
    final BagService bagService = locator.get<BagService>();

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
}
