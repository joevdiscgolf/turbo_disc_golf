import 'package:equatable/equatable.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';

class CreateLayoutState extends Equatable {
  const CreateLayoutState({
    required this.layoutId,
    required this.layoutName,
    required this.holes,
    required this.numberOfHoles,
    required this.isParsingImage,
    required this.isEditMode,
    this.parseError,
  });

  // ─────────────────────────────────────────────
  // Initial state for creating a new layout
  // ─────────────────────────────────────────────
  factory CreateLayoutState.initial() {
    return const CreateLayoutState(
      layoutId: '',
      layoutName: '',
      holes: [],
      numberOfHoles: 18,
      isParsingImage: false,
      isEditMode: false,
    );
  }

  // ─────────────────────────────────────────────
  // State from an existing layout (edit mode)
  // ─────────────────────────────────────────────
  factory CreateLayoutState.fromLayout(CourseLayout layout) {
    return CreateLayoutState(
      layoutId: layout.id,
      layoutName: layout.name,
      holes: layout.holes,
      numberOfHoles: layout.holes.length,
      isParsingImage: false,
      isEditMode: true,
    );
  }

  // ─────────────────────────────────────────────
  // Core fields
  // ─────────────────────────────────────────────
  final String layoutId;
  final String layoutName;
  final List<CourseHole> holes;

  /// Used when regenerating holes
  final int numberOfHoles;

  // ─────────────────────────────────────────────
  // Loading states
  // ─────────────────────────────────────────────
  final bool isParsingImage;
  final String? parseError;

  // ─────────────────────────────────────────────
  // Mode
  // ─────────────────────────────────────────────
  final bool isEditMode;

  // ─────────────────────────────────────────────
  // Derived
  // ─────────────────────────────────────────────
  bool get hasValidLayout => holes.isNotEmpty;
  bool get canSave => layoutName.trim().isNotEmpty && holes.isNotEmpty;

  // ─────────────────────────────────────────────
  // Copy
  // ─────────────────────────────────────────────
  CreateLayoutState copyWith({
    String? layoutId,
    String? layoutName,
    List<CourseHole>? holes,
    int? numberOfHoles,
    bool? isParsingImage,
    bool? isEditMode,
    String? parseError,
  }) {
    return CreateLayoutState(
      layoutId: layoutId ?? this.layoutId,
      layoutName: layoutName ?? this.layoutName,
      holes: holes ?? this.holes,
      numberOfHoles: numberOfHoles ?? this.numberOfHoles,
      isParsingImage: isParsingImage ?? this.isParsingImage,
      isEditMode: isEditMode ?? this.isEditMode,
      parseError: parseError,
    );
  }

  @override
  List<Object?> get props => [
    layoutId,
    layoutName,
    holes,
    numberOfHoles,
    isParsingImage,
    isEditMode,
    parseError,
  ];
}
