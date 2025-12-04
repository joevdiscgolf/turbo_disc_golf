import 'package:turbo_disc_golf/models/data/auth_data/auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  AuthUser? getCurrentUser();
  bool userHasOnboarded();
  Future<bool> markUserOnboarded();
  Future<bool> signInWithEmailPassword(String email, String password);
  Future<bool> signUpWithEmailPassword(String email, String password);
  Future<bool>? signInWithGoogle();
  Future<void> signOut();
  Future<bool> deleteCurrentUser();

  String get exceptionMessage;
}
