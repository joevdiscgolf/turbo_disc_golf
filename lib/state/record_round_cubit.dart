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

  void onVoiceServiceUpdate(String transcribedText, int holeIndex) {
    if (state is! RecordRoundActive) return;

    final RecordRoundActive activeState = state as RecordRoundActive;

    final String scrubbedText = transcribedText
        .replaceAll(previousTranscribedText, '')
        .replaceAll('  ', ' ');

    debugPrint(
      '[onVoiceServiceUpdate] transcribedText: $transcribedText, scrubbedText $scrubbedText',
    );

    final String updatedText = '$existingTextForHole $scrubbedText'.trim();
    final Map<int, String> updatedHoleDescriptions =
        activeState.holeDescriptions;
    updatedHoleDescriptions[holeIndex] = updatedText;

    final RecordRoundActive updatedActiveState = activeState.copyWith(
      holeDescriptions: updatedHoleDescriptions,
    );

    emit(updatedActiveState);
  }

  @override
  Future<void> clearOnLogout() async {
    emit(const RecordRoundInactive());
  }
}
