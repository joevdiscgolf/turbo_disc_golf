import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';

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
  });

  final PotentialDGRound potentialRound;
  final int? currentEditingHoleIndex;

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
  }) {
    return ConfirmingRoundActive(
      potentialRound: potentialRound ?? this.potentialRound,
      currentEditingHoleIndex: clearCurrentEditingHole
          ? null
          : (currentEditingHoleIndex ?? this.currentEditingHoleIndex),
    );
  }
}
