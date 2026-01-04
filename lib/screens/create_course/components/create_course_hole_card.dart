import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

/// Compact card widget for displaying and editing a single hole
class CrateCourseHoleCard extends StatelessWidget {
  const CrateCourseHoleCard({
    super.key,
    required this.hole,
    required this.onParChanged,
    required this.onFeetChanged,
    required this.onTypeChanged,
  });

  final CourseHole hole;
  final void Function(int) onParChanged;
  final void Function(int) onFeetChanged;
  final void Function(HoleType) onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // gradient: LinearGradient(
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        //   colors: [
        //     flattenedOverWhite(const Color(0xFF64B5F6), 0.10),
        //     flattenedOverWhite(const Color(0xFF1565C0), 0.05),
        //     // flattenedOverWhite(const Color(0xFFE8F5E9), 0.6),
        //     // flattenedOverWhite(const Color(0xFFC8E6C9), 0.1),
        //   ],
        // ),
        color: Colors.white,
        // borderRadius: BorderRadius.circular(12),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: 0.05),
        //     offset: Offset(0, 4),
        //     blurRadius: 8,
        //     spreadRadius: 0,
        //   ),
        // ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Hole number
            SizedBox(
              width: 24,
              child: Text(
                '${hole.holeNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Par field
            Expanded(
              flex: 1,
              child: _CompactNumberField(
                label: 'Par',
                value: hole.par,
                onChanged: onParChanged,
              ),
            ),
            const SizedBox(width: 8),
            // Feet field
            Expanded(
              flex: 2,
              child: _CompactNumberField(
                label: 'Feet',
                value: hole.feet,
                onChanged: onFeetChanged,
              ),
            ),
            const SizedBox(width: 8),
            // Hole type selector
            _HoleTypeCompact(
              selectedType: hole.holeType ?? HoleType.open,
              onTypeChanged: onTypeChanged,
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
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('$label-$value'), // Force rebuild when value changes
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.7),
      ),
      onChanged: (v) {
        final int? parsed = int.tryParse(v);
        if (parsed != null) onChanged(parsed);
      },
    );
  }
}

/// Compact hole type dropdown selector
class _HoleTypeCompact extends StatelessWidget {
  const _HoleTypeCompact({
    required this.selectedType,
    required this.onTypeChanged,
  });

  final HoleType selectedType;
  final void Function(HoleType) onTypeChanged;

  String _getIcon(HoleType type) {
    switch (type) {
      case HoleType.open:
        return '🌳';
      case HoleType.slightlyWooded:
        return '🌲';
      case HoleType.wooded:
        return '🌲🌲';
    }
  }

  String _getLabel(HoleType type) {
    switch (type) {
      case HoleType.open:
        return 'Open';
      case HoleType.slightlyWooded:
        return 'Mod';
      case HoleType.wooded:
        return 'Wood';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: DropdownButton<HoleType>(
          value: selectedType,
          isDense: true,
          underline: const SizedBox(),
          iconSize: 16, // Smaller dropdown arrow
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          items: HoleType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                '${_getIcon(type)} ${_getLabel(type)}',
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (HoleType? value) {
            if (value != null) onTypeChanged(value);
          },
        ),
      ),
    );
  }
}
