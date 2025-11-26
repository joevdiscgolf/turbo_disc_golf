import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/naming_constants.dart';

/// Bottom sheet panel for adding or editing a throw with a space-efficient,
/// button-based UI.
class AddThrowPanel extends StatefulWidget {
  const AddThrowPanel({
    super.key,
    required this.existingThrow,
    required this.previousThrow,
    required this.throwIndex,
    required this.onSave,
    required this.onDelete,
    this.isNewThrow = false,
  });

  final DiscThrow? existingThrow;
  final DiscThrow? previousThrow;
  final int throwIndex;
  final void Function(DiscThrow) onSave;
  final VoidCallback? onDelete;
  final bool isNewThrow;

  @override
  State<AddThrowPanel> createState() => _AddThrowPanelState();
}

class _AddThrowPanelState extends State<AddThrowPanel> {
  late BagService _bagService;
  late List<DGDisc> _userDiscs;

  // Form state
  late ThrowPurpose? _purpose;
  late ThrowTechnique? _technique;
  late LandingSpot? _landingSpot;
  late int? _distanceBefore;
  late int? _distanceAfter;
  late ThrowResultRating? _resultRating;
  late String? _discId;
  late ShotShape? _shotShape;
  late PuttStyle? _puttStyle;
  int? _landingDistance; // Direct state for slider to avoid lag

  // Controllers for custom inputs
  late TextEditingController _customDistanceBeforeController;
  late TextEditingController _customDistanceAfterController;
  late TextEditingController _customLandingDistanceController;
  late TextEditingController _discSearchController;

  bool _showOptionalFields = false;

  // Quick-tap distance options
  // static const List<int> _quickDistances = [25, 50, 75, 100];

  // Accent colors for different fields (following record_round_panel_v2 pattern)
  static const Color _purposeAccent = Color(0xFF2196F3); // blue
  static const Color _techniqueAccent = Color(0xFF4CAF50); // green
  static const Color _landingAccent = Color(
    0xFFB39DDB,
  ); // light purple (matches description card)
  // static const Color _distanceAccent = Color(0xFFFF9800); // orange
  static const Color _ratingAccent = Color(0xFF2E7D32); // dark green
  static const Color _discAccent = Color(0xFF00BCD4); // cyan
  static const Color _shapeAccent = Color(0xFFB39DDB); // light purple
  static const Color _generalAccent = Color(0xFF9E9E9E); // gray

  // Button accent color (consistent across all buttons for UX)
  static const Color _buttonAccent = TurbColors.blue; // purple

  @override
  void initState() {
    super.initState();
    _bagService = locator.get<BagService>();
    _userDiscs = _bagService.userBag;

    // Initialize form values from throw, with smart auto-selection
    _purpose = widget.existingThrow?.purpose ?? _getAutoSelectedPurpose();
    _technique = widget.existingThrow?.technique;
    _landingSpot = widget.existingThrow?.landingSpot;
    _distanceBefore = widget.existingThrow?.distanceFeetBeforeThrow;
    _distanceAfter = widget.existingThrow?.distanceFeetAfterThrow;
    _resultRating = widget.existingThrow?.resultRating;
    _discId = widget.existingThrow?.disc?.id;
    _shotShape = widget.existingThrow?.shotShape;
    _puttStyle =
        widget.existingThrow?.puttStyle ??
        (_purpose == ThrowPurpose.putt ? PuttStyle.staggered : null);

    _customDistanceBeforeController = TextEditingController(
      text: _distanceBefore?.toString() ?? '',
    );
    _customDistanceAfterController = TextEditingController(
      text: _distanceAfter?.toString() ?? '',
    );
    _customLandingDistanceController = TextEditingController();
    _discSearchController = TextEditingController();

    // Initialize landing distance from text controller if available
    _landingDistance = int.tryParse(_customLandingDistanceController.text);
  }

  @override
  void dispose() {
    _customDistanceBeforeController.dispose();
    _customDistanceAfterController.dispose();
    _customLandingDistanceController.dispose();
    _discSearchController.dispose();
    super.dispose();
  }

  /// Determines the auto-selected purpose based on the previous throw's landing spot.
  /// If the previous throw landed in circle 1, circle 2, or was parked,
  /// then auto-select purpose as 'putt'.
  ThrowPurpose? _getAutoSelectedPurpose() {
    if (widget.previousThrow == null) return null;

    final LandingSpot? previousLanding = widget.previousThrow!.landingSpot;
    if (previousLanding == null) return null;

    // If previous throw landed in putting range, auto-select putt
    if (previousLanding == LandingSpot.circle1 ||
        previousLanding == LandingSpot.circle2 ||
        previousLanding == LandingSpot.parked) {
      return ThrowPurpose.putt;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5EEF8), // Light purple tint
              Colors.white, // Fade to white
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PanelHeader(
              title: widget.isNewThrow
                  ? 'Add Throw'
                  : 'Edit Throw ${widget.throwIndex + 1}',
            ),
            // _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPrimaryFields(),
                    const SizedBox(height: 16),
                    _buildOptionalFieldsToggle(),
                    if (_showOptionalFields) ...[
                      const SizedBox(height: 16),
                      _buildOptionalFields(),
                    ],
                  ],
                ),
              ),
            ),
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPurposeField(),
        const SizedBox(height: 12),
        _buildTechniqueField(),
        const SizedBox(height: 12),
        _buildLandingSpotField(),
      ],
    );
  }

  Widget _buildPurposeField() {
    final List<ThrowPurpose> visibleOptions = [
      ThrowPurpose.teeDrive,
      ThrowPurpose.approach,
      ThrowPurpose.putt,
    ];

    return _FieldCard(
      label: 'Purpose',
      icon: Icons.track_changes,
      accentColor: _purposeAccent,
      child: Row(
        children: [
          ...visibleOptions.map(
            (purpose) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildOptionButton(
                  label: throwPurposeToName[purpose] ?? purpose.name,
                  isSelected: _purpose == purpose,
                  accentColor: _purposeAccent,
                  onTap: () {
                    setState(() {
                      _purpose = purpose;
                      // Auto-select staggered putt style when switching to putt
                      if (purpose == ThrowPurpose.putt && _puttStyle == null) {
                        _puttStyle = PuttStyle.staggered;
                      }
                    });
                  },
                ),
              ),
            ),
          ),
          _buildMoreButton(
            accentColor: _purposeAccent,
            onTap: () => _showEnumPicker<ThrowPurpose>(
              title: 'Select Purpose',
              values: ThrowPurpose.values,
              nameMap: throwPurposeToName,
              currentValue: _purpose,
              accentColor: _purposeAccent,
              onSelect: (value) {
                setState(() {
                  _purpose = value;
                  // Auto-select staggered putt style when switching to putt
                  if (value == ThrowPurpose.putt && _puttStyle == null) {
                    _puttStyle = PuttStyle.staggered;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechniqueField() {
    // If purpose is putt, show putt style instead of technique
    if (_purpose == ThrowPurpose.putt) {
      final List<PuttStyle> visibleOptions = [
        PuttStyle.staggered,
        PuttStyle.straddle,
      ];

      return _FieldCard(
        label: 'Putt style',
        icon: Icons.golf_course,
        accentColor: _techniqueAccent,
        child: Row(
          children: [
            ...visibleOptions.map(
              (style) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildOptionButton(
                    label: puttStyleToName[style] ?? style.name,
                    isSelected: _puttStyle == style,
                    accentColor: _techniqueAccent,
                    onTap: () => setState(() => _puttStyle = style),
                  ),
                ),
              ),
            ),
            _buildMoreButton(
              accentColor: _techniqueAccent,
              onTap: () => _showEnumPicker<PuttStyle>(
                title: 'Select Putt Style',
                values: PuttStyle.values,
                nameMap: puttStyleToName,
                currentValue: _puttStyle,
                accentColor: _techniqueAccent,
                onSelect: (value) => setState(() => _puttStyle = value),
              ),
            ),
          ],
        ),
      );
    }

    // Otherwise show throw technique
    final List<ThrowTechnique> visibleOptions = [
      ThrowTechnique.backhand,
      ThrowTechnique.forehand,
    ];

    return _FieldCard(
      label: 'Technique',
      icon: Icons.style,
      accentColor: _techniqueAccent,
      child: Row(
        children: [
          ...visibleOptions.map(
            (technique) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildOptionButton(
                  label: throwTechniqueToName[technique] ?? technique.name,
                  isSelected: _technique == technique,
                  accentColor: _techniqueAccent,
                  onTap: () => setState(() => _technique = technique),
                ),
              ),
            ),
          ),
          _buildMoreButton(
            accentColor: _techniqueAccent,
            onTap: () => _showEnumPicker<ThrowTechnique>(
              title: 'Select Technique',
              values: ThrowTechnique.values,
              nameMap: throwTechniqueToName,
              currentValue: _technique,
              accentColor: _techniqueAccent,
              onSelect: (value) => setState(() => _technique = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandingSpotField() {
    final List<LandingSpot> visibleOptions = [
      LandingSpot.inBasket,
      LandingSpot.circle1,
      LandingSpot.circle2,
    ];

    return _FieldCard(
      label: 'Landing spot',
      icon: Icons.place,
      accentColor: _landingAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ...visibleOptions.map(
                (spot) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildOptionButton(
                      label: landingSpotToName[spot] ?? spot.name,
                      isSelected: _landingSpot == spot,
                      accentColor: _landingAccent,
                      onTap: () => setState(() => _landingSpot = spot),
                    ),
                  ),
                ),
              ),
              _buildMoreButton(
                accentColor: _landingAccent,
                onTap: () => _showEnumPicker<LandingSpot>(
                  title: 'Select Landing Spot',
                  values: LandingSpot.values,
                  nameMap: landingSpotToName,
                  currentValue: _landingSpot,
                  accentColor: _landingAccent,
                  onSelect: (value) => setState(() => _landingSpot = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLandingDistanceInput(),
        ],
      ),
    );
  }

  Widget _buildLandingDistanceInput() {
    // In Basket - show disabled message
    if (_landingSpot == LandingSpot.inBasket) {
      return Opacity(
        opacity: 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Colors.grey.shade500, size: 18),
              const SizedBox(width: 8),
              Text(
                'Distance not applicable for basket',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Circle 1 or Circle 2 - show slider
    if (_landingSpot == LandingSpot.circle1 ||
        _landingSpot == LandingSpot.circle2) {
      final int minDistance = _landingSpot == LandingSpot.circle1 ? 0 : 33;
      final int maxDistance = _landingSpot == LandingSpot.circle1 ? 33 : 66;

      // Initialize landing distance if null or out of range
      if (_landingDistance == null ||
          _landingDistance! < minDistance ||
          _landingDistance! > maxDistance) {
        _landingDistance = minDistance;
        _customLandingDistanceController.text = minDistance.toString();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Landing distance',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _landingAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _landingAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$_landingDistance ft',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _landingAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _landingAccent,
              inactiveTrackColor: flattenedOverWhite(_landingAccent, 0.2),
              thumbColor: _landingAccent,
              overlayColor: _landingAccent.withValues(alpha: 0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
              valueIndicatorColor: _landingAccent,
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Slider(
              value: _landingDistance!.toDouble(),
              min: minDistance.toDouble(),
              max: maxDistance.toDouble(),
              divisions: maxDistance - minDistance,
              label: '$_landingDistance ft',
              onChanged: (value) {
                setState(() {
                  _landingDistance = value.round();
                  _customLandingDistanceController.text = _landingDistance.toString();
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$minDistance ft',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                '$maxDistance ft',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      );
    }

    // Other landing spots - show text input
    return TextField(
      controller: _customLandingDistanceController,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: 'Landing distance (ft)',
        hintText: 'Enter distance',
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontStyle: FontStyle.italic,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: flattenedOverWhite(_landingAccent, 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: flattenedOverWhite(_landingAccent, 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _landingAccent, width: 2),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  Widget _buildOptionalFieldsToggle() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _showOptionalFields = !_showOptionalFields);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showOptionalFields ? Icons.remove : Icons.add,
              color: _generalAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _showOptionalFields ? 'Hide Fields' : 'More Fields',
              style: TextStyle(
                color: _generalAccent,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionalFields() {
    return Column(
      children: [
        // _buildDistanceField(
        //   label: '📏 DISTANCE BEFORE',
        //   controller: _customDistanceBeforeController,
        //   currentValue: _distanceBefore,
        //   onQuickSelect: (value) {
        //     setState(() => _distanceBefore = value);
        //     _customDistanceBeforeController.text = value.toString();
        //   },
        // ),
        // const SizedBox(height: 12),
        // _buildDistanceField(
        //   label: '📏 DISTANCE AFTER',
        //   controller: _customDistanceAfterController,
        //   currentValue: _distanceAfter,
        //   onQuickSelect: (value) {
        //     setState(() => _distanceAfter = value);
        //     _customDistanceAfterController.text = value.toString();
        //   },
        // ),
        // const SizedBox(height: 12),
        _buildResultRatingField(),
        const SizedBox(height: 12),
        _buildDiscTypeField(),
        const SizedBox(height: 12),
        _buildShotShapeField(),
        const SizedBox(height: 64),
      ],
    );
  }

  // Widget _buildDistanceField({
  //   required String label,
  //   required TextEditingController controller,
  //   required int? currentValue,
  //   required void Function(int) onQuickSelect,
  // }) {
  //   return _FieldCard(
  //     label: label,
  //     accentColor: _distanceAccent,
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.stretch,
  //       children: [
  //         Wrap(
  //           spacing: 8,
  //           runSpacing: 8,
  //           children: _quickDistances
  //               .map(
  //                 (distance) => _buildOptionButton(
  //                   label: '$distance ft',
  //                   isSelected: currentValue == distance,
  //                   accentColor: _distanceAccent,
  //                   onTap: () => onQuickSelect(distance),
  //                 ),
  //               )
  //               .toList(),
  //         ),
  //         const SizedBox(height: 12),
  //         TextField(
  //           controller: controller,
  //           decoration: const InputDecoration(
  //             labelText: 'Custom Distance',
  //             border: OutlineInputBorder(),
  //             isDense: true,
  //             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //           ),
  //           keyboardType: TextInputType.number,
  //           inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  //           onChanged: (value) {
  //             final int? parsed = int.tryParse(value);
  //             if (currentValue != parsed) {
  //               setState(() {
  //                 if (label.contains('BEFORE')) {
  //                   _distanceBefore = parsed;
  //                 } else {
  //                   _distanceAfter = parsed;
  //                 }
  //               });
  //             }
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildResultRatingField() {
    return _FieldCard(
      label: 'Result rating',
      icon: Icons.star,
      accentColor: _ratingAccent,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ThrowResultRating.values
            .map(
              (rating) => _buildOptionButton(
                label: throwResultRatingToName[rating] ?? rating.name,
                isSelected: _resultRating == rating,
                accentColor: _ratingAccent,
                onTap: () => setState(() => _resultRating = rating),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDiscTypeField() {
    final List<DGDisc> filteredDiscs = _userDiscs
        .where(
          (disc) => disc.name.toLowerCase().contains(
            _discSearchController.text.toLowerCase(),
          ),
        )
        .toList();

    return _FieldCard(
      label: 'Disc',
      icon: Icons.album,
      accentColor: _discAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _discSearchController,
            decoration: const InputDecoration(
              hintText: 'Type to search...',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              prefixIcon: Icon(Icons.search, size: 20),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (filteredDiscs.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: filteredDiscs
                    .map(
                      (disc) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildOptionButton(
                          label: disc.name,
                          isSelected: _discId == disc.id,
                          accentColor: _discAccent,
                          onTap: () => setState(() => _discId = disc.id),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShotShapeField() {
    final List<ShotShape> commonShapes = [
      ShotShape.hyzer,
      ShotShape.anhyzer,
      ShotShape.flat,
    ];

    return _FieldCard(
      label: 'Shot shape',
      icon: Icons.swap_horiz,
      accentColor: _shapeAccent,
      child: Row(
        children: [
          ...commonShapes.map(
            (shape) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildOptionButton(
                  label: shotShapeToName[shape] ?? shape.name,
                  isSelected: _shotShape == shape,
                  accentColor: _shapeAccent,
                  onTap: () => setState(() => _shotShape = shape),
                ),
              ),
            ),
          ),
          _buildMoreButton(
            accentColor: _shapeAccent,
            onTap: () => _showEnumPicker<ShotShape>(
              title: 'Select Shot Shape',
              values: ShotShape.values,
              nameMap: shotShapeToName,
              currentValue: _shotShape,
              accentColor: _shapeAccent,
              onSelect: (value) => setState(() => _shotShape = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    final bool canSave =
        _purpose != null &&
        _landingSpot != null &&
        (_purpose == ThrowPurpose.putt
            ? _puttStyle != null
            : _technique != null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.onDelete != null) ...[
            Expanded(
              child: PrimaryButton(
                label: 'Delete',
                width: double.infinity,
                height: 48,
                backgroundColor: Theme.of(context).colorScheme.surface,
                borderColor: Colors.red.withValues(alpha: 0.2),
                labelColor: Colors.red,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  FocusScope.of(context).unfocus();
                  widget.onDelete!();
                },
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: PrimaryButton(
              label: 'Save',
              width: double.infinity,
              height: 48,
              backgroundColor: TurbColors.blue,
              labelColor: Colors.white,
              disabled: !canSave,
              onPressed: _handleSave,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _buttonAccent : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? _buttonAccent
                : flattenedOverWhite(accentColor, 0.5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreButton({
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: flattenedOverWhite(accentColor, 0.15),
          border: Border.all(color: flattenedOverWhite(accentColor, 0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.expand_more, color: accentColor, size: 18),
      ),
    );
  }

  void _showEnumPicker<T>({
    required String title,
    required List<T> values,
    required Map<T, String> nameMap,
    required T? currentValue,
    required void Function(T) onSelect,
    required Color accentColor,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: values
                      .map(
                        (value) => _buildOptionButton(
                          label: nameMap[value] ?? value.toString(),
                          isSelected: currentValue == value,
                          accentColor: accentColor,
                          onTap: () {
                            onSelect(value);
                            Navigator.pop(context);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    // Parse distance values
    final int? distanceBefore = int.tryParse(
      _customDistanceBeforeController.text,
    );
    final int? distanceAfter = int.tryParse(
      _customDistanceAfterController.text,
    );

    // Find selected disc
    DGDisc? selectedDisc;
    if (_discId != null) {
      selectedDisc = _userDiscs.firstWhere(
        (disc) => disc.id == _discId,
        orElse: () => _userDiscs.first,
      );
    }

    // Create updated throw
    final DiscThrow updatedThrow = DiscThrow(
      index: widget.throwIndex,
      purpose: _purpose,
      technique: _technique,
      puttStyle: _puttStyle,
      shotShape: _shotShape,
      stance: widget.existingThrow?.stance,
      power: widget.existingThrow?.power,
      distanceFeetBeforeThrow: distanceBefore ?? _distanceBefore,
      distanceFeetAfterThrow: distanceAfter ?? _distanceAfter,
      elevationChangeFeet: widget.existingThrow?.elevationChangeFeet,
      windDirection: widget.existingThrow?.windDirection,
      windStrength: widget.existingThrow?.windStrength,
      resultRating: _resultRating,
      landingSpot: _landingSpot,
      fairwayWidth: widget.existingThrow?.fairwayWidth,
      customPenaltyStrokes: widget.existingThrow?.customPenaltyStrokes,
      notes: widget.existingThrow?.notes,
      rawText: widget.existingThrow?.rawText,
      parseConfidence: widget.existingThrow?.parseConfidence,
      discName: selectedDisc?.name,
      disc: selectedDisc,
    );

    widget.onSave(updatedThrow);
  }
}

/// Card widget with gradient background for field sections
class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.label,
    required this.child,
    required this.accentColor,
    required this.icon,
  });

  final String label;
  final Widget child;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          transform: GradientRotation(math.pi / 4),
          colors: [flattenedOverWhite(accentColor, 0.2), Colors.white],
        ),
        border: Border.all(color: flattenedOverWhite(accentColor, 0.3)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Circular icon container with radial gradient
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Colors.white, accentColor.withValues(alpha: 0.0)],
                    stops: const [0.6, 1.0],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
