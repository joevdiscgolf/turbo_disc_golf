import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';

/// Animation phases for the round finalization flow
enum AnimationPhase {
  idle, // User is editing/confirming the round
  transitioning, // Text fading out
  exploding, // Explosion effect
  zooming, // Hyperspace zoom
  revealing, // Content reveal animation
}

/// State for the round confirmation workflow
@immutable
abstract class RoundConfirmationState {
  const RoundConfirmationState();
}

class ConfirmingRoundInactive extends RoundConfirmationState {
  const ConfirmingRoundInactive();
}

class ConfirmingRoundActive extends RoundConfirmationState {
  const ConfirmingRoundActive({
    required this.potentialRound,
    this.currentEditingHoleIndex,
    this.animationPhase = AnimationPhase.idle,
    this.parsedRound,
  });

  final PotentialDGRound potentialRound;
  final int? currentEditingHoleIndex;
  final AnimationPhase animationPhase;
  final DGRound? parsedRound;

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

  ConfirmingRoundActive copyWith({
    PotentialDGRound? potentialRound,
    int? currentEditingHoleIndex,
    bool clearCurrentEditingHole = false,
    AnimationPhase? animationPhase,
    DGRound? parsedRound,
    bool clearParsedRound = false,
  }) {
    return ConfirmingRoundActive(
      potentialRound: potentialRound ?? this.potentialRound,
      currentEditingHoleIndex: clearCurrentEditingHole
          ? null
          : (currentEditingHoleIndex ?? this.currentEditingHoleIndex),
      animationPhase: animationPhase ?? this.animationPhase,
      parsedRound:
          clearParsedRound ? null : (parsedRound ?? this.parsedRound),
    );
  }
}
