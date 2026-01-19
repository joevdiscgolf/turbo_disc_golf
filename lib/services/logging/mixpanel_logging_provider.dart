import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

import 'package:turbo_disc_golf/protocols/logging_provider.dart';

/// Mixpanel implementation of the [LoggingProvider] protocol.
///
/// Wraps the Mixpanel Flutter SDK and provides graceful error handling
/// to ensure analytics failures never crash the app.
class MixpanelLoggingProvider implements LoggingProvider {
  Mixpanel? _mixpanel;
  bool _isInitialized = false;

  @override
  String get providerName => 'Mixpanel';

  @override
  Future<bool> initialize({
    required String projectToken,
    bool trackAutomaticEvents = true,
  }) async {
    try {
      debugPrint('[MixpanelProvider] initialize() called');
      debugPrint('[MixpanelProvider] Token length: ${projectToken.length}');
      debugPrint(
        '[MixpanelProvider] Token preview: ${projectToken.length >= 8 ? projectToken.substring(0, 8) : projectToken}...',
      );

      // Validate token - empty check
      if (projectToken.isEmpty) {
        debugPrint('[MixpanelProvider] FAILED: Token is empty');
        return false;
      }

      // Check for placeholder tokens
      final bool containsYour = projectToken.contains('your_');
      final bool containsPlaceholder = projectToken.contains('placeholder');
      final bool tooShort = projectToken.length < 20;

      debugPrint(
        '[MixpanelProvider] Validation: containsYour=$containsYour, containsPlaceholder=$containsPlaceholder, tooShort=$tooShort',
      );

      if (containsYour || containsPlaceholder || tooShort) {
        debugPrint(
          '[MixpanelProvider] FAILED: Invalid or placeholder token detected',
        );
        return false;
      }

      debugPrint(
        '[MixpanelProvider] Token validation PASSED, calling Mixpanel.init()...',
      );

      // Initialize Mixpanel SDK
      _mixpanel = await Mixpanel.init(
        projectToken,
        trackAutomaticEvents: trackAutomaticEvents,
      );

      _isInitialized = true;
      debugPrint('[MixpanelProvider] SUCCESS: Mixpanel initialized');
      return true;
    } catch (e, stackTrace) {
      debugPrint('[MixpanelProvider] EXCEPTION during init: $e');
      debugPrint('[MixpanelProvider] Stack trace: $stackTrace');
      _isInitialized = false;
      return false;
    }
  }

  @override
  Future<void> track(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    if (!_isInitialized || _mixpanel == null) {
      debugPrint('[MixpanelProvider] Not initialized - skipping event: $eventName');
      return;
    }

    try {
      _mixpanel!.track(eventName, properties: properties);
    } catch (e) {
      debugPrint('[MixpanelProvider] Failed to track event "$eventName": $e');
    }
  }

  @override
  Future<void> identify(String userId) async {
    if (!_isInitialized || _mixpanel == null) {
      debugPrint('[MixpanelProvider] Not initialized - skipping identify');
      return;
    }

    try {
      _mixpanel!.identify(userId);
      debugPrint('[MixpanelProvider] Identified user: $userId');
    } catch (e) {
      debugPrint('[MixpanelProvider] Failed to identify user: $e');
    }
  }

  @override
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    if (!_isInitialized || _mixpanel == null) {
      debugPrint('[MixpanelProvider] Not initialized - skipping setUserProperties');
      return;
    }

    try {
      // Set each property using Mixpanel People API
      // Mixpanel uses special prefixed keys like $name, $email, etc.
      for (final MapEntry<String, dynamic> entry in properties.entries) {
        final String key = entry.key;
        final dynamic value = entry.value;

        // Use Mixpanel People API to set properties
        _mixpanel!.getPeople().set(key, value);
      }

      debugPrint('[MixpanelProvider] Set user properties: ${properties.keys.join(", ")}');
    } catch (e) {
      debugPrint('[MixpanelProvider] Failed to set user properties: $e');
    }
  }

  @override
  Future<void> reset() async {
    if (!_isInitialized || _mixpanel == null) {
      debugPrint('[MixpanelProvider] Not initialized - skipping reset');
      return;
    }

    try {
      _mixpanel!.reset();
      debugPrint('[MixpanelProvider] Reset user identity');
    } catch (e) {
      debugPrint('[MixpanelProvider] Failed to reset: $e');
    }
  }

  @override
  Future<void> flush() async {
    if (!_isInitialized || _mixpanel == null) {
      debugPrint('[MixpanelProvider] Not initialized - skipping flush');
      return;
    }

    try {
      _mixpanel!.flush();
      debugPrint('[MixpanelProvider] Flushed queued events');
    } catch (e) {
      debugPrint('[MixpanelProvider] Failed to flush: $e');
    }
  }

  @override
  Future<void> registerSuperProperties(Map<String, dynamic> properties) async {
    if (!_isInitialized || _mixpanel == null) {
      debugPrint('[MixpanelProvider] Not initialized - skipping registerSuperProperties');
      return;
    }

    try {
      _mixpanel!.registerSuperProperties(properties);
      debugPrint('[MixpanelProvider] Registered super properties: ${properties.keys.join(", ")}');
    } catch (e) {
      debugPrint('[MixpanelProvider] Failed to register super properties: $e');
    }
  }

  @override
  Future<void> clearSuperProperties() async {
    if (!_isInitialized || _mixpanel == null) {
      debugPrint('[MixpanelProvider] Not initialized - skipping clearSuperProperties');
      return;
    }

    try {
      _mixpanel!.clearSuperProperties();
      debugPrint('[MixpanelProvider] Cleared super properties');
    } catch (e) {
      debugPrint('[MixpanelProvider] Failed to clear super properties: $e');
    }
  }
}
