import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';
import 'package:turbo_disc_golf/services/rounds_service.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/state/round_history_cubit.dart';
import 'package:turbo_disc_golf/state/round_review_state.dart';

/// Cubit for managing round review workflow state
/// Tracks the completed round being edited and the current hole being edited
class RoundReviewCubit extends Cubit<RoundReviewState>
    implements ClearOnLogoutProtocol {
  RoundReviewCubit({required this.roundHistoryCubit})
    : super(const ReviewingRoundInactive());

  final RoundHistoryCubit roundHistoryCubit;

  void startRoundReview(DGRound round) {
    emit(ReviewingRoundActive(round: round, currentEditingHoleIndex: null));
  }

  void clearRoundReview() {
    emit(const ReviewingRoundInactive());
  }

  void setCurrentEditingHole(int holeIndex) {
    if (state is! ReviewingRoundActive) {
      return;
    }
    final ReviewingRoundActive activeState = state as ReviewingRoundActive;

    if (holeIndex >= activeState.round.holes.length) {
      return;
    }

    emit(activeState.copyWith(currentEditingHoleIndex: holeIndex));
  }

  /// Clear the current editing hole
  void clearCurrentEditingHole() {
    if (state is! ReviewingRoundActive) {
      return;
    }
    final ReviewingRoundActive activeState = state as ReviewingRoundActive;

    emit(activeState.copyWith(clearCurrentEditingHole: true));
  }

  /// Update a hole's basic metadata (number, par, distance)
  void updateHoleMetadata(int holeIndex, {int? number, int? par, int? feet}) {
    if (state is! ReviewingRoundActive) {
      return;
    }
    final ReviewingRoundActive activeState = state as ReviewingRoundActive;

    if (holeIndex >= activeState.round.holes.length) {
      return;
    }

    final DGHole currentHole = activeState.round.holes[holeIndex];

    // Create updated hole with new metadata
    final DGHole updatedHole = DGHole(
      number: number ?? currentHole.number,
      par: par ?? currentHole.par,
      feet: feet ?? currentHole.feet,
      throws: currentHole.throws,
      holeType: currentHole.holeType,
    );

    // Update the holes list
    final List<DGHole> updatedHoles = List<DGHole>.from(
      activeState.round.holes,
    );
    updatedHoles[holeIndex] = updatedHole;

    final DGRound updatedRound = activeState.round.copyWith(
      holes: updatedHoles,
      versionId: activeState.round.versionId + 1,
    );

    emit(activeState.copyWith(round: updatedRound));
    _saveRound(updatedRound);
  }

  /// Update an entire hole including its throws
  void updateHole(int holeIndex, DGHole updatedHole) {
    if (state is! ReviewingRoundActive) {
      return;
    }
    final ReviewingRoundActive activeState = state as ReviewingRoundActive;

    if (holeIndex >= activeState.round.holes.length) {
      return;
    }

    // Update the holes list
    final List<DGHole> updatedHoles = List<DGHole>.from(
      activeState.round.holes,
    );
    updatedHoles[holeIndex] = updatedHole;

    final DGRound updatedRound = activeState.round.copyWith(
      holes: updatedHoles,
      versionId: activeState.round.versionId + 1,
    );

    emit(activeState.copyWith(round: updatedRound));
    _saveRound(updatedRound);
  }

  /// Add a throw to a hole
  /// [addAfterThrowIndex] indicates which throw to insert after (null = append to end)
  /// Semantic convention: addAfterThrowIndex=0 means insert after throw 0 (becomes throw 1)
  void addThrow(int holeIndex, DiscThrow newThrow, {int? addAfterThrowIndex}) {
    if (state is! ReviewingRoundActive) {
      return;
    }
    final ReviewingRoundActive activeState = state as ReviewingRoundActive;

    if (holeIndex >= activeState.round.holes.length) {
      return;
    }

    final DGHole currentHole = activeState.round.holes[holeIndex];
    final List<DiscThrow> updatedThrows = List<DiscThrow>.from(
      currentHole.throws,
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
        customPenaltyStrokes: newThrow.customPenaltyStrokes,
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

    final DGHole updatedHole = DGHole(
      number: currentHole.number,
      par: currentHole.par,
      feet: currentHole.feet,
      throws: reindexedThrows,
      holeType: currentHole.holeType,
    );

    updateHole(holeIndex, updatedHole);
  }

  /// Delete a throw from a hole
  void deleteThrow(int holeIndex, int throwIndex) {
    if (state is! ReviewingRoundActive) {
      return;
    }
    final ReviewingRoundActive activeState = state as ReviewingRoundActive;

    if (holeIndex >= activeState.round.holes.length) {
      return;
    }

    final DGHole currentHole = activeState.round.holes[holeIndex];
    if (throwIndex >= currentHole.throws.length) {
      return;
    }

    final List<DiscThrow> updatedThrows = List<DiscThrow>.from(
      currentHole.throws,
    );
    updatedThrows.removeAt(throwIndex);

    // Reindex remaining throws to ensure sequential indices
    final List<DiscThrow> reindexedThrows = _reindexThrows(updatedThrows);

    final DGHole updatedHole = DGHole(
      number: currentHole.number,
      par: currentHole.par,
      feet: currentHole.feet,
      throws: reindexedThrows,
      holeType: currentHole.holeType,
    );

    updateHole(holeIndex, updatedHole);
  }

  /// Update a throw within a hole
  void updateThrow(int holeIndex, int throwIndex, DiscThrow updatedThrow) {
    if (state is! ReviewingRoundActive) {
      return;
    }
    final ReviewingRoundActive activeState = state as ReviewingRoundActive;

    if (holeIndex >= activeState.round.holes.length) {
      return;
    }

    final DGHole hole = activeState.round.holes[holeIndex];
    if (throwIndex >= hole.throws.length) {
      return;
    }

    final List<DiscThrow> updatedThrows = List<DiscThrow>.from(hole.throws);
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
      customPenaltyStrokes: updatedThrow.customPenaltyStrokes,
      notes: updatedThrow.notes,
      rawText: updatedThrow.rawText,
      parseConfidence: updatedThrow.parseConfidence,
      discName: updatedThrow.discName,
      disc: updatedThrow.disc,
    );

    final DGHole updatedHole = DGHole(
      number: hole.number,
      par: hole.par,
      feet: hole.feet,
      throws: updatedThrows,
      holeType: hole.holeType,
    );

    updateHole(holeIndex, updatedHole);
  }

  /// Reorder throws within a hole
  void reorderThrows(int holeIndex, int oldIndex, int newIndex) {
    if (state is! ReviewingRoundActive) {
      return;
    }
    final ReviewingRoundActive activeState = state as ReviewingRoundActive;

    if (holeIndex >= activeState.round.holes.length) {
      return;
    }

    final DGHole currentHole = activeState.round.holes[holeIndex];
    if (oldIndex >= currentHole.throws.length ||
        newIndex >= currentHole.throws.length) {
      return;
    }

    final List<DiscThrow> updatedThrows = List<DiscThrow>.from(
      currentHole.throws,
    );

    // Remove the throw from the old position
    final DiscThrow movedThrow = updatedThrows.removeAt(oldIndex);

    // Insert it at the new position
    updatedThrows.insert(newIndex, movedThrow);

    // Reindex all throws to ensure sequential indices
    final List<DiscThrow> reindexedThrows = _reindexThrows(updatedThrows);

    final DGHole updatedHole = DGHole(
      number: currentHole.number,
      par: currentHole.par,
      feet: currentHole.feet,
      throws: reindexedThrows,
      holeType: currentHole.holeType,
    );

    updateHole(holeIndex, updatedHole);
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
        customPenaltyStrokes: throw_.customPenaltyStrokes,
        notes: throw_.notes,
        rawText: throw_.rawText,
        parseConfidence: throw_.parseConfidence,
        discName: throw_.discName,
        disc: throw_.disc,
      );
    }).toList();
  }

  /// Update the entire round (useful for AI content updates)
  void updateRoundData(DGRound updatedRound) {
    if (state is! ReviewingRoundActive) {
      return;
    }
    final ReviewingRoundActive activeState = state as ReviewingRoundActive;
    emit(activeState.copyWith(round: updatedRound));
    _saveRound(updatedRound);
  }

  /// Save the round to both local storage and Firestore
  Future<void> _saveRound(DGRound round) async {
    // Save to shared preferences
    final bool savedLocally = await locator
        .get<RoundStorageService>()
        .saveRound(round);
    if (savedLocally) {
      debugPrint('Successfully saved round to shared preferences');
    } else {
      debugPrint('Failed to save round to shared preferences');
    }

    // Save to Firestore
    final bool firestoreSuccess = await locator
        .get<RoundsService>()
        .updateRound(round);
    if (firestoreSuccess) {
      debugPrint('Successfully saved round to Firestore');

      // Update the round in round history
      roundHistoryCubit.updateRound(round);
    } else {
      debugPrint('Failed to save round to Firestore');
    }
  }

  @override
  Future<void> clearOnLogout() async {
    emit(const ReviewingRoundInactive());
  }
}
