import 'package:equatable/equatable.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';

class CreateCourseState extends Equatable {
  const CreateCourseState({
    required this.courseName,
    required this.layoutId,
    required this.layoutName,
    required this.holes,
    required this.numberOfHoles,
    required this.isParsingImage,
    this.parseError,
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
      layoutId: '',
      layoutName: 'Main Layout',
      holes: [],
      numberOfHoles: 18,
      isParsingImage: false,
    );
  }

  // ─────────────────────────────────────────────
  // Core fields
  // ─────────────────────────────────────────────
  final String courseName;

  /// Single default layout (UI assumes only one)
  final String layoutId;
  final String layoutName;
  final List<CourseHole> holes;

  /// Used when regenerating holes
  final int numberOfHoles;

  // ─────────────────────────────────────────────
  // Location
  // ─────────────────────────────────────────────
  final String? city;
  final String? state;
  final String? country;

  // ─────────────────────────────────────────────
  // Image parsing
  // ─────────────────────────────────────────────
  final bool isParsingImage;
  final String? parseError;

  // ─────────────────────────────────────────────
  // Derived
  // ─────────────────────────────────────────────
  bool get hasValidLayout => holes.isNotEmpty;

  // ─────────────────────────────────────────────
  // Copy
  // ─────────────────────────────────────────────
  CreateCourseState copyWith({
    String? courseName,
    String? layoutId,
    String? layoutName,
    List<CourseHole>? holes,
    int? numberOfHoles,
    bool? isParsingImage,
    String? parseError,
    String? city,
    String? state,
    String? country,
  }) {
    return CreateCourseState(
      courseName: courseName ?? this.courseName,
      layoutId: layoutId ?? this.layoutId,
      layoutName: layoutName ?? this.layoutName,
      holes: holes ?? this.holes,
      numberOfHoles: numberOfHoles ?? this.numberOfHoles,
      isParsingImage: isParsingImage ?? this.isParsingImage,
      parseError: parseError,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
    );
  }

  @override
  List<Object?> get props => [
    courseName,
    layoutId,
    layoutName,
    holes,
    numberOfHoles,
    isParsingImage,
    parseError,
    city,
    state,
    country,
  ];
}
