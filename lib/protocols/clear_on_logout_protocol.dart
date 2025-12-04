/// Protocol for any component (cubit, service, manager, etc.) that holds
/// session-specific or user-specific state that must be cleared when the user logs out.
///
/// Implement this interface for:
/// - Cubits that manage UI state tied to the logged-in user
/// - Services that cache user data
/// - Components that hold session-specific information
///
/// The [clearOnLogout] method will be called automatically by [LogoutManager]
/// when the user signs out, ensuring a clean state for the next user session.
abstract class ClearOnLogoutProtocol {
  /// Clears all user-specific or session-specific state.
  ///
  /// This method should:
  /// - Reset all state variables to their initial values
  /// - Clear any cached data
  /// - Cancel any ongoing operations if applicable
  /// - Return a Future that completes when cleanup is done
  Future<void> clearOnLogout();
}
