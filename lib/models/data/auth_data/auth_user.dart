import 'package:firebase_auth/firebase_auth.dart' as firebase;

class AuthUser {
  const AuthUser({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.email,
    required this.phoneNumber,
  });

  final String uid;
  final String? username;
  final String? displayName;
  final String? email;
  final String? phoneNumber;

  factory AuthUser.fromFirebaseuser(firebase.User firebaseUser) {
    return AuthUser(
      uid: firebaseUser.uid,
      username: null,
      displayName: firebaseUser.displayName,
      email: firebaseUser.email,
      phoneNumber: firebaseUser.phoneNumber,
    );
  }
}
