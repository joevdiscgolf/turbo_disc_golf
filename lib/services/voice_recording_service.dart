import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecordingService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  String _transcribedText = '';
  bool _isListening = false;
  bool _isInitialized = false;
  String _lastError = '';

  String get transcribedText => _transcribedText;
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get lastError => _lastError;

  Future<bool> initialize() async {
    try {
      debugPrint('=== Initializing Voice Recording Service ===');

      // Check current microphone permission status
      debugPrint('Checking microphone permission...');
      var status = await Permission.microphone.status;
      debugPrint('Current microphone permission status: $status');

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
      debugPrint('Initializing speech recognition...');
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

  Future<void> startListening() async {
    debugPrint('=== Starting voice recording ===');

    if (!_isInitialized) {
      debugPrint('Not initialized, initializing now...');
      await initialize();
    }

    if (_isInitialized && !_isListening) {
      _transcribedText = ''; // Clear previous text
      _lastError = '';
      debugPrint('Starting speech recognition...');

      try {
        await _speechToText.listen(
          onResult: (result) {
            _transcribedText = result.recognizedWords;
            debugPrint('=== VOICE TRANSCRIPT UPDATE ===');
            debugPrint('Raw text: ${result.recognizedWords}');
            debugPrint('Is final: ${result.finalResult}');
            debugPrint('===============================');
            notifyListeners();
          },
          listenFor: const Duration(minutes: 10),
          pauseFor: const Duration(seconds: 3),
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

  Future<void> stopListening() async {
    debugPrint('=== Stopping voice recording ===');
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      debugPrint('Speech recognition stopped');
      debugPrint('Final transcript: $_transcribedText');
      notifyListeners();
    }
  }

  void appendText(String text) {
    _transcribedText += ' $text';
    notifyListeners();
  }

  void clearText() {
    _transcribedText = '';
    notifyListeners();
  }

  void updateText(String text) {
    _transcribedText = text;
    notifyListeners();
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }
}
