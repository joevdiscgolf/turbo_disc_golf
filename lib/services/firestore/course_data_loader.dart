import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_constants.dart';
import 'package:turbo_disc_golf/utils/firebase/firebase_utils.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

abstract class FBCourseDataLoader {
  /// Loads all courses from Firestore.
  static Future<List<Course>> getAllCourses() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await firestore.collection(kCoursesCollection).get();

      final List<Course> courses = [];
      for (final doc in snapshot.docs) {
        try {
          courses.add(Course.fromJson(doc.data()));
        } catch (e) {
          debugPrint('[FBCourseDataLoader][getAllCourses] Error parsing course ${doc.id}: $e');
        }
      }
      return courses;
    } catch (e, trace) {
      debugPrint('[FBCourseDataLoader][getAllCourses] Error');
      debugPrint(e.toString());
      debugPrint(trace.toString());
      return [];
    }
  }

  static Future<Course?> getCourseById(String id) async {
    final DocumentSnapshot<Map<String, dynamic>>? snapshot =
        await firestoreFetch('$kCoursesCollection/$id');

    if (snapshot?.data() == null) return null;

    try {
      return Course.fromJson(snapshot!.data()!);
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

  /// Deletes a course from Firestore by its ID
  static Future<void> deleteCourse(String courseId) async {
    await FirebaseFirestore.instance
        .collection(kCoursesCollection)
        .doc(courseId)
        .delete();
  }

  /// Adds a new layout to an existing course.
  /// Returns the updated course on success, null on failure.
  static Future<Course?> addLayoutToCourse(
    String courseId,
    CourseLayout layout,
  ) async {
    try {
      // Fetch the current course
      final Course? course = await getCourseById(courseId);
      if (course == null) {
        debugPrint('[FBCourseDataLoader][addLayoutToCourse] Course not found');
        return null;
      }

      // Create updated course with new layout
      final Course updatedCourse = course.copyWith(
        layouts: [...course.layouts, layout],
      );

      // Save the updated course
      final bool success = await saveCourse(updatedCourse);
      if (!success) {
        debugPrint('[FBCourseDataLoader][addLayoutToCourse] Failed to save');
        return null;
      }

      return updatedCourse;
    } catch (e, trace) {
      debugPrint('[FBCourseDataLoader][addLayoutToCourse] Error');
      debugPrint(e.toString());
      debugPrint(trace.toString());
      return null;
    }
  }

  /// Updates an existing layout in a course.
  /// Returns the updated course on success, null on failure.
  static Future<Course?> updateLayoutInCourse(
    String courseId,
    CourseLayout layout,
  ) async {
    try {
      // Fetch the current course
      final Course? course = await getCourseById(courseId);
      if (course == null) {
        debugPrint('[FBCourseDataLoader][updateLayoutInCourse] Course not found');
        return null;
      }

      // Update the layout in the list
      final List<CourseLayout> updatedLayouts = course.layouts.map((l) {
        return l.id == layout.id ? layout : l;
      }).toList();

      // Create updated course with modified layouts
      final Course updatedCourse = course.copyWith(layouts: updatedLayouts);

      // Save the updated course
      final bool success = await saveCourse(updatedCourse);
      if (!success) {
        debugPrint('[FBCourseDataLoader][updateLayoutInCourse] Failed to save');
        return null;
      }

      return updatedCourse;
    } catch (e, trace) {
      debugPrint('[FBCourseDataLoader][updateLayoutInCourse] Error');
      debugPrint(e.toString());
      debugPrint(trace.toString());
      return null;
    }
  }
}
