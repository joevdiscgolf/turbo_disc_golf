import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'create_course_state.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/protocols/clear_on_logout_protocol.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';
import 'package:turbo_disc_golf/services/courses/course_search_service.dart';
import 'package:turbo_disc_golf/services/firestore/course_data_loader.dart';
import 'package:turbo_disc_golf/services/geocoding/geocoding_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';

const String _createCourseDraftKey = 'create_course_draft';

class CreateCourseCubit extends Cubit<CreateCourseState>
    implements ClearOnLogoutProtocol {
  CreateCourseCubit() : super(CreateCourseState.initial()) {
    _initializeDefaultLayout();
  }

  @override
  Future<void> clearOnLogout() async {
    emit(CreateCourseState.initial());
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

  /// Updates country selection from the country picker panel
  void updateCountrySelection(String code, String name) {
    emit(state.copyWith(country: name, countryCode: code));
  }

  // Aliases used by UI (no behavior change)
  void courseNameChanged(String v) => updateCourseName(v);
  void cityChanged(String v) => updateCity(v);
  void stateChanged(String v) => updateState(v);
  void countryChanged(String v) => updateCountry(v);

  // ─────────────────────────────────────────────
  // Location (Map Picker)
  // ─────────────────────────────────────────────

  /// Updates the course location from map selection and triggers reverse geocoding.
  Future<void> updateLocation(double lat, double lng) async {
    // Immediately update coordinates
    emit(state.copyWith(
      latitude: lat,
      longitude: lng,
      isGeocodingLocation: true,
    ));

    // Perform reverse geocoding to get city/state/country
    await _reverseGeocodeLocation(lat, lng);
  }

  /// Clears the selected location and all related fields.
  void clearLocation() {
    emit(state.copyWith(clearLocation: true, isGeocodingLocation: false));
  }

  /// Performs reverse geocoding using Nominatim API.
  Future<void> _reverseGeocodeLocation(double lat, double lng) async {
    try {
      final GeocodingService geocodingService = locator.get<GeocodingService>();
      final LocationDetails? details = await geocodingService.reverseGeocode(lat, lng);

      if (details != null) {
        emit(state.copyWith(
          city: details.city,
          state: details.state,
          country: details.country,
          countryCode: details.countryCode,
          isGeocodingLocation: false,
        ));
      } else {
        // Geocoding returned no results - just clear the loading state
        emit(state.copyWith(isGeocodingLocation: false));
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      emit(state.copyWith(isGeocodingLocation: false));
    }
  }

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
  // Quick fill undo support
  // ─────────────────────────────────────────────
  void snapshotHolesForUndo() {
    emit(state.copyWith(previousHolesSnapshot: List.from(state.holes)));
  }

  void undoQuickFill() {
    if (state.previousHolesSnapshot != null) {
      emit(state.copyWith(
        holes: state.previousHolesSnapshot,
        clearPreviousHolesSnapshot: true,
      ));
    }
  }

  void clearHolesSnapshot() {
    emit(state.copyWith(clearPreviousHolesSnapshot: true));
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
  // Validation + Save
  // ─────────────────────────────────────────────
  bool get canSave {
    return state.courseName.trim().isNotEmpty && state.holes.isNotEmpty;
  }

  // ─────────────────────────────────────────────
  // Draft persistence
  // ─────────────────────────────────────────────

  /// Checks if a draft exists without loading it
  static Future<bool> hasDraft() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_createCourseDraftKey);
  }

  /// Saves the current state as a draft
  Future<void> saveDraft() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> draftData = {
        'courseName': state.courseName,
        'layoutId': state.layoutId,
        'layoutName': state.layoutName,
        'numberOfHoles': state.numberOfHoles,
        'holes': state.holes.map((h) => h.toJson()).toList(),
        'city': state.city,
        'state': state.state,
        'country': state.country,
        'countryCode': state.countryCode,
        'latitude': state.latitude,
        'longitude': state.longitude,
      };
      await prefs.setString(_createCourseDraftKey, jsonEncode(draftData));
      debugPrint('Draft saved successfully');
    } catch (e) {
      debugPrint('Error saving draft: $e');
    }
  }

  /// Loads a saved draft and restores state
  Future<bool> loadDraft() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? draftJson = prefs.getString(_createCourseDraftKey);
      if (draftJson == null) return false;

      final Map<String, dynamic> draftData = jsonDecode(draftJson);

      final List<CourseHole> holes = (draftData['holes'] as List)
          .map((h) => CourseHole.fromJson(h as Map<String, dynamic>))
          .toList();

      emit(state.copyWith(
        courseName: draftData['courseName'] as String? ?? '',
        layoutId: draftData['layoutId'] as String? ?? state.layoutId,
        layoutName: draftData['layoutName'] as String? ?? '',
        numberOfHoles: draftData['numberOfHoles'] as int? ?? 18,
        holes: holes,
        city: draftData['city'] as String?,
        state: draftData['state'] as String?,
        country: draftData['country'] as String?,
        countryCode: draftData['countryCode'] as String?,
        latitude: draftData['latitude'] as double?,
        longitude: draftData['longitude'] as double?,
      ));

      debugPrint('Draft loaded successfully');
      return true;
    } catch (e) {
      debugPrint('Error loading draft: $e');
      return false;
    }
  }

  /// Clears any saved draft
  static Future<void> clearDraft() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_createCourseDraftKey);
      debugPrint('Draft cleared');
    } catch (e) {
      debugPrint('Error clearing draft: $e');
    }
  }

  Future<bool> saveCourse({
    required void Function(Course) onSuccess,
    required void Function(String errorMessage) onError,
  }) async {
    if (!canSave) {
      onError('Please fill in all required fields');
      return false;
    }

    emit(state.copyWith(isSaving: true));

    try {
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
        countryCode: state.countryCode?.trim().isEmpty ?? true ? null : state.countryCode,
        latitude: state.latitude,
        longitude: state.longitude,
      );

      debugPrint('Saving course: ${course.name}');

      // Save to Firestore
      final bool firestoreSaved = await FBCourseDataLoader.saveCourse(course);
      if (!firestoreSaved) {
        emit(state.copyWith(isSaving: false));
        onError('Failed to save course to database');
        return false;
      }
      debugPrint('Course saved to Firestore');

      // Add to shared preferences cache (search indexing handled by backend)
      try {
        await locator.get<CourseSearchService>().markCourseAsUsed(
          course.toCourseSearchHit(),
        );
        debugPrint('Course added to shared preferences cache');
      } catch (e) {
        debugPrint('Warning: Failed to add course to cache: $e');
      }

      emit(state.copyWith(isSaving: false));

      // Call success callback
      onSuccess(course);

      return true;
    } catch (e, trace) {
      debugPrint('Error saving course: $e');
      debugPrint(trace.toString());
      emit(state.copyWith(isSaving: false));
      onError('Failed to create course: ${e.toString()}');
      return false;
    }
  }
}
