import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/state/record_round_state.dart';

class RecordRoundCubit extends Cubit<RecordRoundState>
    implements ClearOnLogoutProtocol {
  RecordRoundCubit() : super(const RecordRoundInactive());

  static const defaultNumHoles = 18;

  String previousTranscribedText = '';
  String existingTextForHole = '';

  void onHoleIndexChanged(String voiceServiceText, int newIndex) {
    if (state is! RecordRoundActive) return;
    final activeState = state as RecordRoundActive;

    existingTextForHole = activeState.holeDescriptions[newIndex] ?? '';
    previousTranscribedText = voiceServiceText;

    print(
      '\n\non hole index changed, set previousTranscribedText to $voiceServiceText',
    );
    print(
      'set existingTextForHole to $existingTextForHole, old index: $newIndex\n\n',
    );
  }

  void startRecordingRound() {
    emit(
      RecordRoundActive(
        selectedCourse: null,
        selectedDateTime: DateTime.now(),
        holeDescriptions: getEmptyHoleDescriptions(),
        numHoles: defaultNumHoles,
      ),
    );
  }

  void setSelectedTime(DateTime selectedDateTime) {
    if (state is! RecordRoundActive) return;
    emit(
      (state as RecordRoundActive).copyWith(selectedDateTime: selectedDateTime),
    );
  }

  void setSelectedCourse(String selectedCourse) {
    if (state is! RecordRoundActive) return;
    emit((state as RecordRoundActive).copyWith(selectedCourse: selectedCourse));
  }

  void setHoleDescription(String description, {required int index}) {
    if (state is! RecordRoundActive) return;
    final activeState = state as RecordRoundActive;
    // Create a new map to trigger state update
    final updatedHoleDescriptions = Map<int, String>.from(
      activeState.holeDescriptions,
    );
    updatedHoleDescriptions[index] = description;

    emit(activeState.copyWith(holeDescriptions: updatedHoleDescriptions));
  }

  Map<int, String> getEmptyHoleDescriptions() {
    int numHoles = defaultNumHoles.toInt();
    if (state is RecordRoundActive) {
      numHoles = (state as RecordRoundActive).numHoles;
    }

    return Map.fromEntries(
      List<MapEntry<int, String>>.generate(
        numHoles,
        (index) => MapEntry(index, ''),
      ),
    );
  }

  // chatgpt fix to help me with string matching issues
  void onVoiceServiceUpdate(String transcribedText, int holeIndex) {
    if (state is! RecordRoundActive) return;
    final activeState = state as RecordRoundActive;

    // Normalize whitespace
    String clean(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

    final full = clean(transcribedText);
    final prev = clean(previousTranscribedText);

    String delta;

    if (full.startsWith(prev)) {
      // Best-case: exact prefix match
      delta = full.substring(prev.length).trim();
    } else {
      // Fallback: find the longest common prefix
      int i = 0;
      while (i < full.length && i < prev.length && full[i] == prev[i]) {
        i++;
      }
      delta = full.substring(i).trim();
    }

    debugPrint('''
[onVoiceServiceUpdate]
full: $full
prev: $prev
delta: $delta
holeIndex: $holeIndex
''');

    // Build final text
    final updatedText = '$existingTextForHole $delta'.trim();

    final updatedHoleDescriptions = {
      ...activeState.holeDescriptions,
      holeIndex: updatedText,
    };

    emit(activeState.copyWith(holeDescriptions: updatedHoleDescriptions));
  }

  // void onVoiceServiceUpdate(String transcribedText, int holeIndex) {
  //   if (state is! RecordRoundActive) return;

  //   final RecordRoundActive activeState = state as RecordRoundActive;

  //   final String scrubbedText = transcribedText
  //       .replaceAll(previousTranscribedText, '')
  //       .replaceAll('  ', ' ');

  //   debugPrint(
  //     '\n\n[onVoiceServiceUpdate] transcribedText: $transcribedText, scrubbedText $scrubbedText, previousTranscribedText: $previousTranscribedText, holeIndex: $holeIndex\n\n',
  //   );

  //   final String updatedText = '$existingTextForHole $scrubbedText'.trim();
  //   final Map<int, String> updatedHoleDescriptions =
  //       activeState.holeDescriptions;
  //   updatedHoleDescriptions[holeIndex] = updatedText;

  //   final RecordRoundActive updatedActiveState = activeState.copyWith(
  //     holeDescriptions: updatedHoleDescriptions,
  //   );

  //   emit(updatedActiveState);
  // }

  @override
  Future<void> clearOnLogout() async {
    emit(const RecordRoundInactive());
  }
}
