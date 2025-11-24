import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

/// A guided, step-by-step dialog for creating a throw.
/// Automatically advances through required fields:
/// 1. Purpose (always required)
/// 2. Technique (skipped if purpose == ThrowPurpose.putt)
/// 3. Landing spot (always required)
class AddThrowWalkthroughDialog extends StatefulWidget {
  const AddThrowWalkthroughDialog({
    super.key,
    required this.onComplete,
    required this.throwIndex,
  });

  final void Function(DiscThrow throwData, int throwIndex) onComplete;
  final int throwIndex;

  @override
  State<AddThrowWalkthroughDialog> createState() =>
      _AddThrowWalkthroughDialogState();
}

class _AddThrowWalkthroughDialogState extends State<AddThrowWalkthroughDialog> {
  ThrowPurpose? _purpose;
  ThrowTechnique? _technique;
  LandingSpot? _landingSpot;

  int _step = 0; // 0 = purpose, 1 = technique (maybe skipped), 2 = landing

  void _handlePurposeSelected(ThrowPurpose value) {
    setState(() {
      _purpose = value;

      // Skip technique if putting
      if (value == ThrowPurpose.putt) {
        _step = 2; // jump directly to landing spot
      } else {
        _step = 1;
      }
    });
  }

  void _handleTechniqueSelected(ThrowTechnique value) {
    setState(() {
      _technique = value;
      _step = 2;
    });
  }

  void _handleLandingSelected(LandingSpot selectedLandingSpot) {
    setState(() {
      _landingSpot = selectedLandingSpot;
    });

    final throwData = DiscThrow(
      purpose: _purpose!,
      technique: _purpose == ThrowPurpose.putt ? null : _technique,
      landingSpot: _landingSpot!,
      index: widget.throwIndex,
    );

    widget.onComplete(throwData, widget.throwIndex);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_step == 0) _buildPurposeStep(),
            if (_step == 1) _buildTechniqueStep(),
            if (_step == 2) _buildLandingStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildPurposeStep() {
    return _StepWrapper(
      title: "What was the purpose of this throw?",
      child: Wrap(
        spacing: 8,
        children: ThrowPurpose.values.map((p) {
          return ChoiceChip(
            label: Text(_labelForPurpose(p)),
            selected: _purpose == p,
            onSelected: (_) => _handlePurposeSelected(p),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTechniqueStep() {
    return _StepWrapper(
      title: "Which technique did you use?",
      child: Wrap(
        spacing: 8,
        children: ThrowTechnique.values.map((t) {
          return ChoiceChip(
            label: Text(_labelForTechnique(t)),
            selected: _technique == t,
            onSelected: (_) => _handleTechniqueSelected(t),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLandingStep() {
    return _StepWrapper(
      title: "Where did the disc land?",
      child: Wrap(
        spacing: 8,
        children: LandingSpot.values.map((spot) => _landingChip(spot)).toList(),
      ),
    );
  }

  Widget _landingChip(LandingSpot landingSpot) {
    return ChoiceChip(
      label: Text(landingSpot.name),
      selected: _landingSpot == landingSpot,
      onSelected: (_) => _handleLandingSelected(landingSpot),
    );
  }

  String _labelForPurpose(ThrowPurpose p) {
    switch (p) {
      case ThrowPurpose.teeDrive:
        return "Tee Drive";
      case ThrowPurpose.fairwayDrive:
        return "Fairway Drive";
      case ThrowPurpose.approach:
        return "Approach";
      case ThrowPurpose.putt:
        return "Putt";
      case ThrowPurpose.scramble:
        return "Scramble";
      case ThrowPurpose.penalty:
        return "Penalty";
      case ThrowPurpose.other:
        return "Other";
    }
  }

  String _labelForTechnique(ThrowTechnique t) {
    switch (t) {
      case ThrowTechnique.backhand:
        return "Backhand";
      case ThrowTechnique.forehand:
        return "Forehand";
      case ThrowTechnique.tomahawk:
        return "Tomahawk";
      case ThrowTechnique.thumber:
        return "Thumber";
      case ThrowTechnique.overhand:
        return "Overhand";
      case ThrowTechnique.backhandRoller:
        return "BH Roller";
      case ThrowTechnique.forehandRoller:
        return "FH Roller";
      case ThrowTechnique.grenade:
        return "Grenade";
      case ThrowTechnique.other:
        return "Other";
    }
  }
}

class _StepWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const _StepWrapper({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}
