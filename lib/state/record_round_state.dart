import 'package:flutter/material.dart';

@immutable
abstract class RecordRoundState {
  const RecordRoundState();
}

class RecordRoundInactive extends RecordRoundState {
  const RecordRoundInactive();
}

class RecordRoundActive extends RecordRoundState {
  const RecordRoundActive({
    required this.selectedCourse,
    required this.selectedDateTime,
    required this.holeDescriptions,
    this.totalHoles = 18,
  });

  final String? selectedCourse;
  final DateTime selectedDateTime;
  final Map<int, String> holeDescriptions;
  final int totalHoles;

  RecordRoundActive copyWith({
    String? selectedCourse,
    DateTime? selectedDateTime,
    Map<int, String>? holeDescriptions,
    int? totalHoles,
  }) {
    return RecordRoundActive(
      selectedCourse: selectedCourse ?? this.selectedCourse,
      selectedDateTime: selectedDateTime ?? this.selectedDateTime,
      holeDescriptions: holeDescriptions ?? this.holeDescriptions,
      totalHoles: totalHoles ?? this.totalHoles,
    );
  }

  String get fullTranscript {
    if (holeDescriptions.isEmpty) {
      return '';
    }

    // Sort by hole index (key) and combine descriptions
    final List<int> sortedKeys = holeDescriptions.keys.toList()..sort();
    return sortedKeys
        .map((int holeIndex) => holeDescriptions[holeIndex] ?? '')
        .where((String description) => description.isNotEmpty)
        .join(' ');
  }
}
