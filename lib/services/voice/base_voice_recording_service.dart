import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';

/// Abstract base class for voice recording services
/// This allows swapping between different speech recognition implementations
abstract class BaseVoiceRecordingService extends ChangeNotifier
    implements ClearOnLogoutProtocol {
  String _transcribedText = '';

  String get transcribedText => _transcribedText;
  bool get isListening;
  bool get isInitialized;
  String get lastError;

  Future<bool> initialize();
  Future<void> warmUp();
  Future<void> startListening();
  Future<void> stopListening();

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
  Future<void> clearOnLogout() async {
    clearText();
  }
}
