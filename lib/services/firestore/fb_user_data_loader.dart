import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:turbo_disc_golf/models/data/user_data/user_data.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_constants.dart';
import 'package:turbo_disc_golf/utils/constants/timing_constants.dart';
import 'package:turbo_disc_golf/utils/firebase/firebase_utils.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

abstract class FBUserDataLoader {
  static Future<TurboUser?> getCurrentUser(
    String uid, {
    Duration timeoutDuration = shortTimeout,
  }) async {
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

  static Future<Map<String, dynamic>?> getUserJson(String uid) async {
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

  static Future<List<TurboUser>> getUsersByUsername(
    String uid,
    String username,
  ) async {
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
            if (user != null && user.uid != uid) {
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

  static bool isValidUser(Map<String, dynamic>? data) {
    return data?['username'] != null &&
        data?['displayName'] != null &&
        data?['uid'] != null;
  }

  /// Update the user's PDGA division in Firestore.
  static Future<bool> updateUserDivision(String uid, String division) async {
    try {
      await firestore.doc('$kUsersCollection/$uid').update({
        'pdgaMetadata.division': division,
      });
      return true;
    } catch (e, trace) {
      log('[FBUserDataLoader][updateUserDivision] Error: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        trace,
        reason: '[FBUserDataLoader][updateUserDivision] Firestore Exception',
      );
      return false;
    }
  }

  /// Update the user's PDGA rating in Firestore.
  static Future<bool> updateUserRating(String uid, int rating) async {
    try {
      await firestore.doc('$kUsersCollection/$uid').update({
        'pdgaMetadata.pdgaRating': rating,
      });
      return true;
    } catch (e, trace) {
      log('[FBUserDataLoader][updateUserRating] Error: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        trace,
        reason: '[FBUserDataLoader][updateUserRating] Firestore Exception',
      );
      return false;
    }
  }
}
