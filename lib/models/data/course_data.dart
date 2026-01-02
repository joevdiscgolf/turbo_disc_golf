import 'package:json_annotation/json_annotation.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

part 'course_data.g.dart';

/// Represents a single hole in a course layout with baseline information
@JsonSerializable(explicitToJson: true, anyMap: true)
class CourseHole {
  const CourseHole({
    required this.holeNumber,
    required this.par,
    required this.feet,
    this.holeType,
  });

  /// Hole number (1-18, 1-9, etc.)
  final int holeNumber;

  /// Par for this hole (typically 3-5)
  final int par;

  /// Distance in feet from tee to basket
  final int feet;

  /// Type of terrain/openness for this hole
  final HoleType? holeType;

  factory CourseHole.fromJson(Map<String, dynamic> json) =>
      _$CourseHoleFromJson(json);

  Map<String, dynamic> toJson() => _$CourseHoleToJson(this);

  CourseHole copyWith({
    int? holeNumber,
    int? par,
    int? feet,
    HoleType? holeType,
  }) {
    return CourseHole(
      holeNumber: holeNumber ?? this.holeNumber,
      par: par ?? this.par,
      feet: feet ?? this.feet,
      holeType: holeType ?? this.holeType,
    );
  }
}

/// Represents a specific layout configuration of a disc golf course
@JsonSerializable(explicitToJson: true, anyMap: true)
class CourseLayout {
  const CourseLayout({
    required this.id,
    required this.name,
    required this.holes,
    this.description,
    this.isDefault = false,
  });

  /// Unique identifier for this layout
  final String id;

  /// Display name (e.g., "18-hole Championship", "9-hole Short", "Blue Tees")
  final String name;

  /// List of holes in this layout
  final List<CourseHole> holes;

  /// Optional description or notes about this layout
  final String? description;

  /// Whether this is the default/primary layout for the course
  final bool isDefault;

  /// Total number of holes in this layout
  int get numberOfHoles => holes.length;

  /// Total par for this layout
  int get totalPar => holes.fold(0, (sum, hole) => sum + hole.par);

  /// Total distance in feet for this layout
  int get totalFeet => holes.fold(0, (sum, hole) => sum + hole.feet);

  factory CourseLayout.fromJson(Map<String, dynamic> json) =>
      _$CourseLayoutFromJson(json);

  Map<String, dynamic> toJson() => _$CourseLayoutToJson(this);

  CourseLayout copyWith({
    String? id,
    String? name,
    List<CourseHole>? holes,
    String? description,
    bool? isDefault,
  }) {
    return CourseLayout(
      id: id ?? this.id,
      name: name ?? this.name,
      holes: holes ?? this.holes,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// Represents a disc golf course with potentially multiple layouts
@JsonSerializable(explicitToJson: true, anyMap: true)
class Course {
  const Course({
    required this.id,
    required this.name,
    required this.layouts,
    this.location,
    this.city,
    this.state,
    this.country,
    this.description,
    this.uDiscId,
    this.pdgaId,
  });

  /// Unique identifier for this course (e.g., UUID or external API ID)
  final String id;

  /// Course name (e.g., "Blue Lake Disc Golf Course")
  final String name;

  /// List of available layouts for this course
  /// Most courses have 1 layout, some have multiple (front 9, back 9, championship, etc.)
  final List<CourseLayout> layouts;

  // Location information
  final String? location; // General location description
  final String? city;
  final String? state;
  final String? country;

  /// Course description or notes
  final String? description;

  // External IDs for integration with disc golf platforms
  final String? uDiscId; // UDisc course ID
  final String? pdgaId; // PDGA course ID

  /// Get the default layout (marked as isDefault: true)
  /// Falls back to first layout if no default is marked
  CourseLayout get defaultLayout {
    try {
      return layouts.firstWhere((layout) => layout.isDefault);
    } catch (e) {
      return layouts.first;
    }
  }

  /// Get layout by ID, returns null if not found
  CourseLayout? getLayoutById(String layoutId) {
    try {
      return layouts.firstWhere((layout) => layout.id == layoutId);
    } catch (e) {
      return null;
    }
  }

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);

  Map<String, dynamic> toJson() => _$CourseToJson(this);

  Course copyWith({
    String? id,
    String? name,
    List<CourseLayout>? layouts,
    String? location,
    String? city,
    String? state,
    String? country,
    String? description,
    String? uDiscId,
    String? pdgaId,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      layouts: layouts ?? this.layouts,
      location: location ?? this.location,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      description: description ?? this.description,
      uDiscId: uDiscId ?? this.uDiscId,
      pdgaId: pdgaId ?? this.pdgaId,
    );
  }
}
