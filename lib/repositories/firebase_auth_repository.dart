import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:turbo_disc_golf/models/data/auth_data/auth_user.dart';
import 'package:turbo_disc_golf/repositories/auth_repository.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_constants.dart';

final FirebaseAuth auth = FirebaseAuth.instance;

class FirebaseAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() {
    return _auth.userChanges().map((User? user) {
      if (user == null) return null;
      return AuthUser.fromFirebaseuser(user);
    });
  }

  @override
  AuthUser? getCurrentUser() {
    final User? currentFirebaseUser = _auth.currentUser;
    if (currentFirebaseUser == null) return null;
    return AuthUser.fromFirebaseuser(currentFirebaseUser);
  }

  @override
  Future<bool> signUpWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('user credential user: ${userCredential.user}');
      if (userCredential.user == null) {
        return false;
      }

      debugPrint('attempting to create a user doc');
      return await FirebaseFirestore.instance
          .collection(kUsersCollection)
          .doc(userCredential.user?.uid)
          .set(<String, dynamic>{
            'uid': userCredential.user?.uid,
            'createdAt': DateTime.now().toUtc().toIso8601String(),
          })
          .then((_) => true);
    } on FirebaseAuthException catch (e) {
      debugPrint('firebase exception: $e');
      if (e.code == 'weak-password') {
        exception = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        exception = 'Email already in use';
      }
      return false;
    }
  }

  @override
  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user == null) {
        return false;
      }
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        exception = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        exception = 'Wrong password provided for that user.';
      }
      log(e.toString());
      return false;
    }
  }

  @override
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // User cancelled the sign-in
      if (googleUser == null) {
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return false;
      }

      // Check if this is a new user and create Firestore document if needed
      final bool isNewUser =
          userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        await FirebaseFirestore.instance
            .collection(kUsersCollection)
            .doc(userCredential.user!.uid)
            .set(<String, dynamic>{
              'uid': userCredential.user!.uid,
              'createdAt': DateTime.now().toUtc().toIso8601String(),
            });
      }

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign-in Firebase exception: $e');
      exception = e.message ?? 'Google sign-in failed';
      return false;
    } catch (e, trace) {
      log('Google sign-in error: $e');
      log(trace.toString());
      FirebaseCrashlytics.instance.recordError(
        e,
        trace,
        reason: '[FirebaseAuthRepository][signInWithGoogle] exception',
      );
      exception = 'Google sign-in failed. Please try again.';
      return false;
    }
  }

  @override
  Future<bool> signInWithApple() async {
    try {
      // Generate a random nonce for security
      final String rawNonce = _generateNonce();
      final String nonce = _sha256ofString(rawNonce);

      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: nonce,
          );

      final OAuthCredential oauthCredential = OAuthProvider('apple.com')
          .credential(
            idToken: appleCredential.identityToken,
            rawNonce: rawNonce,
          );

      final UserCredential userCredential =
          await _auth.signInWithCredential(oauthCredential);

      if (userCredential.user == null) {
        return false;
      }

      // Check if this is a new user and create Firestore document if needed
      final bool isNewUser =
          userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        await FirebaseFirestore.instance
            .collection(kUsersCollection)
            .doc(userCredential.user!.uid)
            .set(<String, dynamic>{
              'uid': userCredential.user!.uid,
              'createdAt': DateTime.now().toUtc().toIso8601String(),
            });
      }

      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      // User cancelled the sign-in
      if (e.code == AuthorizationErrorCode.canceled) {
        return false;
      }
      debugPrint('Apple sign-in authorization exception: $e');
      exception = 'Apple sign-in failed';
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('Apple sign-in Firebase exception: $e');
      exception = e.message ?? 'Apple sign-in failed';
      return false;
    } catch (e, trace) {
      log('Apple sign-in error: $e');
      log(trace.toString());
      FirebaseCrashlytics.instance.recordError(
        e,
        trace,
        reason: '[FirebaseAuthRepository][signInWithApple] exception',
      );
      exception = 'Apple sign-in failed. Please try again.';
      return false;
    }
  }

  /// Generates a random nonce string for Apple Sign-In security
  String _generateNonce([int length = 32]) {
    const String charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final math.Random random = math.Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the SHA256 hash of the input string
  String _sha256ofString(String input) {
    final List<int> bytes = utf8.encode(input);
    final Digest digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e, trace) {
      log(e.toString());
      log(trace.toString());
      FirebaseCrashlytics.instance.recordError(
        e,
        trace,
        reason: '[FirebaseAuthSErvice][logOut] exception',
      );
    }
  }

  @override
  Future<bool> deleteCurrentUser() async {
    if (_auth.currentUser == null) {
      return false;
    }
    return _auth.currentUser!.delete().then((_) => true).catchError((e, trace) {
      return false;
    });
  }

  @override
  String get exceptionMessage => exception;

  final FirebaseAuth _auth = auth;

  String exception = '';

  Future<User?> getUser() async {
    try {
      return _auth.currentUser;
    } catch (e, trace) {
      log(e.toString());
      log(trace.toString());
      FirebaseCrashlytics.instance.recordError(
        e,
        trace,
        reason: '[FirebaseAuthService][getUser] exception',
      );
      return null;
    }
  }

  @override
  bool userHasOnboarded() {
    return getCurrentUser()?.displayName?.contains('has_onboarded') == true;
  }

  @override
  Future<bool> markUserOnboarded() async {
    try {
      if (_auth.currentUser == null) {
        return false;
      }

      // Get existing display name or empty string
      final String currentDisplayName = _auth.currentUser!.displayName ?? '';

      // Append onboarding marker
      final String newDisplayName = '$currentDisplayName//has_onboarded';

      // Update the display name
      await _auth.currentUser!.updateProfile(displayName: newDisplayName);

      return true;
    } catch (e, trace) {
      log(e.toString());
      log(trace.toString());
      FirebaseCrashlytics.instance.recordError(
        e,
        trace,
        reason: '[FirebaseAuthRepository][markUserOnboarded] exception',
      );
      return false;
    }
  }

  Stream<User?> get user {
    return _auth.userChanges();
  }

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  Future<String?> getAuthToken() async {
    try {
      return _auth.currentUser?.getIdToken();
    } catch (e, trace) {
      log(e.toString());
      log(trace.toString());
      FirebaseCrashlytics.instance.recordError(
        e,
        trace,
        reason: '[FirebaseAuthService][getAuthToken] exception',
      );
      return null;
    }
  }

  Future<bool> sendPasswordReset(String email) {
    return auth
        .sendPasswordResetEmail(email: email)
        .then((response) => true)
        .catchError((e, trace) {
          log(e.toString());
          FirebaseCrashlytics.instance.recordError(
            e,
            trace,
            reason:
                '[FirebaseAuthService][sendPasswordReset] sendPasswordResetEmail() exception',
          );
          return false;
        });
  }

  bool userDocIsValid(Map<String, dynamic> doc) {
    return doc['username'] != null && doc['displayName'] != null;
  }
}
