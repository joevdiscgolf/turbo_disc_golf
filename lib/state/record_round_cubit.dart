import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/state/record_round_state.dart';

class RecordRoundCubit extends Cubit<RecordRoundState> {
  RecordRoundCubit() : super(const RecordRoundInactive());

  static const defaultNumHoles = 18;

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
}
