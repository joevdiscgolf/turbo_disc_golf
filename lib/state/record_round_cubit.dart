import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/services/courses/courses_service.dart';
import 'package:turbo_disc_golf/services/voice/base_voice_recording_service.dart';
import 'package:turbo_disc_golf/state/record_round_state.dart';

class RecordRoundCubit extends Cubit<RecordRoundState>
    implements ClearOnLogoutProtocol {
  RecordRoundCubit() : super(const RecordRoundInactive());

  static const defaultNumHoles = 18;

  List<Course> courses = List.from(kTestCourses);

  // Voice service fields
  late BaseVoiceRecordingService _voiceService;
  String _textWhenListeningStarted = '';
  bool _isStoppingListening = false;

  Future<void> _safeStartListening() async {
    if (_isStoppingListening) {
      return;
    }

    await _voiceService.startListening();
  }

  Future<void> _safeStopListening({
    required bool isNavigatingFromDifferentHole,
  }) async {
    if (state is! RecordRoundActive) return;
    final RecordRoundActive activeState = state as RecordRoundActive;

    _isStoppingListening = true;
    try {
      await _voiceService.stopListening();

      if (isNavigatingFromDifferentHole) {
        emit(activeState.copyWith(pausingBetweenHoles: true));
      }

      await Future.delayed(const Duration(milliseconds: 200));
      if (isNavigatingFromDifferentHole) {
        emit(activeState.copyWith(pausingBetweenHoles: false));
      }
    } finally {
      // Always clear flag, even if stop throws error
      _isStoppingListening = false;
    }
  }

  void startRecordingRound() {
    // don't overwrite if a round description already exists.
    if (state is RecordRoundActive) return;

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

  void setSelectedCourse(Course selectedCourse, {String? layoutId}) {
    if (state is! RecordRoundActive) return;
    emit((state as RecordRoundActive).copyWith(
      selectedCourse: selectedCourse,
      selectedLayoutId: layoutId,
    ));
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

  void appendToHoleDescription(String newText, {required int index}) {
    if (state is! RecordRoundActive) return;
    final RecordRoundActive activeState = state as RecordRoundActive;

    // Get existing text for this hole
    final String existingText = activeState.holeDescriptions[index] ?? '';

    // Combine texts with proper spacing
    final String combinedText = existingText.isEmpty
        ? newText.trim()
        : '${existingText.trim()} ${newText.trim()}';

    // Save combined text using setHoleDescription
    setHoleDescription(combinedText, index: index);
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

  // Voice service management
  void initializeVoiceService() {
    _voiceService = locator.get<BaseVoiceRecordingService>();
    _voiceService.initialize();
    _voiceService.addListener(_onVoiceServiceUpdate);
  }

  void disposeVoiceService() {
    _voiceService.removeListener(_onVoiceServiceUpdate);
  }

  void _onVoiceServiceUpdate() {
    if (state is! RecordRoundActive) return;
    final RecordRoundActive activeState = state as RecordRoundActive;

    // Calculate new state values
    final bool newIsListening = _voiceService.isListening;
    final bool newIsStartingListening =
        (newIsListening && activeState.isStartingListening)
        ? false // Clear loading when listening starts
        : activeState.isStartingListening;

    // Emit once if anything changed
    if (newIsListening != activeState.isListening ||
        newIsStartingListening != activeState.isStartingListening) {
      emit(
        activeState.copyWith(
          isListening: newIsListening,
          isStartingListening: newIsStartingListening,
        ),
      );
    }

    // Process transcription when listening
    if (_voiceService.isListening) {
      final String sessionText = _voiceService.transcribedText;
      final String combinedText = _textWhenListeningStarted.isEmpty
          ? sessionText
          : '${_textWhenListeningStarted.trim()} ${sessionText.trim()}';

      setHoleDescription(combinedText, index: activeState.currentHoleIndex);
    }
  }

  // Voice control methods
  Future<void> toggleListening() async {
    if (state is! RecordRoundActive) return;
    final RecordRoundActive activeState = state as RecordRoundActive;

    if (_voiceService.isListening) {
      // Stop listening - voice service listener will update isListening state

      await _safeStopListening(isNavigatingFromDifferentHole: false);
    } else {
      // Capture baseline text (what exists before we start listening)
      _textWhenListeningStarted =
          activeState.holeDescriptions[activeState.currentHoleIndex] ?? '';

      // Show loading state
      emit(activeState.copyWith(isStartingListening: true));

      // Start listening - voice service listener will clear isStartingListening when ready
      await _safeStartListening();
    }
  }

  Future<void> stopListening() async {
    if (state is! RecordRoundActive) return;

    if (_voiceService.isListening) {
      // Stop listening - voice service listener will update isListening state
      await _safeStopListening(isNavigatingFromDifferentHole: false);
    }
  }

  Future<void> navigateToHole(int newHoleIndex) async {
    if (state is! RecordRoundActive) return;
    final RecordRoundActive activeState = state as RecordRoundActive;

    final bool wasListening = activeState.isListening;

    // Stop recording if active - wait for it to complete
    if (wasListening) {
      await _safeStopListening(isNavigatingFromDifferentHole: true);
    }

    // Navigate to new hole
    emit(
      activeState.copyWith(
        currentHoleIndex: newHoleIndex,
        isStartingListening: false,
      ),
    );

    // Restart recording if it was active
    if (wasListening) {
      // Get fresh state to get correct hole description
      final RecordRoundActive newState = state as RecordRoundActive;

      // Capture new hole's accumulated text as baseline
      _textWhenListeningStarted = newState.holeDescriptions[newHoleIndex] ?? '';

      // Start fresh voice session - voice service listener will update isListening
      await _safeStartListening();
    }
  }

  void clearCurrentHoleText() {
    if (state is! RecordRoundActive) return;
    final RecordRoundActive activeState = state as RecordRoundActive;

    _voiceService.clearText();
    _textWhenListeningStarted = '';
    setHoleDescription('', index: activeState.currentHoleIndex);
  }

  void updateCurrentHoleText(String text) {
    if (state is! RecordRoundActive) return;
    final RecordRoundActive activeState = state as RecordRoundActive;

    setHoleDescription(text, index: activeState.currentHoleIndex);
  }

  Future<void> clearAllHoles() async {
    if (state is! RecordRoundActive) return;

    // Stop listening if active
    if (_voiceService.isListening) {
      await _safeStopListening(isNavigatingFromDifferentHole: false);
    }

    // Reset to inactive state
    emit(
      RecordRoundActive(
        selectedCourse: null,
        selectedDateTime: DateTime.now(),
        holeDescriptions: getEmptyHoleDescriptions(),
        numHoles: defaultNumHoles,
      ),
    );
  }

  void emitInactive() {
    emit(const RecordRoundInactive());
  }

  @override
  Future<void> clearOnLogout() async {
    emit(const RecordRoundInactive());
  }
}
