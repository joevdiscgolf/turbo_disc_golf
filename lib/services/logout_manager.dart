import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';

/// Manages centralized logout for all components implementing ClearOnLogoutProtocol.
///
/// All components (cubits, services, etc.) that hold user-specific or session-specific
/// state should be registered with this manager during app initialization. When logout
/// occurs, this manager iterates through all registered components and calls their
/// clearOnLogout() method.
///
/// Example usage:
/// ```dart
/// final logoutManager = LogoutManager(components: [
///   roundHistoryCubit,
///   roundParser,
///   bagService,
///   // ... other components
/// ]);
///
/// await logoutManager.clearAll();
/// ```
class LogoutManager {
  final List<ClearOnLogoutProtocol> _components;

  LogoutManager({required List<ClearOnLogoutProtocol> components})
      : _components = components;

  /// Calls clearOnLogout() on all registered components.
  ///
  /// This should be called before Firebase auth sign out to ensure
  /// all user-specific state is cleared properly.
  ///
  /// Returns a Future that completes when all components have been cleared.
  Future<void> clearAll() async {
    for (final component in _components) {
      await component.clearOnLogout();
    }
  }

  /// Returns the list of registered components (for debugging/testing)
  List<ClearOnLogoutProtocol> get registeredComponents =>
      List.unmodifiable(_components);

  /// Returns the number of registered components
  int get componentCount => _components.length;
}
