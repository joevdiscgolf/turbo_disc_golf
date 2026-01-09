import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:turbo_disc_golf/models/data/throw_data.dart';

/// Callback type for applying default values to all holes
typedef ApplyDefaultsCallback = void Function({
  required int defaultPar,
  required int defaultFeet,
  required HoleType defaultType,
  required HoleShape defaultShape,
});

class QuickFillHolesCard extends StatefulWidget {
  const QuickFillHolesCard({
    super.key,
    required this.onApplyDefaults,
  });

  /// Callback to apply default values to all holes
  final ApplyDefaultsCallback onApplyDefaults;

  @override
  State<QuickFillHolesCard> createState() => _QuickFillHolesCardState();
}

class _QuickFillHolesCardState extends State<QuickFillHolesCard> {
  int quickFillPar = 3;
  int quickFillFeet = 300;
  HoleType quickFillType = HoleType.slightlyWooded;
  HoleShape quickFillShape = HoleShape.straight;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: const Text(
              'Quick Fill',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: const Text(
              'Set default values for all holes',
              style: TextStyle(fontSize: 12),
            ),
            initiallyExpanded: false,
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            iconColor: Colors.grey,
            collapsedIconColor: Colors.grey,
            onExpansionChanged: (_) => HapticFeedback.lightImpact(),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildParAndFeetRow(),
                    const SizedBox(height: 16),
                    _buildTightnessSelector(),
                    const SizedBox(height: 12),
                    _buildShapeSelector(),
                    const SizedBox(height: 16),
                    _buildApplyButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParAndFeetRow() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextFormField(
              initialValue: quickFillPar.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Par',
                contentPadding: EdgeInsets.fromLTRB(12, 8, 12, 8),
              ),
              onChanged: (v) {
                final int? parsed = int.tryParse(v);
                if (parsed != null) {
                  setState(() => quickFillPar = parsed);
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextFormField(
              initialValue: quickFillFeet.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Distance (ft)',
                contentPadding: EdgeInsets.fromLTRB(12, 8, 12, 8),
              ),
              onChanged: (v) {
                final int? parsed = int.tryParse(v);
                if (parsed != null) {
                  setState(() => quickFillFeet = parsed);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTightnessSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tightness',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _IconToggleButton(
                icon: Icons.circle_outlined,
                label: 'Open',
                isSelected: quickFillType == HoleType.open,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => quickFillType = HoleType.open);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _IconToggleButton(
                icon: Icons.contrast,
                label: 'Mod',
                isSelected: quickFillType == HoleType.slightlyWooded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => quickFillType = HoleType.slightlyWooded);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _IconToggleButton(
                icon: Icons.circle,
                label: 'Tight',
                isSelected: quickFillType == HoleType.wooded,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => quickFillType = HoleType.wooded);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShapeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shape',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _IconToggleButton(
                icon: Icons.turn_left,
                label: 'Left',
                isSelected: quickFillShape == HoleShape.doglegLeft,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => quickFillShape = HoleShape.doglegLeft);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _IconToggleButton(
                icon: Icons.arrow_upward,
                label: 'Str',
                isSelected: quickFillShape == HoleShape.straight,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => quickFillShape = HoleShape.straight);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _IconToggleButton(
                icon: Icons.turn_right,
                label: 'Right',
                isSelected: quickFillShape == HoleShape.doglegRight,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => quickFillShape = HoleShape.doglegRight);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApplyButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onApplyDefaults(
            defaultPar: quickFillPar,
            defaultFeet: quickFillFeet,
            defaultType: quickFillType,
            defaultShape: quickFillShape,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Applied defaults to all holes'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            'Apply to all',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact icon toggle button for tightness and shape selection
class _IconToggleButton extends StatelessWidget {
  const _IconToggleButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF137e66).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF137e66)
                : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? const Color(0xFF137e66)
                  : Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF137e66)
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
