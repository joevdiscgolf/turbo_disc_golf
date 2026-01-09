import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

/// Ultra-compact card widget for displaying and editing a single hole
/// Single row layout with inline icon-button selectors for tightness and shape
class CreateCourseHoleCard extends StatelessWidget {
  const CreateCourseHoleCard({
    super.key,
    required this.hole,
    required this.onParChanged,
    required this.onFeetChanged,
    required this.onTypeChanged,
    required this.onShapeChanged,
  });

  final CourseHole hole;
  final void Function(int) onParChanged;
  final void Function(int) onFeetChanged;
  final void Function(HoleType) onTypeChanged;
  final void Function(HoleShape) onShapeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            // Hole number
            SizedBox(
              width: 20,
              child: Text(
                '${hole.holeNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Par field
            SizedBox(
              width: 36,
              child: _CompactNumberField(
                value: hole.par,
                onChanged: onParChanged,
              ),
            ),
            const SizedBox(width: 8),
            // Feet field
            SizedBox(
              width: 52,
              child: _CompactNumberField(
                value: hole.feet,
                onChanged: onFeetChanged,
              ),
            ),
            const SizedBox(width: 12),
            // Tightness selector
            Expanded(
              child: _TightnessSelector(
                selected: hole.holeType ?? HoleType.slightlyWooded,
                onChanged: onTypeChanged,
              ),
            ),
            const SizedBox(width: 10),
            // Shape selector
            Expanded(
              child: _ShapeSelector(
                selected: hole.holeShape ?? HoleShape.straight,
                onChanged: onShapeChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact number input field for par and distance
class _CompactNumberField extends StatelessWidget {
  const _CompactNumberField({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('field-$value'),
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      onChanged: (v) {
        final int? parsed = int.tryParse(v);
        if (parsed != null) onChanged(parsed);
      },
    );
  }
}

/// Inline tightness selector with 3 icon buttons
class _TightnessSelector extends StatelessWidget {
  const _TightnessSelector({
    required this.selected,
    required this.onChanged,
  });

  final HoleType selected;
  final void Function(HoleType) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CompactIconButton(
            icon: Icons.circle_outlined,
            isSelected: selected == HoleType.open,
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(HoleType.open);
            },
            semanticLabel: 'Open',
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: _CompactIconButton(
            icon: Icons.contrast,
            isSelected: selected == HoleType.slightlyWooded,
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(HoleType.slightlyWooded);
            },
            semanticLabel: 'Moderate',
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: _CompactIconButton(
            icon: Icons.circle,
            isSelected: selected == HoleType.wooded,
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(HoleType.wooded);
            },
            semanticLabel: 'Tight',
          ),
        ),
      ],
    );
  }
}

/// Inline shape selector with 3 icon buttons
class _ShapeSelector extends StatelessWidget {
  const _ShapeSelector({
    required this.selected,
    required this.onChanged,
  });

  final HoleShape selected;
  final void Function(HoleShape) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CompactIconButton(
            icon: Icons.turn_left,
            isSelected: selected == HoleShape.doglegLeft,
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(HoleShape.doglegLeft);
            },
            semanticLabel: 'Dogleg Left',
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: _CompactIconButton(
            icon: Icons.arrow_upward,
            isSelected: selected == HoleShape.straight,
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(HoleShape.straight);
            },
            semanticLabel: 'Straight',
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: _CompactIconButton(
            icon: Icons.turn_right,
            isSelected: selected == HoleShape.doglegRight,
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(HoleShape.doglegRight);
            },
            semanticLabel: 'Dogleg Right',
          ),
        ),
      ],
    );
  }
}

/// Compact icon button that fills available width
class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String semanticLabel;

  static const Color _selectedColor = Color(0xFF137e66);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? _selectedColor.withValues(alpha: 0.15)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? _selectedColor : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 14,
                color: isSelected ? _selectedColor : Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header row for the holes list showing column labels
class CreateCourseHoleHeader extends StatelessWidget {
  const CreateCourseHoleHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle headerStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade600,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 20, child: Text('#', style: headerStyle)),
            const SizedBox(width: 4),
            SizedBox(
              width: 36,
              child: Text('Par', style: headerStyle, textAlign: TextAlign.center),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 52,
              child: Text('Feet', style: headerStyle, textAlign: TextAlign.center),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Tightness', style: headerStyle, textAlign: TextAlign.center),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Shape', style: headerStyle, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
