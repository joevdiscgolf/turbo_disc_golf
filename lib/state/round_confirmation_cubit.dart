import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

/// State for the round confirmation workflow
class RoundConfirmationState {
  const RoundConfirmationState({
    required this.potentialRound,
    this.currentEditingHoleIndex,
    this.parController,
    this.distanceController,
    this.parFocus,
    this.distanceFocus,
  });

  final PotentialDGRound potentialRound;
  final int? currentEditingHoleIndex;
  final TextEditingController? parController;
  final TextEditingController? distanceController;
  final FocusNode? parFocus;
  final FocusNode? distanceFocus;

  /// Get the current hole being edited
  PotentialDGHole? get currentEditingHole {
    if (currentEditingHoleIndex == null ||
        potentialRound.holes == null ||
        currentEditingHoleIndex! >= potentialRound.holes!.length) {
      return null;
    }
    return potentialRound.holes![currentEditingHoleIndex!];
  }

  /// Getters for convenience
  int get par => currentEditingHole?.par ?? 0;
  int get distance => currentEditingHole?.feet ?? 0;
  int get strokes => currentEditingHole?.throws?.length ?? 0;
  bool get hasRequiredFields => currentEditingHole?.hasRequiredFields ?? false;

  RoundConfirmationState copyWith({
    PotentialDGRound? potentialRound,
    int? currentEditingHoleIndex,
    bool clearCurrentEditingHole = false,
    TextEditingController? parController,
    TextEditingController? distanceController,
    FocusNode? parFocus,
    FocusNode? distanceFocus,
  }) {
    return RoundConfirmationState(
      potentialRound: potentialRound ?? this.potentialRound,
      currentEditingHoleIndex: clearCurrentEditingHole
          ? null
          : (currentEditingHoleIndex ?? this.currentEditingHoleIndex),
      parController: parController ?? this.parController,
      distanceController: distanceController ?? this.distanceController,
      parFocus: parFocus ?? this.parFocus,
      distanceFocus: distanceFocus ?? this.distanceFocus,
    );
  }
}

/// Cubit for managing round confirmation workflow state
/// Tracks the potential round being edited and the current hole being edited
class RoundConfirmationCubit extends Cubit<RoundConfirmationState> {
  RoundConfirmationCubit(PotentialDGRound initialRound)
      : super(RoundConfirmationState(potentialRound: initialRound));

  /// Set the current hole being edited and initialize text controllers
  void setCurrentEditingHole(int holeIndex) {
    if (state.potentialRound.holes == null ||
        holeIndex >= state.potentialRound.holes!.length) {
      return;
    }

    // Dispose old controllers if they exist
    _disposeEditingControllers();

    final PotentialDGHole hole = state.potentialRound.holes![holeIndex];

    // Initialize new controllers with current hole data
    final parController = TextEditingController(
      text: hole.par?.toString() ?? '',
    );
    final distanceController = TextEditingController(
      text: hole.feet?.toString() ?? '',
    );
    final parFocus = FocusNode();
    final distanceFocus = FocusNode();

    emit(state.copyWith(
      currentEditingHoleIndex: holeIndex,
      parController: parController,
      distanceController: distanceController,
      parFocus: parFocus,
      distanceFocus: distanceFocus,
    ));
  }

  /// Clear the current editing hole
  void clearCurrentEditingHole() {
    _disposeEditingControllers();
    emit(state.copyWith(clearCurrentEditingHole: true));
  }

  /// Update text controllers when hole data changes externally
  /// Only updates controllers if they don't have focus (user not editing)
  void updateEditingControllersFromHole() {
    if (state.currentEditingHoleIndex == null ||
        state.currentEditingHole == null) {
      return;
    }

    final PotentialDGHole hole = state.currentEditingHole!;

    // Only update controllers if they don't have focus
    if (state.parFocus != null &&
        !state.parFocus!.hasFocus &&
        state.parController != null) {
      state.parController!.text = hole.par?.toString() ?? '';
    }
    if (state.distanceFocus != null &&
        !state.distanceFocus!.hasFocus &&
        state.distanceController != null) {
      state.distanceController!.text = hole.feet?.toString() ?? '';
    }
  }

  /// Gets the current metadata values from the text controllers.
  /// Returns a map with par and distance keys.
  Map<String, int?> getMetadataValues() {
    if (state.parController == null || state.distanceController == null) {
      return {'par': null, 'distance': null};
    }

    final int? par = state.parController!.text.isEmpty
        ? null
        : int.tryParse(state.parController!.text);
    final int? distance = state.distanceController!.text.isEmpty
        ? null
        : int.tryParse(state.distanceController!.text);

    return {'par': par, 'distance': distance};
  }

  /// Update a potential hole's basic metadata (number, par, distance)
  void updatePotentialHoleMetadata(
    int holeIndex, {
    int? number,
    int? par,
    int? feet,
  }) {
    if (state.potentialRound.holes == null ||
        holeIndex >= state.potentialRound.holes!.length) {
      return;
    }

    final PotentialDGHole currentHole = state.potentialRound.holes![holeIndex];

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
      state.potentialRound.holes!,
    );
    updatedHoles[holeIndex] = updatedHole;

    final updatedRound = PotentialDGRound(
      id: state.potentialRound.id,
      courseName: state.potentialRound.courseName,
      courseId: state.potentialRound.courseId,
      holes: updatedHoles,
      versionId: state.potentialRound.versionId,
      analysis: state.potentialRound.analysis,
      aiSummary: state.potentialRound.aiSummary,
      aiCoachSuggestion: state.potentialRound.aiCoachSuggestion,
      createdAt: state.potentialRound.createdAt,
      playedRoundAt: state.potentialRound.playedRoundAt,
    );

    emit(state.copyWith(potentialRound: updatedRound));

    // Update text controllers if this is the current editing hole
    if (state.currentEditingHoleIndex == holeIndex) {
      updateEditingControllersFromHole();
    }
  }

  /// Update an entire potential hole including its throws
  void updatePotentialHole(int holeIndex, PotentialDGHole updatedHole) {
    if (state.potentialRound.holes == null ||
        holeIndex >= state.potentialRound.holes!.length) {
      return;
    }

    // Update the holes list
    final List<PotentialDGHole> updatedHoles = List<PotentialDGHole>.from(
      state.potentialRound.holes!,
    );
    updatedHoles[holeIndex] = updatedHole;

    final updatedRound = PotentialDGRound(
      id: state.potentialRound.id,
      courseName: state.potentialRound.courseName,
      courseId: state.potentialRound.courseId,
      holes: updatedHoles,
      versionId: state.potentialRound.versionId,
      analysis: state.potentialRound.analysis,
      aiSummary: state.potentialRound.aiSummary,
      aiCoachSuggestion: state.potentialRound.aiCoachSuggestion,
      createdAt: state.potentialRound.createdAt,
      playedRoundAt: state.potentialRound.playedRoundAt,
    );

    emit(state.copyWith(potentialRound: updatedRound));

    // Update text controllers if this is the current editing hole
    if (state.currentEditingHoleIndex == holeIndex) {
      updateEditingControllersFromHole();
    }
  }

  /// Update a throw within a hole
  void updateThrow(int holeIndex, int throwIndex, DiscThrow updatedThrow) {
    if (state.potentialRound.holes == null ||
        holeIndex >= state.potentialRound.holes!.length) {
      return;
    }

    final hole = state.potentialRound.holes![holeIndex];
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

  /// Dispose text controllers and focus nodes
  void _disposeEditingControllers() {
    state.parController?.dispose();
    state.distanceController?.dispose();
    state.parFocus?.dispose();
    state.distanceFocus?.dispose();
  }

  @override
  Future<void> close() {
    _disposeEditingControllers();
    return super.close();
  }
}
