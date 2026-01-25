import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A single item in the checkpoint selector.
class CheckpointSelectorItem {
  const CheckpointSelectorItem({
    required this.id,
    required this.label,
  });

  /// Unique identifier for this checkpoint.
  final String id;

  /// Display label for this checkpoint.
  final String label;
}

/// A generic reusable checkpoint selector component.
///
/// Displays a horizontal segmented control with selectable items.
/// Used in form analysis views to switch between checkpoints.
class CheckpointSelector extends StatelessWidget {
  const CheckpointSelector({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.formatLabel,
  });

  /// The list of items to display.
  final List<CheckpointSelectorItem> items;

  /// The currently selected index.
  final int selectedIndex;

  /// Callback when selection changes.
  final ValueChanged<int> onChanged;

  /// Optional function to format labels (e.g., remove " Position" suffix).
  final String Function(String)? formatLabel;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final String label = formatLabel != null
              ? formatLabel!(items[index].label)
              : items[index].label;
          return Expanded(
            child: _buildTabSegment(
              label,
              index == selectedIndex,
              () {
                HapticFeedback.selectionClick();
                onChanged(index);
              },
              isFirst: index == 0,
              isLast: index == items.length - 1,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabSegment(
    String name,
    bool isSelected,
    VoidCallback onTap, {
    required bool isFirst,
    required bool isLast,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8B5CF6), Color(0xFF6B4EFF)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: isFirst ? const Radius.circular(11) : Radius.zero,
            bottomLeft: isFirst ? const Radius.circular(11) : Radius.zero,
            topRight: isLast ? const Radius.circular(11) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(11) : Radius.zero,
          ),
        ),
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
