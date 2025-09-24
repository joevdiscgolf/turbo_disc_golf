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
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        _lastError = 'Microphone permission denied';
        notifyListeners();
        return false;
      }

      // Initialize speech to text
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          _lastError = error.errorMsg;
          _isListening = false;
          notifyListeners();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
      );

      if (!_isInitialized) {
        _lastError = 'Speech recognition not available';
      }

      notifyListeners();
      return _isInitialized;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isInitialized && !_isListening) {
      _transcribedText = ''; // Clear previous text
      _lastError = '';

      await _speechToText.listen(
        onResult: (result) {
          _transcribedText = result.recognizedWords;
          notifyListeners();
        },
        listenFor: const Duration(minutes: 10), // Extended duration for full round description
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        listenMode: ListenMode.dictation, // Better for longer form speech
      );

      _isListening = true;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
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