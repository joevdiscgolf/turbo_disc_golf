import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'create_course_state.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course_data.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';

class CreateCourseCubit extends Cubit<CreateCourseState> {
  CreateCourseCubit() : super(CreateCourseState.initial()) {
    _initializeDefaultLayout();
  }

  final _uuid = const Uuid();
  final _picker = ImagePicker();

  // ─────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────
  void _initializeDefaultLayout() {
    emit(
      state.copyWith(
        layoutId: _uuid.v4(),
        layoutName: 'Main Layout',
        holes: _generateDefaultHoles(state.numberOfHoles),
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
  // Course info (KEEPING YOUR NAMES)
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

  // Aliases used by UI (no behavior change)
  void courseNameChanged(String v) => updateCourseName(v);
  void cityChanged(String v) => updateCity(v);
  void stateChanged(String v) => updateState(v);
  void countryChanged(String v) => updateCountry(v);

  // ─────────────────────────────────────────────
  // Layout
  // ─────────────────────────────────────────────
  void updateLayoutName(String name) {
    emit(state.copyWith(layoutName: name));
  }

  // UI alias
  void layoutNameChanged(String v) => updateLayoutName(v);

  void updateHoleCount(int count) {
    emit(
      state.copyWith(numberOfHoles: count, holes: _generateDefaultHoles(count)),
    );
  }

  // ─────────────────────────────────────────────
  // Hole editing
  // ─────────────────────────────────────────────
  void updateHolePar(int holeNumber, int par) {
    _updateHole(holeNumber, par: par);
  }

  void updateHoleFeet(int holeNumber, int feet) {
    _updateHole(holeNumber, feet: feet);
  }

  void updateHoleType(int holeNumber, HoleType type) {
    _updateHole(holeNumber, holeType: type);
  }

  void _updateHole(int holeNumber, {int? par, int? feet, HoleType? holeType}) {
    emit(
      state.copyWith(
        holes: state.holes.map((hole) {
          if (hole.holeNumber != holeNumber) return hole;
          return hole.copyWith(par: par, feet: feet, holeType: holeType);
        }).toList(),
      ),
    );
  }

  /// Apply default values to all holes (quick fill feature)
  void applyDefaultsToAllHoles({
    required int defaultPar,
    required int defaultFeet,
    required HoleType defaultType,
  }) {
    final List<CourseHole> updatedHoles = state.holes.map((hole) {
      return hole.copyWith(
        par: defaultPar,
        feet: defaultFeet,
        holeType: defaultType,
      );
    }).toList();

    emit(state.copyWith(holes: updatedHoles));
  }

  // ─────────────────────────────────────────────
  // Image parsing
  // ─────────────────────────────────────────────
  Future<void> pickAndParseImage(BuildContext context) async {
    emit(state.copyWith(parseError: null));

    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final image = await _picker.pickImage(source: source);
      if (image == null) return;

      emit(state.copyWith(isParsingImage: true));

      final ai = locator.get<AiParsingService>();
      final List<HoleMetadata> metadata = await ai.parseScorecard(
        imagePath: image.path,
      );

      if (metadata.isEmpty) {
        emit(
          state.copyWith(
            isParsingImage: false,
            parseError: 'No course data found. Try another image.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          isParsingImage: false,
          numberOfHoles: metadata.length,
          holes: metadata.map((m) {
            return CourseHole(
              holeNumber: m.holeNumber,
              par: m.par,
              feet: m.distanceFeet ?? 300,
              holeType: HoleType.open,
              pins: [
                HolePin(
                  id: 'A',
                  par: m.par,
                  feet: m.distanceFeet ?? 300,
                  label: 'Default',
                ),
              ],
              defaultPinId: 'A',
            );
          }).toList(),
        ),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Parsed ${metadata.length} holes')),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isParsingImage: false,
          parseError: 'Failed to parse image',
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  // Validation + Save
  // ─────────────────────────────────────────────
  bool get canSave {
    return state.courseName.trim().isNotEmpty && state.holes.isNotEmpty;
  }

  void saveCourse() {
    if (!canSave) return;

    final layout = CourseLayout(
      id: state.layoutId,
      name: state.layoutName.trim(),
      holes: state.holes,
      isDefault: true,
    );

    final course = Course(
      id: _uuid.v4(),
      name: state.courseName.trim(),
      layouts: [layout],
      city: state.city?.trim().isEmpty ?? true ? null : state.city,
      state: state.state?.trim().isEmpty ?? true ? null : state.state,
      country: state.country?.trim().isEmpty ?? true ? null : state.country,
    );

    print('on course created to implement here, course name: ${course.name}');
    // _onCourseCreated(course);
  }
}
