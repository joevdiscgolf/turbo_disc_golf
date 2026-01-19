import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_constants.dart';

class AppVersionInfo {
  final String minimumVersion;
  final String? appStoreUrl;
  final String? playStoreUrl;
  final String? upgradeMessage;

  AppVersionInfo({
    required this.minimumVersion,
    this.appStoreUrl,
    this.playStoreUrl,
    this.upgradeMessage,
  });

  factory AppVersionInfo.fromMap(Map<String, dynamic> data) {
    return AppVersionInfo(
      minimumVersion: data['minimumVersion'] as String,
      appStoreUrl: data['appStoreUrl'] as String?,
      playStoreUrl: data['playStoreUrl'] as String?,
      upgradeMessage: data['upgradeMessage'] as String?,
    );
  }
}

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

  static Future<AppVersionInfo?> getAppVersionInfo() async {
    return FirebaseFirestore.instance
        .doc('$kAppInfoCollection/$kMinimumVersionDoc')
        .get()
        .then((DocumentSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.metadata.isFromCache) {
            log(
              '[AppInfoDataLoader][getAppVersionInfo] data is from cache, returning null',
            );
            return null;
          }
          if (snapshot.exists && snapshot.data() != null) {
            try {
              return AppVersionInfo.fromMap(snapshot.data()!);
            } catch (e) {
              log(
                '[AppInfoDataLoader][getAppVersionInfo] error parsing data: $e',
              );
              return null;
            }
          } else {
            return null;
          }
        })
        .timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            log('[AppInfoDataLoader][getAppVersionInfo] on timeout');
            return null;
          },
        )
        .catchError((e, trace) {
          FirebaseCrashlytics.instance.recordError(
            e,
            trace,
            reason: '[AppInfoDataLoader][getAppVersionInfo] Firestore timeout',
          );
          return null;
        });
  }
}
