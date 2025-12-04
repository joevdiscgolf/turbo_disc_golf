import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_constants.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

class FBAppInfoDataLoader {
  static Future<String?> getMinimumAppVersion() async {
    return FirebaseFirestore.instance
        .doc('$kAppInfoCollection/$kMinimumVersionDoc')
        .get()
        .then((DocumentSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.metadata.isFromCache) {
            return null;
          }
          if (snapshot.exists && snapshot.data()?['minimumVersion'] != null) {
            return snapshot.data()!['minimumVersion'] as String;
          } else {
            return null;
          }
        })
        .timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            log('[AppInfoDataLoader][getMinimumAppVersion] on timeout');
            return null;
          },
        )
        .catchError((e, trace) {
          FirebaseCrashlytics.instance.recordError(
            e,
            trace,
            reason:
                '[AppInfoDataLoader][getMinimumAppVersion] Firestore timeout',
          );
          return null;
        });
  }
}
