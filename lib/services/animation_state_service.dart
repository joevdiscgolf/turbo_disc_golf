import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';

/// Service to track which animations have been played to prevent re-animation
/// when Hero widgets recreate components during navigation transitions.
class AnimationStateService implements ClearOnLogoutProtocol {
  AnimationStateService._();

  static final AnimationStateService instance = AnimationStateService._();

  final Set<String> _animatedKeys = {};

  /// Check if an animation has already been played for a specific widget
  /// [roundId] - The unique ID of the round
  /// [widgetType] - A unique identifier for the widget type (e.g., 'spider_chart', 'circular_c1')
  bool hasAnimated(String roundId, String widgetType) {
    final String key = '${roundId}_$widgetType';
    return _animatedKeys.contains(key);
  }

  /// Mark an animation as having been played
  /// [roundId] - The unique ID of the round
  /// [widgetType] - A unique identifier for the widget type
  void markAnimated(String roundId, String widgetType) {
    final String key = '${roundId}_$widgetType';
    _animatedKeys.add(key);
  }

  /// Clear animation state for a specific round
  /// Useful when round data changes or user navigates away from a round
  void clearRound(String roundId) {
    _animatedKeys.removeWhere((key) => key.startsWith('${roundId}_'));
  }

  /// Clear all animation state
  /// Useful for app-wide resets or testing
  void clearAll() {
    _animatedKeys.clear();
  }

  @override
  Future<void> clearOnLogout() async {
    clearAll();
  }
}
