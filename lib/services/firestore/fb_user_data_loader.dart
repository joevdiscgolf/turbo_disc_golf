import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/user_data/user_data.dart';
import 'package:turbo_disc_golf/repositories/firebase_auth_repository.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_constants.dart';
import 'package:turbo_disc_golf/utils/constants/timing_constants.dart';
import 'package:turbo_disc_golf/utils/firebase/firebase_utils.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

abstract class FBUserDataLoader {
  FBUserDataLoader._internal();

  Future<TurboUser?> getCurrentUser({
    Duration timeoutDuration = shortTimeout,
  }) async {
    final String? uid = locator
        .get<FirebaseAuthRepository>()
        .getCurrentUserId();
    if (uid == null) {
      return null;
    }

    return firestoreFetch(
      '$kUsersCollection/$uid',
      timeoutDuration: timeoutDuration,
    ).then((snapshot) {
      if (snapshot == null ||
          !snapshot.exists ||
          !isValidUser(snapshot.data() as Map<String, dynamic>)) {
        return null;
      }
      final Map<String, dynamic> data = snapshot.data()!;
      return TurboUser.fromJson(data);
    });
  }

  Future<Map<String, dynamic>?> getUserJson() async {
    final String? uid = locator
        .get<FirebaseAuthRepository>()
        .getCurrentUserId();
    if (uid == null) {
      return null;
    }

    return firestore
        .doc('$kUsersCollection/$uid')
        .get()
        .then((snapshot) {
          if (snapshot.exists) {
            return snapshot.data() as Map<String, dynamic>;
          } else {
            return null;
          }
        })
        .catchError((e, trace) {
          FirebaseCrashlytics.instance.recordError(
            e,
            trace,
            reason: '[FBUserDataLoader][getUserJson] Firestore Exception',
          );
          return null;
        });
  }

  Future<List<TurboUser>> getUsersByUsername(String username) async {
    final FirebaseAuthRepository authService = locator
        .get<FirebaseAuthRepository>();
    final String? currentUid = authService.getCurrentUserId();
    if (currentUid == null) {
      return [];
    }
    return firestore
        .collection(kUsersCollection)
        .where('keywords', arrayContains: username)
        .get()
        .then((QuerySnapshot querySnapshot) {
          final List<TurboUser?> users = querySnapshot.docs.map((doc) {
            if (doc.exists) {
              return TurboUser.fromJson(doc.data() as Map<String, dynamic>);
            } else {
              return null;
            }
          }).toList();

          List<TurboUser> existingUsers = [];

          for (var user in users) {
            if (user != null && user.uid != currentUid) {
              existingUsers.add(user);
            }
          }

          return existingUsers;
        })
        .catchError((e, trace) {
          log(e);
          FirebaseCrashlytics.instance.recordError(
            e,
            trace,
            reason:
                '[FBUserDataLoader][getUsersByUsername] firestore read exception',
          );
          return <TurboUser>[];
        });
  }

  bool isValidUser(Map<String, dynamic>? data) {
    return data?['username'] != null &&
        data?['displayName'] != null &&
        data?['uid'] != null;
  }
}
