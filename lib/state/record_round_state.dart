import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';

@immutable
abstract class RecordRoundState {
  const RecordRoundState();
}

class RecordRoundInactive extends RecordRoundState {
  const RecordRoundInactive();
}

class RecordRoundActive extends RecordRoundState {
  static const int defaultNumHoles = 18;

  const RecordRoundActive({
    required this.selectedCourse,
    required this.selectedDateTime,
    required this.holeDescriptions,
    this.selectedLayout,
    this.isListening = false,
    this.pausingBetweenHoles = false,
    this.isStartingListening = false,
    this.currentHoleIndex = 0,
    this.importedScores,
    this.importedHoleMetadata,
  });

  final Course? selectedCourse;
  final CourseLayout? selectedLayout;
  final DateTime selectedDateTime;
  final Map<int, String> holeDescriptions;
  final bool isListening;
  final bool isStartingListening;
  final bool pausingBetweenHoles;
  final int currentHoleIndex;
  final Map<int, int>? importedScores; // holeIndex (0-based) -> score
  final Map<int, HoleMetadata>? importedHoleMetadata; // holeIndex (0-based) -> full metadata

  /// Number of holes, derived from selected layout or default
  int get numHoles => selectedLayout?.holes.length ?? defaultNumHoles;

  RecordRoundActive copyWith({
    Course? selectedCourse,
    CourseLayout? selectedLayout,
    DateTime? selectedDateTime,
    Map<int, String>? holeDescriptions,
    bool? isListening,
    bool? isStartingListening,
    bool? pausingBetweenHoles,
    int? currentHoleIndex,
    Map<int, int>? importedScores,
    Map<int, HoleMetadata>? importedHoleMetadata,
    bool clearImportedScores = false,
  }) {
    return RecordRoundActive(
      selectedCourse: selectedCourse ?? this.selectedCourse,
      selectedLayout: selectedLayout ?? this.selectedLayout,
      selectedDateTime: selectedDateTime ?? this.selectedDateTime,
      holeDescriptions: holeDescriptions ?? this.holeDescriptions,
      isListening: isListening ?? this.isListening,
      isStartingListening: isStartingListening ?? this.isStartingListening,
      pausingBetweenHoles: pausingBetweenHoles ?? this.pausingBetweenHoles,
      currentHoleIndex: currentHoleIndex ?? this.currentHoleIndex,
      importedScores:
          clearImportedScores ? null : (importedScores ?? this.importedScores),
      importedHoleMetadata: clearImportedScores
          ? null
          : (importedHoleMetadata ?? this.importedHoleMetadata),
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
