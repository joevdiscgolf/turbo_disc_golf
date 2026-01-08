import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/auth_data/auth_user.dart';
import 'package:turbo_disc_golf/models/data/user_data/pdga_metadata.dart';
import 'package:turbo_disc_golf/models/data/user_data/user_data.dart';
import 'package:turbo_disc_golf/models/data/user_data/username_doc.dart';
import 'package:turbo_disc_golf/repositories/auth_database_repository.dart';
import 'package:turbo_disc_golf/services/shared_preferences_service.dart';
import 'package:turbo_disc_golf/utils/string_helpers.dart';

class FirebaseAuthDatabaseRepository implements AuthDatabaseRepository {
  @override
  Future<TurboUser?> setUpNewUserInDatabase(
    AuthUser authUser,
    String username,
    String displayName, {
    PDGAMetadata? pdgaMetadata,
  }) async {
    final DocumentReference<Map<String, dynamic>> userDoc =
        FirebaseFirestore.instance.collection('Users').doc(authUser.uid);
    final WriteBatch batch = FirebaseFirestore.instance.batch();
    final DocumentReference<Map<String, dynamic>> usernameDoc =
        FirebaseFirestore.instance.collection('Usernames').doc(username);

    final TurboUser newUser = TurboUser(
      keywords: getPrefixes(username),
      username: username,
      displayName: displayName,
      uid: authUser.uid,
      pdgaMetadata: pdgaMetadata,
    );

    batch.set(userDoc, newUser.toJson());
    batch.set(
      usernameDoc,
      UsernameDocument(username: username, uid: authUser.uid).toJson(),
    );
    await batch.commit().catchError((e, trace) {
      log(e.toString());
      FirebaseCrashlytics.instance.recordError(
        e,
        trace,
        reason:
            '[FirebaseAuthService][setUpNewUser] firestore batch commit exception',
      );
      return null;
    });

    locator.get<SharedPreferencesService>().markUserIsSetUp(true);

    return newUser;
  }

  @override
  Future<bool> saveUserInfoInDatabase(
    AuthUser authUser,
    String name,
    String? bio,
  ) async {
    Map<String, String> userData = <String, String>{'name': name};
    if (bio != null && bio.trim().isNotEmpty) {
      userData['bio'] = bio;
    }

    return FirebaseFirestore.instance
        .collection('Users')
        .doc(authUser.uid)
        .update(userData)
        .then((_) => true)
        .catchError((e, trace) {
          log(e);
          FirebaseCrashlytics.instance.recordError(
            e,
            trace,
            reason: '[FirebaseAuthService][saveUserInfo] Firestore Exception',
          );
          return false;
        });
  }

  @override
  Future<bool> usernameIsAvailable(String username) async {
    try {
      final DocumentSnapshot<dynamic> usernameDoc = await FirebaseFirestore
          .instance
          .collection('Usernames')
          .doc(username)
          .get();
      return !usernameDoc.exists;
    } catch (e, trace) {
      log(e.toString());
      log(trace.toString());
      FirebaseCrashlytics.instance.recordError(
        e,
        trace,
        reason: '[FirebaseAuthSErvice][usernameIsAvailable] exception',
      );
      return false;
    }
  }

  @override
  Future<bool> userIsSetUp(String uid) async {
    return false;
    // try {
    //   final Map<String, dynamic>? userJson = await FBUserDataLoader.getUserJson(
    //     uid,
    //   );
    //   if (userJson == null) {
    //     return false;
    //   }

    //   // Try to parse into TurboUser - if this throws, catch will return false
    //   TurboUser.fromJson(userJson);
    //   return true;
    // } catch (e, trace) {
    //   log(e.toString());
    //   log(trace.toString());
    //   FirebaseCrashlytics.instance.recordError(
    //     e,
    //     trace,
    //     reason: '[FirebaseAuthDatabaseRepository][userIsSetUp] exception',
    //   );
    //   return false;
    // }
  }
}
