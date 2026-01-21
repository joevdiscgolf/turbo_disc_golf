import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/add_disc_panel.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/disc_usage_stats_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
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
  static const String _panelName = 'Add Throw Panel';

  late BagService _bagService;
  late List<DGDisc> _userDiscs;
  late final LoggingServiceBase _logger;

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

  // Button accent color (consistent across all buttons)
  static const Color _buttonAccent = SenseiColors.blue;

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({'panel_name': _panelName});

    // Track modal opened
    _logger.track(
      'Modal Opened',
      properties: {
        'modal_type': 'bottom_sheet',
        'modal_name': _panelName,
        'is_new_throw': widget.isNewThrow,
        'throw_index': widget.throwIndex,
      },
    );

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
        decoration: BoxDecoration(
          color: SenseiColors.gray[50],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PanelHeader(
              title: widget.isNewThrow
                  ? 'Add Throw'
                  : 'Edit Throw ${widget.throwIndex + 1}',
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPurposeField(),
                    const SizedBox(height: 12),
                    _buildTechniqueField(),
                    const SizedBox(height: 12),
                    _buildLandingSpotField(),
                    const SizedBox(height: 12),
                    _buildDiscTypeField(),
                    const SizedBox(height: 12),
                    _buildShotShapeField(),
                    const SizedBox(height: 64),
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

  Widget _buildPurposeField() {
    final List<ThrowPurpose> visibleOptions = [
      ThrowPurpose.teeDrive,
      ThrowPurpose.approach,
      ThrowPurpose.putt,
    ];

    // Check if current selection is NOT in visible options
    final bool isOtherSelected =
        _purpose != null && !visibleOptions.contains(_purpose);

    void openPicker() => _showEnumPicker<ThrowPurpose>(
      title: 'Select Purpose',
      values: ThrowPurpose.values,
      nameMap: throwPurposeToName,
      currentValue: _purpose,
      onSelect: (value) {
        setState(() {
          _purpose = value;
          if (value == ThrowPurpose.putt && _puttStyle == null) {
            _puttStyle = PuttStyle.staggered;
          }
        });
      },
    );

    return _FieldCard(
      label: 'Purpose',
      icon: Icons.track_changes,
      child: isOtherSelected
          ? _buildSelectedValueDisplay(
              label: throwPurposeToName[_purpose] ?? _purpose!.name,
              onChangeTap: openPicker,
            )
          : Row(
              children: [
                ...visibleOptions.map(
                  (purpose) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildOptionButton(
                        label: throwPurposeToName[purpose] ?? purpose.name,
                        isSelected: _purpose == purpose,
                        onTap: () {
                          setState(() {
                            _purpose = purpose;
                            if (purpose == ThrowPurpose.putt &&
                                _puttStyle == null) {
                              _puttStyle = PuttStyle.staggered;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
                _buildMoreButton(onTap: openPicker),
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

      // Check if current selection is NOT in visible options
      final bool isOtherSelected =
          _puttStyle != null && !visibleOptions.contains(_puttStyle);

      void openPicker() => _showEnumPicker<PuttStyle>(
        title: 'Select Putt Style',
        values: PuttStyle.values,
        nameMap: puttStyleToName,
        currentValue: _puttStyle,
        onSelect: (value) => setState(() => _puttStyle = value),
      );

      return _FieldCard(
        label: 'Putt style',
        icon: Icons.golf_course,
        child: isOtherSelected
            ? _buildSelectedValueDisplay(
                label: puttStyleToName[_puttStyle] ?? _puttStyle!.name,
                onChangeTap: openPicker,
              )
            : Row(
                children: [
                  ...visibleOptions.map(
                    (style) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildOptionButton(
                          label: puttStyleToName[style] ?? style.name,
                          isSelected: _puttStyle == style,
                          onTap: () => setState(() => _puttStyle = style),
                        ),
                      ),
                    ),
                  ),
                  _buildMoreButton(onTap: openPicker),
                ],
              ),
      );
    }

    // Otherwise show throw technique
    final List<ThrowTechnique> visibleOptions = [
      ThrowTechnique.backhand,
      ThrowTechnique.forehand,
    ];

    // Check if current selection is NOT in visible options
    final bool isOtherSelected =
        _technique != null && !visibleOptions.contains(_technique);

    void openPicker() => _showEnumPicker<ThrowTechnique>(
      title: 'Select Technique',
      values: ThrowTechnique.values,
      nameMap: throwTechniqueToName,
      currentValue: _technique,
      onSelect: (value) => setState(() => _technique = value),
    );

    return _FieldCard(
      label: 'Technique',
      icon: Icons.style,
      child: isOtherSelected
          ? _buildSelectedValueDisplay(
              label: throwTechniqueToName[_technique] ?? _technique!.name,
              onChangeTap: openPicker,
            )
          : Row(
              children: [
                ...visibleOptions.map(
                  (technique) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildOptionButton(
                        label:
                            throwTechniqueToName[technique] ?? technique.name,
                        isSelected: _technique == technique,
                        onTap: () => setState(() => _technique = technique),
                      ),
                    ),
                  ),
                ),
                _buildMoreButton(onTap: openPicker),
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

    // Check if current selection is NOT in visible options
    final bool isOtherSelected =
        _landingSpot != null && !visibleOptions.contains(_landingSpot);

    void openPicker() => _showEnumPicker<LandingSpot>(
      title: 'Select Landing Spot',
      values: LandingSpot.values,
      nameMap: landingSpotToName,
      currentValue: _landingSpot,
      onSelect: (value) => setState(() => _landingSpot = value),
    );

    return _FieldCard(
      label: 'Landing spot',
      icon: Icons.place,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isOtherSelected)
            _buildSelectedValueDisplay(
              label: landingSpotToName[_landingSpot] ?? _landingSpot!.name,
              onChangeTap: openPicker,
            )
          else
            Row(
              children: [
                ...visibleOptions.map(
                  (spot) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildOptionButton(
                        label: landingSpotToName[spot] ?? spot.name,
                        isSelected: _landingSpot == spot,
                        onTap: () => setState(() => _landingSpot = spot),
                      ),
                    ),
                  ),
                ),
                _buildMoreButton(onTap: openPicker),
              ],
            ),
          const SizedBox(height: 12),
          _buildLandingDistanceInput(),
        ],
      ),
    );
  }

  Widget _buildLandingDistanceInput() {
    // Fixed height for consistent card size across all states
    const double fixedHeight = 56.0;

    // In Basket - show disabled message
    if (_landingSpot == LandingSpot.inBasket) {
      return SizedBox(
        height: fixedHeight,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              'Distance not applicable',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    // Parked, Circle 1, or Circle 2 - show sleek slider
    if (_landingSpot == LandingSpot.parked ||
        _landingSpot == LandingSpot.circle1 ||
        _landingSpot == LandingSpot.circle2) {
      final int minDistance = _landingSpot == LandingSpot.circle2 ? 33 : 0;
      final int maxDistance = _landingSpot == LandingSpot.parked
          ? 11
          : _landingSpot == LandingSpot.circle1
              ? 33
              : 66;

      // Initialize landing distance if null or out of range
      if (_landingDistance == null ||
          _landingDistance! < minDistance ||
          _landingDistance! > maxDistance) {
        _landingDistance = minDistance;
        _customLandingDistanceController.text = minDistance.toString();
      }

      return SizedBox(
        height: fixedHeight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _buttonAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _buttonAccent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              // Distance value display
              Container(
                width: 54,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: _buttonAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_landingDistance ft',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              // Slider
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: _buttonAccent,
                    inactiveTrackColor: _buttonAccent.withValues(alpha: 0.2),
                    thumbColor: _buttonAccent,
                    overlayColor: _buttonAccent.withValues(alpha: 0.15),
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: _landingDistance!.toDouble(),
                    min: minDistance.toDouble(),
                    max: maxDistance.toDouble(),
                    divisions: maxDistance - minDistance,
                    onChanged: (value) {
                      setState(() => _landingDistance = value.round());
                    },
                    onChangeEnd: (value) {
                      _customLandingDistanceController.text =
                          value.round().toString();
                    },
                  ),
                ),
              ),
              // Max label
              Text(
                '$maxDistance',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Other landing spots - show text input
    return SizedBox(
      height: fixedHeight,
      child: TextField(
        controller: _customLandingDistanceController,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Distance to basket',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
          ),
          suffixText: 'ft',
          suffixStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _buttonAccent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
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

  Widget _buildDiscTypeField() {
    final String searchText = _discSearchController.text.toLowerCase();
    final List<DGDisc> filteredDiscs = _userDiscs
        .where((disc) => disc.name.toLowerCase().contains(searchText))
        .toList();

    // Get recommended discs based on selected purpose
    final List<DGDisc> recommendedDiscs = _getRecommendedDiscs();

    // Check if search text doesn't match any disc (for "add new" option)
    final bool showAddNewOption =
        searchText.isNotEmpty && filteredDiscs.isEmpty;

    return _FieldCard(
      label: 'Disc',
      icon: Icons.album,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Recommended discs section (only show when purpose is selected)
          if (_purpose != null && recommendedDiscs.isNotEmpty) ...[
            _buildRecommendedDiscsSection(recommendedDiscs),
            const SizedBox(height: 12),
          ],
          // Search field
          TextField(
            controller: _discSearchController,
            decoration: InputDecoration(
              hintText: 'Search or add new disc...',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontStyle: FontStyle.italic,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: SenseiColors.blue, width: 2),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              prefixIcon: const Icon(Icons.search, size: 20),
            ),
            onChanged: (_) => setState(() {}),
          ),
          // Filtered disc list
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
                          onTap: () => setState(() => _discId = disc.id),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          // "Add new disc" button when search doesn't match
          if (showAddNewOption) ...[
            const SizedBox(height: 12),
            _buildAddNewDiscButton(_discSearchController.text.trim()),
          ],
        ],
      ),
    );
  }

  /// Get recommended discs based on the currently selected purpose
  List<DGDisc> _getRecommendedDiscs() {
    if (_purpose == null) return [];

    final DiscUsageStatsService statsService =
        locator.get<DiscUsageStatsService>();
    final List<String> recommendedIds = statsService.getRecommendedDiscIds(
      purpose: _purpose!,
      limit: 3,
    );

    // Convert IDs to DGDisc objects, filtering out any that aren't in the bag
    final List<DGDisc> recommendedDiscs = [];
    for (final String discId in recommendedIds) {
      final DGDisc? disc = _userDiscs
          .where((d) => d.id == discId)
          .cast<DGDisc?>()
          .firstOrNull;
      if (disc != null) {
        recommendedDiscs.add(disc);
      }
    }

    return recommendedDiscs;
  }

  /// Build the "Frequently used for [purpose]" section
  Widget _buildRecommendedDiscsSection(List<DGDisc> recommendedDiscs) {
    final String purposeName = throwPurposeToName[_purpose] ?? _purpose!.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, size: 14, color: Colors.amber.shade600),
            const SizedBox(width: 4),
            Text(
              'Frequently used for $purposeName',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: recommendedDiscs
              .map((disc) => _buildRecommendedDiscChip(disc))
              .toList(),
        ),
      ],
    );
  }

  /// Build a chip for a recommended disc
  Widget _buildRecommendedDiscChip(DGDisc disc) {
    final bool isSelected = _discId == disc.id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _discId = disc.id);
        _logger.track(
          'Recommended Disc Selected',
          properties: {
            'disc_id': disc.id,
            'disc_name': disc.name,
            'purpose': _purpose?.name,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _buttonAccent : Colors.amber.shade50,
          border: Border.all(
            color: isSelected ? _buttonAccent : Colors.amber.shade200,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: 12,
              color: isSelected ? Colors.white : Colors.amber.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              disc.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the "Add [name] to your bag" button
  Widget _buildAddNewDiscButton(String discName) {
    return GestureDetector(
      onTap: () => _showAddDiscPanel(discName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.add_circle, size: 20, color: Colors.green.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Add "$discName" to your bag',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.green.shade600),
          ],
        ),
      ),
    );
  }

  /// Show the AddDiscPanel bottom sheet
  void _showAddDiscPanel(String initialName) {
    _logger.track(
      'Add New Disc Button Tapped',
      properties: {'initial_name': initialName},
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddDiscPanel(
        initialName: initialName,
        onDiscAdded: (disc) {
          // Refresh the disc list and select the new disc
          setState(() {
            _userDiscs = _bagService.userBag;
            _discId = disc.id;
            _discSearchController.clear();
          });
        },
      ),
    );
  }

  Widget _buildShotShapeField() {
    final List<ShotShape> commonShapes = [
      ShotShape.hyzer,
      ShotShape.anhyzer,
      ShotShape.flat,
    ];

    // Check if current selection is NOT in visible options
    final bool isOtherSelected =
        _shotShape != null && !commonShapes.contains(_shotShape);

    void openPicker() => _showEnumPicker<ShotShape>(
      title: 'Select Shot Shape',
      values: ShotShape.values,
      nameMap: shotShapeToName,
      currentValue: _shotShape,
      onSelect: (value) => setState(() => _shotShape = value),
    );

    return _FieldCard(
      label: 'Shot shape',
      icon: Icons.swap_horiz,
      child: isOtherSelected
          ? _buildSelectedValueDisplay(
              label: shotShapeToName[_shotShape] ?? _shotShape!.name,
              onChangeTap: openPicker,
            )
          : Row(
              children: [
                ...commonShapes.map(
                  (shape) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildOptionButton(
                        label: shotShapeToName[shape] ?? shape.name,
                        isSelected: _shotShape == shape,
                        onTap: () => setState(() => _shotShape = shape),
                      ),
                    ),
                  ),
                ),
                _buildMoreButton(onTap: openPicker),
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
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: SenseiColors.gray[50],
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
                height: 56,
                backgroundColor: Colors.white,
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
              label: 'Add',
              width: double.infinity,
              height: 56,
              backgroundColor: SenseiColors.blue,
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
            color: isSelected ? _buttonAccent : Colors.grey.shade300,
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

  /// Full-width display for a selected "other" option with "Change" button
  Widget _buildSelectedValueDisplay({
    required String label,
    required VoidCallback onChangeTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChangeTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _buttonAccent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Change',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more,
              color: Colors.white.withValues(alpha: 0.8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.expand_more, color: Colors.grey.shade600, size: 18),
      ),
    );
  }

  void _showEnumPicker<T>({
    required String title,
    required List<T> values,
    required Map<T, String> nameMap,
    required T? currentValue,
    required void Function(T) onSelect,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < values.length; i++) ...[
                      _buildPickerRow(
                        label: nameMap[values[i]] ?? values[i].toString(),
                        isSelected: currentValue == values[i],
                        onTap: () {
                          onSelect(values[i]);
                          Navigator.pop(context);
                        },
                      ),
                      if (i < values.length - 1)
                        Divider(height: 1, color: Colors.grey.shade200),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerRow({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check, color: _buttonAccent, size: 22),
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

/// Card widget with clean white background for field sections
class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.label,
    required this.child,
    required this.icon,
  });

  final String label;
  final Widget child;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Simple icon container with subtle background
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: Colors.grey.shade600),
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
