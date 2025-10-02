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
      print('=== Initializing Voice Recording Service ===');

      // Check current microphone permission status
      print('Checking microphone permission...');
      var status = await Permission.microphone.status;
      print('Current microphone permission status: $status');

      // For debug mode - try requesting even if "permanently denied"
      // This can happen if the permission was never actually shown
      if (status == PermissionStatus.permanentlyDenied ||
          status == PermissionStatus.denied ||
          status == PermissionStatus.restricted) {
        print('Permission not granted, requesting...');
        status = await Permission.microphone.request();
        print('New microphone permission status after request: $status');

        // Check if we actually got a proper response
        if (status == PermissionStatus.permanentlyDenied) {
          // Try speech recognition permission as well
          print('Also checking speech recognition permission...');
          final speechStatus = await Permission.speech.request();
          print('Speech recognition permission: $speechStatus');
        }
      }

      if (status != PermissionStatus.granted) {
        _lastError = 'Microphone permission: $status. Try deleting and reinstalling the app.';
        print('ERROR: $_lastError');
        notifyListeners();
        return false;
      }

      // Initialize speech to text
      print('Initializing speech recognition...');
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          _lastError = error.errorMsg;
          _isListening = false;
          print('Speech recognition error: $_lastError');
          notifyListeners();
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
      );

      if (!_isInitialized) {
        _lastError = 'Speech recognition not available';
        print('ERROR: $_lastError');
      } else {
        print('Speech recognition initialized successfully');
      }

      notifyListeners();
      return _isInitialized;
    } catch (e) {
      _lastError = e.toString();
      print('ERROR during initialization: $_lastError');
      notifyListeners();
      return false;
    }
  }

  Future<void> startListening() async {
    print('=== Starting voice recording ===');

    if (!_isInitialized) {
      print('Not initialized, initializing now...');
      await initialize();
    }

    if (_isInitialized && !_isListening) {
      _transcribedText = ''; // Clear previous text
      _lastError = '';
      print('Starting speech recognition...');

      try {
        await _speechToText.listen(
          onResult: (result) {
            _transcribedText = result.recognizedWords;
            print('=== VOICE TRANSCRIPT UPDATE ===');
            print('Raw text: ${result.recognizedWords}');
            print('Is final: ${result.finalResult}');
            print('===============================');
            notifyListeners();
          },
          listenFor: const Duration(minutes: 10), // Extended duration for full round description
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          listenMode: ListenMode.dictation, // Better for longer form speech
        );

        _isListening = true;
        print('Speech recognition started successfully');
        notifyListeners();
      } catch (e) {
        _lastError = 'Failed to start listening: $e';
        print('ERROR: $_lastError');
        notifyListeners();
      }
    } else {
      print('Cannot start listening - Initialized: $_isInitialized, Already listening: $_isListening');
    }
  }

  Future<void> stopListening() async {
    print('=== Stopping voice recording ===');
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      print('Speech recognition stopped');
      print('Final transcript: $_transcribedText');
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