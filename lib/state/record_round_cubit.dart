import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/state/record_round_state.dart';

class RecordRoundCubit extends Cubit<RecordRoundState> {
  RecordRoundCubit() : super(const RecordRoundInactive());

  void startRecordingRound() {
    emit(
      RecordRoundActive(
        selectedCourse: null,
        selectedDateTime: DateTime.now(),
        holeDescriptions: {},
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
    final updatedHoleDescriptions = Map<int, String>.from(activeState.holeDescriptions);
    updatedHoleDescriptions[index] = description;

    emit(activeState.copyWith(holeDescriptions: updatedHoleDescriptions));
  }
}
