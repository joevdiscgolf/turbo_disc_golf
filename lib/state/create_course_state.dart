import 'package:equatable/equatable.dart';
import 'package:turbo_disc_golf/models/data/course_data.dart';

class CreateCourseState extends Equatable {
  const CreateCourseState({
    required this.courseName,
    required this.layouts,
    required this.numberOfHoles,
    this.city,
    this.state,
    this.country,
  });

  // ─────────────────────────────────────────────
  // Initial
  // ─────────────────────────────────────────────
  factory CreateCourseState.initial() {
    return const CreateCourseState(
      courseName: '',
      layouts: [],
      numberOfHoles: 18,
    );
  }

  // ─────────────────────────────────────────────
  // Core fields
  // ─────────────────────────────────────────────
  final String courseName;
  final List<CourseLayout> layouts;

  /// Used when regenerating the default layout
  final int numberOfHoles;

  final String? city;
  final String? state;
  final String? country;

  // ─────────────────────────────────────────────
  // Derived
  // ─────────────────────────────────────────────
  CourseLayout? get defaultLayout {
    try {
      return layouts.firstWhere((l) => l.isDefault);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // Copy
  // ─────────────────────────────────────────────
  CreateCourseState copyWith({
    String? courseName,
    List<CourseLayout>? layouts,
    int? numberOfHoles,
    String? city,
    String? state,
    String? country,
  }) {
    return CreateCourseState(
      courseName: courseName ?? this.courseName,
      layouts: layouts ?? this.layouts,
      numberOfHoles: numberOfHoles ?? this.numberOfHoles,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
    );
  }

  @override
  List<Object?> get props => [
    courseName,
    layouts,
    numberOfHoles,
    city,
    state,
    country,
  ];
}
