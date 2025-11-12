import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';

/// State management for editing a single hole's metadata and throws.
///
/// Manages text controllers, focus nodes, and the current hole data.
/// Used with ChangeNotifierProvider to provide reactive state updates.
class HoleEditingState extends ChangeNotifier {
  HoleEditingState({required PotentialDGHole initialHole}) {
    _currentHole = initialHole;
    _initializeControllers();
  }

  late PotentialDGHole _currentHole;
  late TextEditingController _parController;
  late TextEditingController _distanceController;
  late FocusNode _parFocus;
  late FocusNode _distanceFocus;

  // Getters
  PotentialDGHole get currentHole => _currentHole;
  TextEditingController get parController => _parController;
  TextEditingController get distanceController => _distanceController;
  FocusNode get parFocus => _parFocus;
  FocusNode get distanceFocus => _distanceFocus;

  int get par => _currentHole.par ?? 0;
  int get distance => _currentHole.feet ?? 0;
  int get strokes => _currentHole.throws?.length ?? 0;
  bool get hasRequiredFields => _currentHole.hasRequiredFields;

  void _initializeControllers() {
    _parController = TextEditingController(
      text: _currentHole.par?.toString() ?? '',
    );
    _distanceController = TextEditingController(
      text: _currentHole.feet?.toString() ?? '',
    );
    _parFocus = FocusNode();
    _distanceFocus = FocusNode();
  }

  /// Updates the current hole data from an external source.
  /// Only updates controllers if they don't have focus (user not editing).
  void updateFromHole(PotentialDGHole newHole) {
    _currentHole = newHole;

    // Only update controllers if they don't have focus
    if (!_parFocus.hasFocus) {
      _parController.text = newHole.par?.toString() ?? '';
    }
    if (!_distanceFocus.hasFocus) {
      _distanceController.text = newHole.feet?.toString() ?? '';
    }

    notifyListeners();
  }

  /// Gets the current metadata values from the text controllers.
  /// Returns a map with par and distance keys.
  Map<String, int?> getMetadataValues() {
    final int? par = _parController.text.isEmpty
        ? null
        : int.tryParse(_parController.text);
    final int? distance = _distanceController.text.isEmpty
        ? null
        : int.tryParse(_distanceController.text);

    return {'par': par, 'distance': distance};
  }

  @override
  void dispose() {
    _parController.dispose();
    _distanceController.dispose();
    _parFocus.dispose();
    _distanceFocus.dispose();
    super.dispose();
  }
}
