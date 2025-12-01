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
    required this.numHoles,
  });

  final String? selectedCourse;
  final DateTime selectedDateTime;
  final Map<int, String> holeDescriptions;
  final int numHoles;

  RecordRoundActive copyWith({
    String? selectedCourse,
    DateTime? selectedDateTime,
    Map<int, String>? holeDescriptions,
    int? numHoles,
  }) {
    return RecordRoundActive(
      selectedCourse: selectedCourse ?? this.selectedCourse,
      selectedDateTime: selectedDateTime ?? this.selectedDateTime,
      holeDescriptions: holeDescriptions ?? this.holeDescriptions,
      numHoles: numHoles ?? this.numHoles,
    );
  }

  String get fullTranscript {
    if (holeDescriptions.isEmpty) {
      return '';
    }

    // Sort by hole index (key) and combine descriptions
    final List<int> sortedKeys = holeDescriptions.keys.toList()..sort();
    final String transcript = sortedKeys
        .map((int holeIndex) {
          final String description = holeDescriptions[holeIndex] ?? '';
          if (description.isEmpty) {
            return '';
          }
          return 'Hole $holeIndex:\n$description';
        })
        .where((String description) => description.isNotEmpty)
        .join('\n\n');

    debugPrint('all hole descriptions:');
    debugPrint(holeDescriptions.toString());
    debugPrint('Full transcript:\n$transcript');
    return transcript;
  }
}
