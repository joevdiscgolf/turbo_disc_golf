import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:turbo_disc_golf/services/voice/base_voice_recording_service.dart';

class SpeechToTextService extends BaseVoiceRecordingService {
  final SpeechToText _speechToText = SpeechToText();
  String _transcribedText = '';
  bool _isListening = false;
  bool _isInitialized = false;
  String _lastError = '';

  // Simple getter - just returns raw speech recognition output
  @override
  String get transcribedText => _transcribedText;
  @override
  bool get isListening => _isListening;
  @override
  bool get isInitialized => _isInitialized;
  @override
  String get lastError => _lastError;

  @override
  Future<bool> initialize() async {
    try {
      // debugPrint('=== Initializing Voice Recording Service ===');

      // Check current microphone permission status
      // debugPrint('Checking microphone permission...');
      var status = await Permission.microphone.status;
      // debugPrint('Current microphone permission status: $status');

      // For debug mode - try requesting even if "permanently denied"
      // This can happen if the permission was never actually shown
      if (status == PermissionStatus.permanentlyDenied ||
          status == PermissionStatus.denied ||
          status == PermissionStatus.restricted) {
        debugPrint('Permission not granted, requesting...');
        status = await Permission.microphone.request();
        debugPrint('New microphone permission status after request: $status');

        // Check if we actually got a proper response
        if (status == PermissionStatus.permanentlyDenied) {
          // Try speech recognition permission as well
          debugPrint('Also checking speech recognition permission...');
          final speechStatus = await Permission.speech.request();
          debugPrint('Speech recognition permission: $speechStatus');
        }
      }

      if (status != PermissionStatus.granted) {
        _lastError =
            'Microphone permission: $status. Try deleting and reinstalling the app.';
        debugPrint('ERROR: $_lastError');
        notifyListeners();
        return false;
      }

      // Initialize speech to text
      // debugPrint('Initializing speech recognition...');
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          _lastError = error.errorMsg;
          _isListening = false;
          debugPrint('Speech recognition error: $_lastError');
          notifyListeners();
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
      );

      if (!_isInitialized) {
        _lastError = 'Speech recognition not available';
        debugPrint('ERROR: $_lastError');
      } else {
        debugPrint('Speech recognition initialized successfully');
      }

      notifyListeners();
      return _isInitialized;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('ERROR during initialization: $_lastError');
      notifyListeners();
      return false;
    }
  }

  /// Warms up the speech recognition engine by doing a brief phantom listen.
  /// This should be called on app startup to reduce latency on first real use.
  @override
  Future<void> warmUp() async {
    debugPrint('=== Warming up speech recognition ===');

    // Initialize if not already done
    if (!_isInitialized) {
      final bool success = await initialize();
      if (!success) {
        debugPrint('Warm-up failed: Could not initialize');
        return;
      }
    }

    // Start a brief phantom listen to warm up the engine
    try {
      await _speechToText.listen(
        onResult: (result) {
          // Do nothing with the result - this is just a warm-up
        },
        listenFor: const Duration(milliseconds: 100), // Very brief
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
        ),
      );

      // Immediately stop
      await _speechToText.stop();

      debugPrint('Speech recognition warmed up successfully');
    } catch (e) {
      debugPrint('Warm-up listen failed (non-critical): $e');
      // Don't fail - this is just an optimization
    }
  }

  @override
  Future<void> startListening() async {
    debugPrint('=== Starting voice recording ===');

    if (!_isInitialized) {
      await initialize();
    }

    if (_isInitialized && !_isListening) {
      // Clear session text for fresh recording
      _transcribedText = '';
      _lastError = '';
      debugPrint('Starting speech recognition...');

      try {
        await _speechToText.listen(
          onResult: (result) {
            _transcribedText = result.recognizedWords;
            // debugPrint('=== VOICE TRANSCRIPT UPDATE ===');
            // debugPrint('Raw text: ${result.recognizedWords}');
            // debugPrint('Is final: ${result.finalResult}');
            // debugPrint('===============================');
            notifyListeners();
          },
          listenFor: const Duration(minutes: 10),
          pauseFor: const Duration(minutes: 10),
          listenOptions: SpeechListenOptions(
            listenMode: ListenMode.dictation,
            partialResults: true,
          ),
        );

        _isListening = true;
        debugPrint('Speech recognition started successfully');
        notifyListeners();
      } catch (e) {
        _lastError = 'Failed to start listening: $e';
        debugPrint('ERROR: $_lastError');
        notifyListeners();
      }
    } else {
      debugPrint(
        'Cannot start listening - Initialized: $_isInitialized, Already listening: $_isListening',
      );
    }
  }

  @override
  Future<void> stopListening() async {
    debugPrint('=== Stopping voice recording ===');
    if (_isListening) {
      _isListening = false; // Set flag immediately
      notifyListeners(); // Notify immediately so UI updates

      await _speechToText.stop(); // Then await actual stop

      debugPrint('Speech recognition stopped');
      debugPrint('Final transcript: $_transcribedText');
    }
  }

  @override
  Future<void> clearOnLogout() async {
    clearText();
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }
}
