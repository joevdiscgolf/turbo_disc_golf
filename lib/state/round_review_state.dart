import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';

/// State for the round review workflow
@immutable
abstract class RoundReviewState {
  const RoundReviewState();
}

class ReviewingRoundInactive extends RoundReviewState {
  const ReviewingRoundInactive();
}

class ReviewingRoundActive extends RoundReviewState {
  const ReviewingRoundActive({
    required this.round,
    this.currentEditingHoleIndex,
  });

  final DGRound round;
  final int? currentEditingHoleIndex;

  /// Get the current hole being edited
  DGHole? get currentEditingHole {
    if (currentEditingHoleIndex == null ||
        currentEditingHoleIndex! >= round.holes.length) {
      return null;
    }
    return round.holes[currentEditingHoleIndex!];
  }

  /// Getters for convenience
  int get par => currentEditingHole?.par ?? 0;
  int get distance => currentEditingHole?.feet ?? 0;
  int get strokes => currentEditingHole?.throws.length ?? 0;

  ReviewingRoundActive copyWith({
    DGRound? round,
    int? currentEditingHoleIndex,
    bool clearCurrentEditingHole = false,
  }) {
    return ReviewingRoundActive(
      round: round ?? this.round,
      currentEditingHoleIndex: clearCurrentEditingHole
          ? null
          : (currentEditingHoleIndex ?? this.currentEditingHoleIndex),
    );
  }
}
