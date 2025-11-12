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

    final updatedThrows = List<PotentialDiscThrow>.from(hole.throws!);
    updatedThrows[throwIndex] = PotentialDiscThrow(
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
}
