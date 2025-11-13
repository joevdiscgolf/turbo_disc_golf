import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/state/round_confirmation_state.dart';

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
}
