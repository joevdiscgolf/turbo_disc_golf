import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/course_data.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_constants.dart';
import 'package:turbo_disc_golf/utils/firebase/firebase_utils.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

abstract class FBCourseDataLoader {
  static Future<Course?> getCourseById(String id) async {
    final DocumentSnapshot<Map<String, dynamic>>? snapshot =
        await firestoreFetch('$kCoursesCollection/$id');

    if (snapshot == null) return null;

    try {
      return Course.fromJson(snapshot.data()!);
    } catch (e, trace) {
      debugPrint('[FBCourseDataLoader][getCourseById] Error');
      debugPrint(e.toString());
      debugPrint(trace.toString());
      return null;
    }
  }

  static Future<bool> saveCourse(Course course) async {
    return firestoreWrite('$kCoursesCollection/${course.id}', course.toJson());
  }
}
