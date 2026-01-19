import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/utils/constants/naming_constants.dart';

/// Dialog for editing or adding a throw with all available fields.
///
/// Provides form inputs for all throw properties including required fields
/// (purpose, technique, distances) and optional fields (shot shape, power, etc.).
class ThrowEditDialog extends StatefulWidget {
  const ThrowEditDialog({
    super.key,
    required DiscThrow throw_,
    required this.throwIndex,
    required this.onSave,
    this.onDelete,
    this.isNewThrow = false,
  }) : _throw = throw_;

  final DiscThrow _throw;
  final int throwIndex;
  final void Function(DiscThrow) onSave;
  final VoidCallback? onDelete;
  final bool isNewThrow;

  @override
  State<ThrowEditDialog> createState() => _ThrowEditDialogState();
}

class _ThrowEditDialogState extends State<ThrowEditDialog> {
  static const String _modalName = 'Throw Edit Dialog';

  late BagService _bagService;
  late List<DGDisc> _userDiscs;
  late final LoggingServiceBase _logger;

  // Form controllers
  late ThrowPurpose? _purpose;
  late ThrowTechnique? _technique;
  late TextEditingController _distanceBeforeController;
  late TextEditingController _distanceAfterController;
  late LandingSpot? _landingSpot;
  late ThrowResultRating? _resultRating;
  late String? _discId;
  late ShotShape? _shotShape;
  late ThrowPower? _power;
  late StanceType? _stance;
  late PuttStyle? _puttStyle;
  late FairwayWidth? _fairwayWidth;
  late TextEditingController _elevationController;
  late WindDirection? _windDirection;
  late WindStrength? _windStrength;
  late TextEditingController _penaltyController;
  late TextEditingController _notesController;

  bool _showOptionalFields = false;

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'modal_name': _modalName,
    });

    // Track modal opened
    _logger.track('Modal Opened', properties: {
      'modal_type': 'dialog',
      'modal_name': _modalName,
      'is_new_throw': widget.isNewThrow,
      'throw_index': widget.throwIndex,
    });

    _bagService = locator.get<BagService>();
    _userDiscs = _bagService.userBag;

    // Initialize form values from throw
    _purpose = widget._throw.purpose;
    _technique = widget._throw.technique;
    _distanceBeforeController = TextEditingController(
      text: widget._throw.distanceFeetBeforeThrow?.toString() ?? '',
    );
    _distanceAfterController = TextEditingController(
      text: widget._throw.distanceFeetAfterThrow?.toString() ?? '',
    );
    _landingSpot = widget._throw.landingSpot;
    _resultRating = widget._throw.resultRating;
    _discId = widget._throw.disc?.id;
    _shotShape = widget._throw.shotShape;
    _power = widget._throw.power;
    _stance = widget._throw.stance;
    _puttStyle = widget._throw.puttStyle;
    _fairwayWidth = widget._throw.fairwayWidth;
    _elevationController = TextEditingController(
      text: widget._throw.elevationChangeFeet?.toString() ?? '',
    );
    _windDirection = widget._throw.windDirection;
    _windStrength = widget._throw.windStrength;
    _penaltyController = TextEditingController(
      text: widget._throw.customPenaltyStrokes?.toString() ?? '',
    );
    _notesController = TextEditingController(text: widget._throw.notes ?? '');
  }

  @override
  void dispose() {
    _distanceBeforeController.dispose();
    _distanceAfterController.dispose();
    _elevationController.dispose();
    _penaltyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    // Unfocus any text fields to dismiss keyboard
    FocusScope.of(context).unfocus();

    // Parse distances
    final int? distanceBefore = int.tryParse(_distanceBeforeController.text);
    final int? distanceAfter = int.tryParse(_distanceAfterController.text);
    final double? elevation = double.tryParse(_elevationController.text);
    final int? penalty = int.tryParse(_penaltyController.text);

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
      index: widget._throw.index,
      purpose: _purpose,
      technique: _technique,
      puttStyle: _puttStyle,
      shotShape: _shotShape,
      stance: _stance,
      power: _power,
      distanceFeetBeforeThrow: distanceBefore,
      distanceFeetAfterThrow: distanceAfter,
      elevationChangeFeet: elevation,
      windDirection: _windDirection,
      windStrength: _windStrength,
      resultRating: _resultRating,
      landingSpot: _landingSpot,
      fairwayWidth: _fairwayWidth,
      customPenaltyStrokes: penalty,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      rawText: widget._throw.rawText,
      parseConfidence: widget._throw.parseConfidence,
      discName: selectedDisc?.name,
      disc: selectedDisc,
    );

    widget.onSave(updatedThrow);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isNewThrow
                        ? 'Add Throw'
                        : 'Edit Throw ${widget.throwIndex + 1}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),

            // Scrollable form content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Purpose
                    _buildDropdown<ThrowPurpose>(
                      label: 'Purpose',
                      value: _purpose,
                      items: ThrowPurpose.values,
                      nameMap: throwPurposeToName,
                      onChanged: (value) => setState(() => _purpose = value),
                    ),
                    const SizedBox(height: 16),

                    // Technique
                    _buildDropdown<ThrowTechnique>(
                      label: 'Technique',
                      value: _technique,
                      items: ThrowTechnique.values,
                      nameMap: throwTechniqueToName,
                      onChanged: (value) => setState(() => _technique = value),
                    ),
                    const SizedBox(height: 16),

                    // Distance before
                    _buildNumberField(
                      label: 'Distance Before Throw (ft)',
                      controller: _distanceBeforeController,
                    ),
                    const SizedBox(height: 16),

                    // Distance after
                    _buildNumberField(
                      label: 'Distance After Throw (ft)',
                      controller: _distanceAfterController,
                    ),
                    const SizedBox(height: 16),

                    // Landing spot (required)
                    _buildDropdown<LandingSpot>(
                      label: 'Landing Spot',
                      value: _landingSpot,
                      items: LandingSpot.values,
                      nameMap: landingSpotToName,
                      onChanged: (value) =>
                          setState(() => _landingSpot = value),
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    // Result rating
                    _buildDropdown<ThrowResultRating>(
                      label: 'Result Rating',
                      value: _resultRating,
                      items: ThrowResultRating.values,
                      nameMap: throwResultRatingToName,
                      onChanged: (value) =>
                          setState(() => _resultRating = value),
                    ),
                    const SizedBox(height: 16),

                    // Disc selection
                    _buildDiscDropdown(),
                    const SizedBox(height: 16),

                    // Shot shape
                    _buildDropdown<ShotShape>(
                      label: 'Shot Shape',
                      value: _shotShape,
                      items: ShotShape.values,
                      nameMap: shotShapeToName,
                      onChanged: (value) => setState(() => _shotShape = value),
                    ),
                    const SizedBox(height: 16),

                    // Power
                    _buildDropdown<ThrowPower>(
                      label: 'Power',
                      value: _power,
                      items: ThrowPower.values,
                      nameMap: throwPowerToName,
                      onChanged: (value) => setState(() => _power = value),
                    ),
                    const SizedBox(height: 16),

                    // Stance
                    _buildDropdown<StanceType>(
                      label: 'Stance',
                      value: _stance,
                      items: StanceType.values,
                      nameMap: stanceTypeToName,
                      onChanged: (value) => setState(() => _stance = value),
                    ),
                    const SizedBox(height: 24),

                    // Optional fields section
                    ExpansionTile(
                      title: const Text('Optional Details'),
                      initiallyExpanded: _showOptionalFields,
                      onExpansionChanged: (expanded) {
                        setState(() => _showOptionalFields = expanded);
                      },
                      children: [
                        // Putt style
                        _buildDropdown<PuttStyle>(
                          label: 'Putt Style',
                          value: _puttStyle,
                          items: PuttStyle.values,
                          nameMap: puttStyleToName,
                          onChanged: (value) =>
                              setState(() => _puttStyle = value),
                        ),
                        const SizedBox(height: 16),

                        // Fairway width
                        _buildDropdown<FairwayWidth>(
                          label: 'Fairway Width',
                          value: _fairwayWidth,
                          items: FairwayWidth.values,
                          nameMap: fairwayWidthToName,
                          onChanged: (value) =>
                              setState(() => _fairwayWidth = value),
                        ),
                        const SizedBox(height: 16),

                        // Elevation
                        _buildNumberField(
                          label: 'Elevation Change (ft)',
                          controller: _elevationController,
                          allowDecimal: true,
                        ),
                        const SizedBox(height: 16),

                        // Wind direction
                        _buildDropdown<WindDirection>(
                          label: 'Wind Direction',
                          value: _windDirection,
                          items: WindDirection.values,
                          nameMap: windDirectionToName,
                          onChanged: (value) =>
                              setState(() => _windDirection = value),
                        ),
                        const SizedBox(height: 16),

                        // Wind strength
                        _buildDropdown<WindStrength>(
                          label: 'Wind Strength',
                          value: _windStrength,
                          items: WindStrength.values,
                          nameMap: windStrengthToName,
                          onChanged: (value) =>
                              setState(() => _windStrength = value),
                        ),
                        const SizedBox(height: 16),

                        // Penalty strokes
                        _buildNumberField(
                          label: 'Penalty Strokes',
                          controller: _penaltyController,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                        hintText: 'Add any additional notes...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Delete button (only for existing throws)
                  if (widget.onDelete != null)
                    TextButton.icon(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        widget.onDelete!();
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Cancel and Save buttons
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _save,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required Map<T, String> nameMap,
    required void Function(T?) onChanged,
    bool isRequired = false,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        label: isRequired
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  const Text(' *', style: TextStyle(color: Colors.red)),
                ],
              )
            : Text(label),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(nameMap[item] ?? item.toString()),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDiscDropdown() {
    if (_userDiscs.isEmpty) {
      return TextField(
        decoration: const InputDecoration(
          labelText: 'Disc',
          border: OutlineInputBorder(),
          enabled: false,
        ),
        controller: TextEditingController(text: 'No discs available'),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _discId,
      decoration: const InputDecoration(
        labelText: 'Disc',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('None')),
        ..._userDiscs.map((disc) {
          return DropdownMenuItem<String>(
            value: disc.id,
            child: Text(disc.name),
          );
        }),
      ],
      onChanged: (value) => setState(() => _discId = value),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    bool allowDecimal = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: allowDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: [
        if (allowDecimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\-?\d*\.?\d*'))
        else
          FilteringTextInputFormatter.allow(RegExp(r'^\-?\d*')),
      ],
    );
  }
}
