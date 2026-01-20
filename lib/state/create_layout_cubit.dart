import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';
import 'package:turbo_disc_golf/state/create_layout_state.dart';

class CreateLayoutCubit extends Cubit<CreateLayoutState> {
  /// Creates a new layout (create mode)
  CreateLayoutCubit() : super(CreateLayoutState.initial()) {
    _initializeDefaultLayout();
  }

  /// Creates a cubit for editing an existing layout (edit mode)
  CreateLayoutCubit.fromLayout(CourseLayout layout)
      : super(CreateLayoutState.fromLayout(layout));

  final _uuid = const Uuid();
  final _picker = ImagePicker();

  // ─────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────
  void _initializeDefaultLayout() {
    emit(
      state.copyWith(
        layoutId: _uuid.v4(),
        layoutName: '',
        holes: _generateDefaultHoles(state.numberOfHoles),
      ),
    );
  }

  List<CourseHole> _generateDefaultHoles(int count) {
    return List.generate(count, (index) {
      final int holeNumber = index + 1;

      return CourseHole(
        holeNumber: holeNumber,
        par: 3,
        feet: 300,
        holeType: HoleType.slightlyWooded,
        holeShape: HoleShape.straight,
        pins: const [HolePin(id: 'A', par: 3, feet: 300, label: 'Default')],
        defaultPinId: 'A',
      );
    });
  }

  // ─────────────────────────────────────────────
  // Layout
  // ─────────────────────────────────────────────
  void updateLayoutName(String name) {
    emit(state.copyWith(layoutName: name));
  }

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

  void updateHoleShape(int holeNumber, HoleShape shape) {
    _updateHole(holeNumber, holeShape: shape);
  }

  void _updateHole(
    int holeNumber, {
    int? par,
    int? feet,
    HoleType? holeType,
    HoleShape? holeShape,
  }) {
    emit(
      state.copyWith(
        holes: state.holes.map((hole) {
          if (hole.holeNumber != holeNumber) return hole;
          return hole.copyWith(
            par: par,
            feet: feet,
            holeType: holeType,
            holeShape: holeShape,
          );
        }).toList(),
      ),
    );
  }

  /// Apply default values to all holes (quick fill feature)
  void applyDefaultsToAllHoles({
    required int defaultPar,
    required int defaultFeet,
    required HoleType defaultType,
    required HoleShape defaultShape,
  }) {
    final List<CourseHole> updatedHoles = state.holes.map((hole) {
      return hole.copyWith(
        par: defaultPar,
        feet: defaultFeet,
        holeType: defaultType,
        holeShape: defaultShape,
      );
    }).toList();

    emit(state.copyWith(holes: updatedHoles));
  }

  // ─────────────────────────────────────────────
  // Image parsing
  // ─────────────────────────────────────────────
  Future<void> pickAndParseImage(BuildContext context) async {
    emit(state.copyWith(parseError: null));

    XFile? image;

    try {
      // Use addPostFrameCallback to ensure UI is ready before showing picker
      await Future.delayed(Duration.zero);

      // Pick image with timeout to prevent indefinite hanging
      image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
        requestFullMetadata: false, // Faster loading
      ).timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          debugPrint('Image picker timed out');
          return null;
        },
      );
    } catch (e) {
      debugPrint('Error picking image: $e');

      // Only show error if it's not a user cancellation
      if (!e.toString().toLowerCase().contains('cancel')) {
        emit(state.copyWith(
          isParsingImage: false,
          parseError: 'Failed to pick image: ${e.toString()}',
        ));
      } else {
        emit(state.copyWith(isParsingImage: false, parseError: null));
      }
      return;
    }

    // User cancelled or error occurred
    if (image == null) {
      emit(state.copyWith(isParsingImage: false, parseError: null));
      return;
    }

    if (!context.mounted) return;

    emit(state.copyWith(isParsingImage: true));

    try {
      final AiParsingService ai = locator.get<AiParsingService>();
      List<HoleMetadata> metadata = [];

      // Try parsing with automatic retry on rate limit
      try {
        metadata = await ai.parseScorecard(imagePath: image.path);
      } catch (e) {
        // Check if it's a quota/rate limit error
        if (e.toString().contains('Quota exceeded') ||
            e.toString().contains('quota') ||
            e.toString().contains('rate limit')) {
          debugPrint('Rate limit hit, retrying after delay...');

          // Extract wait time from error message if available
          final RegExp waitTimeRegex = RegExp(r'retry in (\d+\.?\d*)s');
          final Match? match = waitTimeRegex.firstMatch(e.toString());
          final double waitSeconds = match != null
              ? double.parse(match.group(1)!)
              : 10.0; // Default to 10 seconds

          emit(
            state.copyWith(
              parseError:
                  'Rate limit reached. Retrying in ${waitSeconds.ceil()} seconds...',
            ),
          );

          // Wait for the suggested time
          await Future.delayed(Duration(milliseconds: (waitSeconds * 1000).toInt()));

          // Retry the request
          metadata = await ai.parseScorecard(imagePath: image.path);

          // Clear the retry message
          emit(state.copyWith(parseError: null));
        } else {
          rethrow;
        }
      }

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
              holeType: HoleType.slightlyWooded,
              holeShape: HoleShape.straight,
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

      locator.get<ToastService>().showInfo('Parsed ${metadata.length} holes');
    } catch (e) {
      debugPrint('Error in pickAndParseImage: $e');
      emit(
        state.copyWith(
          isParsingImage: false,
          parseError: 'Failed to parse image',
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  // Build Layout
  // ─────────────────────────────────────────────

  /// Builds and returns a CourseLayout from the current state.
  /// The UI is responsible for saving this to the course.
  CourseLayout buildLayout({bool isDefault = false}) {
    return CourseLayout(
      id: state.layoutId,
      name: state.layoutName.trim().isEmpty
          ? 'New Layout'
          : state.layoutName.trim(),
      holes: state.holes,
      isDefault: isDefault,
    );
  }

  bool get canSave => state.canSave;
}
