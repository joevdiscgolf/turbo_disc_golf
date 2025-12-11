import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'base_voice_recording_service.dart';

class IosVoiceService extends BaseVoiceRecordingService {
  static const platform = MethodChannel(
    'com.example.turbo_disc_golf/speech_recognition',
  );

  late bool _isListening;
  late bool _isInitialized;
  late String _transcribedText;
  late String _lastError;

  // Timing properties
  int? _lastWarmupMs;
  int? _lastInitializeMs;
  int? _lastStartMs;
  int? _lastStopMs;
  int? _lastClearTextMs;

  // Getters for timing
  int? get lastWarmupMs => _lastWarmupMs;
  int? get lastInitializeMs => _lastInitializeMs;
  int? get lastStartMs => _lastStartMs;
  int? get lastStopMs => _lastStopMs;
  int? get lastClearTextMs => _lastClearTextMs;

  IosVoiceService() {
    _isListening = false;
    _isInitialized = false;
    _transcribedText = '';
    _lastError = '';
    _setupMethodChannel();
  }

  @override
  bool get isListening => _isListening;

  @override
  bool get isInitialized => _isInitialized;

  @override
  String get transcribedText => _transcribedText;

  @override
  String get lastError => _lastError;

  void _setupMethodChannel() {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onSpeechResult':
          _transcribedText = call.arguments ?? '';
          _lastError = '';
          notifyListeners();
          break;
        case 'onPartialResult':
          _transcribedText = call.arguments ?? '';
          notifyListeners();
          break;
        case 'onError':
          _lastError = call.arguments ?? 'Unknown error';
          _isListening = false;
          notifyListeners();
          break;
        case 'onListeningStateChanged':
          _isListening = call.arguments ?? false;
          notifyListeners();
          break;
      }
    });
  }

  @override
  Future<bool> initialize() async {
    debugPrint('\n🔧 === INITIALIZE ===');
    final stopwatch = Stopwatch()..start();

    try {
      final result = await platform.invokeMethod<bool>('initialize');
      _isInitialized = result ?? false;
      _lastError = '';
      debugPrint('✅ Initialization successful');
    } on PlatformException catch (e) {
      _lastError = 'Failed to initialize: ${e.message}';
      debugPrint('❌ Initialization failed: ${e.message}');
    }

    stopwatch.stop();
    _lastInitializeMs = stopwatch.elapsedMilliseconds;
    debugPrint('⏱️  Total: ${stopwatch.elapsedMilliseconds}ms');
    debugPrint('✅ === COMPLETE ===\n');

    notifyListeners();
    return true;
  }

  @override
  Future<void> warmUp() async {
    debugPrint('\n🔧 === WARMUP ===');
    final stopwatch = Stopwatch()..start();

    try {
      await platform.invokeMethod<void>('warmUp');
      _lastError = '';
      debugPrint('✅ Warmup successful');
    } on PlatformException catch (e) {
      _lastError = 'Failed to warm up: ${e.message}';
      debugPrint('❌ Warmup failed: ${e.message}');
    }

    stopwatch.stop();
    _lastWarmupMs = stopwatch.elapsedMilliseconds;
    debugPrint('⏱️  Total: ${stopwatch.elapsedMilliseconds}ms');
    debugPrint('✅ === COMPLETE ===\n');

    notifyListeners();
  }

  @override
  Future<void> startListening() async {
    debugPrint('\n🎙️  === START LISTENING ===');

    // Guard: Don't start if already listening
    if (_isListening) {
      debugPrint('⚠️  Already listening, ignoring start request');
      return;
    }

    final stopwatch = Stopwatch()..start();

    try {
      await platform.invokeMethod<void>('startListening');

      // Clear session text for fresh recording
      _transcribedText = '';
      _lastError = '';
      _isListening = true; // Set immediately for UI responsiveness

      debugPrint('✅ Listening started (session text cleared)');

      stopwatch.stop();
      _lastStartMs = stopwatch.elapsedMilliseconds;
      debugPrint('⏱️  Total: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('✅ === COMPLETE ===\n');

      notifyListeners();
    } on PlatformException catch (e) {
      _lastError = 'Failed to start listening: ${e.message}';
      _isListening = false;
      debugPrint('❌ Failed to start listening: ${e.message}');
      notifyListeners();
    } catch (e) {
      _lastError = 'Unexpected error starting listening: $e';
      _isListening = false;
      debugPrint('❌ Unexpected error: $e');
      notifyListeners();
    }
  }

  @override
  Future<void> stopListening() async {
    debugPrint('\n⏹️  === STOP LISTENING ===');
    final stopwatch = Stopwatch()..start();

    try {
      await platform.invokeMethod<void>('stopListening');
      _isListening = false;
      _transcribedText = '';
      debugPrint('✅ Listening stopped');
    } on PlatformException catch (e) {
      _lastError = 'Failed to stop listening: ${e.message}';
      debugPrint('❌ Failed to stop listening: ${e.message}');
    }

    stopwatch.stop();
    _lastStopMs = stopwatch.elapsedMilliseconds;
    debugPrint('⏱️  Total: ${stopwatch.elapsedMilliseconds}ms');
    debugPrint('✅ === COMPLETE ===\n');

    notifyListeners();
  }

  @override
  Future<void> clearText() async {
    debugPrint('\n🗑️  === CLEAR TEXT ===');
    final stopwatch = Stopwatch()..start();

    try {
      _transcribedText = '';
      _lastError = '';
      debugPrint('✅ Text cleared');
    } catch (e) {
      _lastError = 'Failed to clear text: $e';
      debugPrint('❌ Failed to clear text: $e');
    }

    stopwatch.stop();
    _lastClearTextMs = stopwatch.elapsedMilliseconds;
    debugPrint('⏱️  Total: ${stopwatch.elapsedMilliseconds}ms');
    debugPrint('✅ === COMPLETE ===\n');

    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('\n💀 === DISPOSE ===');
    debugPrint('Disposing voice service');
    super.dispose();
  }
}
