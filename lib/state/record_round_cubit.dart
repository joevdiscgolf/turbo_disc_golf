import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/services/courses/courses_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';
import 'package:turbo_disc_golf/services/voice/base_voice_recording_service.dart';
import 'package:turbo_disc_golf/state/record_round_state.dart';

class RecordRoundCubit extends Cubit<RecordRoundState>
    implements ClearOnLogoutProtocol {
  RecordRoundCubit() : super(const RecordRoundInactive());

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
        holeDescriptions: _getEmptyHoleDescriptions(
          RecordRoundActive.defaultNumHoles,
        ),
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
    final RecordRoundActive activeState = state as RecordRoundActive;

    // Get the layout (by ID or default)
    final CourseLayout layout = layoutId != null
        ? selectedCourse.getLayoutById(layoutId) ?? selectedCourse.defaultLayout
        : selectedCourse.defaultLayout;
    final int numHoles = layout.holes.length;

    // Update hole descriptions map if number of holes changed
    Map<int, String> updatedDescriptions = activeState.holeDescriptions;
    if (numHoles != activeState.numHoles) {
      updatedDescriptions = {};
      for (int i = 0; i < numHoles; i++) {
        // Preserve existing descriptions where possible
        updatedDescriptions[i] = activeState.holeDescriptions[i] ?? '';
      }
    }

    emit(activeState.copyWith(
      selectedCourse: selectedCourse,
      selectedLayout: layout,
      holeDescriptions: updatedDescriptions,
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

  Map<int, String> _getEmptyHoleDescriptions(int numHoles) {
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

    // Check for voice service errors and show toast
    final String error = _voiceService.lastError;
    if (error.isNotEmpty && activeState.isStartingListening) {
      // Stop loading state and show error
      emit(activeState.copyWith(isStartingListening: false));
      _showVoicePermissionError(error);
      return;
    }

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

  void _showVoicePermissionError(String error) {
    final ToastService toastService = locator.get<ToastService>();

    final String lowerError = error.toLowerCase();

    // Check for permission-specific errors
    if (lowerError.contains('permission') ||
        lowerError.contains('not authorized') ||
        lowerError.contains('denied')) {
      toastService.showError(
        'Microphone access required. Please enable it in Settings.',
      );
    } else if (lowerError.contains('not available')) {
      toastService.showError(
        'Speech recognition is not available on this device.',
      );
    } else {
      toastService.showError('Voice input failed: $error');
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

      // Check if listening actually started, show error if not
      // Small delay to allow state to settle
      await Future.delayed(const Duration(milliseconds: 100));

      if (!_voiceService.isListening && _voiceService.lastError.isNotEmpty) {
        if (state is RecordRoundActive) {
          emit((state as RecordRoundActive).copyWith(isStartingListening: false));
        }
        _showVoicePermissionError(_voiceService.lastError);
      }
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
        holeDescriptions: _getEmptyHoleDescriptions(
          RecordRoundActive.defaultNumHoles,
        ),
      ),
    );
  }

  void emitInactive() {
    emit(const RecordRoundInactive());
  }

  /// Set imported scores from a parsed scorecard image.
  /// Converts list of hole metadata to a map of holeIndex to score.
  void setImportedScores(Map<int, int> scores) {
    if (state is! RecordRoundActive) return;
    emit((state as RecordRoundActive).copyWith(importedScores: scores));
  }

  /// Update a single hole's score (for manual correction).
  void updateHoleScore(int holeIndex, int? score) {
    if (state is! RecordRoundActive) return;
    final RecordRoundActive activeState = state as RecordRoundActive;

    // Create a new map with the updated score
    final Map<int, int> updatedScores = Map<int, int>.from(
      activeState.importedScores ?? {},
    );

    if (score != null) {
      updatedScores[holeIndex] = score;
    } else {
      updatedScores.remove(holeIndex);
    }

    emit(activeState.copyWith(importedScores: updatedScores));
  }

  /// Increment the score for a hole by 1.
  void incrementHoleScore(int holeIndex) {
    if (state is! RecordRoundActive) return;
    final RecordRoundActive activeState = state as RecordRoundActive;

    final int currentScore = activeState.importedScores?[holeIndex] ?? 0;
    updateHoleScore(holeIndex, currentScore + 1);
  }

  /// Decrement the score for a hole by 1 (minimum score is 1).
  void decrementHoleScore(int holeIndex) {
    if (state is! RecordRoundActive) return;
    final RecordRoundActive activeState = state as RecordRoundActive;

    final int? currentScore = activeState.importedScores?[holeIndex];
    if (currentScore != null && currentScore > 1) {
      updateHoleScore(holeIndex, currentScore - 1);
    }
  }

  /// Set full imported hole metadata from a parsed scorecard image.
  /// Stores both scores and full metadata (par, distance, etc.)
  void setImportedHoleMetadata(List<HoleMetadata> metadata) {
    if (state is! RecordRoundActive) return;

    // Convert to Map<int, int> for scores (existing behavior)
    final Map<int, int> scores = {};
    final Map<int, HoleMetadata> holeMetadata = {};

    for (final HoleMetadata hole in metadata) {
      final int index = hole.holeNumber - 1; // 0-based
      scores[index] = hole.score;
      holeMetadata[index] = hole;
    }

    emit((state as RecordRoundActive).copyWith(
      importedScores: scores,
      importedHoleMetadata: holeMetadata,
    ));
  }

  /// Clear imported scores
  void clearImportedScores() {
    if (state is! RecordRoundActive) return;
    emit((state as RecordRoundActive).copyWith(clearImportedScores: true));
  }

  @override
  Future<void> clearOnLogout() async {
    emit(const RecordRoundInactive());
  }
}
