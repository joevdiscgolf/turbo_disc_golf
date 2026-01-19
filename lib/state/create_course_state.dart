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
    required this.isGeocodingLocation,
    required this.isSaving,
    this.parseError,
    this.city,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
    this.previousHolesSnapshot,
  });

  // ─────────────────────────────────────────────
  // Initial
  // ─────────────────────────────────────────────
  factory CreateCourseState.initial() {
    return const CreateCourseState(
      courseName: '',
      layoutId: '',
      layoutName: '',
      holes: [],
      numberOfHoles: 18,
      isParsingImage: false,
      isGeocodingLocation: false,
      isSaving: false,
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
  final double? latitude;
  final double? longitude;

  // ─────────────────────────────────────────────
  // Loading states
  // ─────────────────────────────────────────────
  final bool isParsingImage;
  final bool isGeocodingLocation;
  final bool isSaving;
  final String? parseError;

  // ─────────────────────────────────────────────
  // Undo support
  // ─────────────────────────────────────────────
  final List<CourseHole>? previousHolesSnapshot;

  // ─────────────────────────────────────────────
  // Derived
  // ─────────────────────────────────────────────
  bool get hasValidLayout => holes.isNotEmpty;
  bool get hasLocation => latitude != null && longitude != null;

  /// Returns completion percentage (0-100).
  /// Sections: Course name (required), Location, Layout name, Holes (always complete)
  int get completionPercentage {
    int completed = 0;
    if (courseName.trim().isNotEmpty) completed++;
    if (hasLocation) completed++;
    if (layoutName.trim().isNotEmpty) completed++;
    // Holes always exist, count as complete
    completed++;
    return ((completed / 4) * 100).round();
  }

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
    bool? isGeocodingLocation,
    bool? isSaving,
    String? parseError,
    String? city,
    String? state,
    String? country,
    double? latitude,
    double? longitude,
    bool clearLocation = false,
    List<CourseHole>? previousHolesSnapshot,
    bool clearPreviousHolesSnapshot = false,
  }) {
    return CreateCourseState(
      courseName: courseName ?? this.courseName,
      layoutId: layoutId ?? this.layoutId,
      layoutName: layoutName ?? this.layoutName,
      holes: holes ?? this.holes,
      numberOfHoles: numberOfHoles ?? this.numberOfHoles,
      isParsingImage: isParsingImage ?? this.isParsingImage,
      isGeocodingLocation: isGeocodingLocation ?? this.isGeocodingLocation,
      isSaving: isSaving ?? this.isSaving,
      parseError: parseError,
      city: clearLocation ? null : (city ?? this.city),
      state: clearLocation ? null : (state ?? this.state),
      country: clearLocation ? null : (country ?? this.country),
      latitude: clearLocation ? null : (latitude ?? this.latitude),
      longitude: clearLocation ? null : (longitude ?? this.longitude),
      previousHolesSnapshot: clearPreviousHolesSnapshot
          ? null
          : (previousHolesSnapshot ?? this.previousHolesSnapshot),
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
    isGeocodingLocation,
    isSaving,
    parseError,
    city,
    state,
    country,
    latitude,
    longitude,
    previousHolesSnapshot,
  ];
}
