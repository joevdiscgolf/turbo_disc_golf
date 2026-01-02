import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'create_course_state.dart';
import 'package:turbo_disc_golf/models/data/course_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

class CreateCourseCubit extends Cubit<CreateCourseState> {
  CreateCourseCubit() : super(CreateCourseState.initial()) {
    _initializeDefaultLayout();
  }

  final _uuid = const Uuid();

  // ─────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────
  void _initializeDefaultLayout() {
    final holes = _generateDefaultHoles(state.numberOfHoles);

    emit(
      state.copyWith(
        layouts: [
          CourseLayout(
            id: _uuid.v4(),
            name: 'Main Layout',
            holes: holes,
            isDefault: true,
          ),
        ],
      ),
    );
  }

  List<CourseHole> _generateDefaultHoles(int count) {
    return List.generate(count, (index) {
      final holeNumber = index + 1;

      return CourseHole(
        holeNumber: holeNumber,
        par: 3,
        feet: 300,
        holeType: HoleType.open,
        pins: const [HolePin(id: 'A', par: 3, feet: 300, label: 'Default')],
        defaultPinId: 'A',
      );
    });
  }

  // ─────────────────────────────────────────────
  // Course info
  // ─────────────────────────────────────────────
  void updateCourseName(String name) {
    emit(state.copyWith(courseName: name));
  }

  void updateCity(String value) {
    emit(state.copyWith(city: value));
  }

  void updateState(String value) {
    emit(state.copyWith(state: value));
  }

  void updateCountry(String value) {
    emit(state.copyWith(country: value));
  }

  // ─────────────────────────────────────────────
  // Layout
  // ─────────────────────────────────────────────
  void updateLayoutName(String layoutId, String name) {
    emit(
      state.copyWith(
        layouts: state.layouts.map((layout) {
          if (layout.id != layoutId) return layout;
          return layout.copyWith(name: name);
        }).toList(),
      ),
    );
  }

  void updateHoleCount(int count) {
    final defaultLayout = state.defaultLayout;
    if (defaultLayout == null) return;

    final updatedLayout = defaultLayout.copyWith(
      holes: _generateDefaultHoles(count),
    );

    emit(state.copyWith(numberOfHoles: count, layouts: [updatedLayout]));
  }

  // ─────────────────────────────────────────────
  // Hole editing
  // ─────────────────────────────────────────────
  void updateHole({
    required String layoutId,
    required int holeNumber,
    int? par,
    int? feet,
    HoleType? holeType,
  }) {
    emit(
      state.copyWith(
        layouts: state.layouts.map((layout) {
          if (layout.id != layoutId) return layout;

          return layout.copyWith(
            holes: layout.holes.map((hole) {
              if (hole.holeNumber != holeNumber) return hole;

              return hole.copyWith(par: par, feet: feet, holeType: holeType);
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Validation + Build
  // ─────────────────────────────────────────────
  bool get canSave {
    return state.courseName.trim().isNotEmpty &&
        state.layouts.isNotEmpty &&
        state.defaultLayout != null &&
        state.layouts.first.holes.isNotEmpty;
  }

  Course buildCourse() {
    if (!canSave) {
      throw StateError('CreateCourseCubit: invalid state');
    }

    return Course(
      id: _uuid.v4(),
      name: state.courseName.trim(),
      layouts: state.layouts,
      city: state.city?.trim().isEmpty ?? true ? null : state.city,
      state: state.state?.trim().isEmpty ?? true ? null : state.state,
      country: state.country?.trim().isEmpty ?? true ? null : state.country,
    );
  }
}
