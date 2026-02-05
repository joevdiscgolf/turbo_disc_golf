import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:turbo_disc_golf/components/form_analysis/pill_button_group.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';

/// Shared component for layout configuration (name, hole count).
/// Used by both CreateCourseSheet and CreateLayoutSheet.
class LayoutInfoSection extends StatefulWidget {
  const LayoutInfoSection({
    super.key,
    required this.headerTitle,
    required this.layoutName,
    required this.numberOfHoles,
    required this.onLayoutNameChanged,
    required this.onHoleCountChanged,
    this.hasNameConflict = false,
  });

  /// The header title (e.g., "Default Layout" or "Layout")
  final String headerTitle;

  /// Current layout name
  final String layoutName;

  /// Current number of holes
  final int numberOfHoles;

  /// Callback when layout name changes
  final ValueChanged<String> onLayoutNameChanged;

  /// Callback when hole count changes
  final ValueChanged<int> onHoleCountChanged;

  /// Whether the layout name conflicts with an existing layout
  final bool hasNameConflict;

  @override
  State<LayoutInfoSection> createState() => _LayoutInfoSectionState();
}

class _LayoutInfoSectionState extends State<LayoutInfoSection> {
  @override
  Widget build(BuildContext context) {
    final Color errorColor = Theme.of(context).colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(widget.headerTitle),
        const SizedBox(height: 12),
        TextField(
          onChanged: widget.onLayoutNameChanged,
          decoration: InputDecoration(
            labelText: 'Layout name',
            enabledBorder: widget.hasNameConflict
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: errorColor, width: 1.5),
                  )
                : null,
            focusedBorder: widget.hasNameConflict
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: errorColor, width: 2),
                  )
                : null,
            labelStyle: widget.hasNameConflict
                ? TextStyle(color: errorColor)
                : null,
          ),
          controller: TextEditingController(text: widget.layoutName)
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: widget.layoutName.length),
            ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topLeft,
          child: widget.hasNameConflict
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Text(
                    'Layout name must be unique',
                    style: TextStyle(color: errorColor, fontSize: 12),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        const Text(
          'Number of holes',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        _buildHoleCountSelector(context),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    );
  }

  Widget _buildHoleCountSelector(BuildContext context) {
    final bool is9Selected = widget.numberOfHoles == 9;
    final bool is18Selected = widget.numberOfHoles == 18;
    final bool isCustomSelected = !is9Selected && !is18Selected;
    final String customLabel = isCustomSelected
        ? 'Custom (${widget.numberOfHoles})'
        : 'Custom';

    return PillButtonGroup(
      isDark: false,
      height: 44,
      buttons: [
        PillButtonData(
          label: '9',
          isSelected: is9Selected,
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onHoleCountChanged(9);
          },
        ),
        PillButtonData(
          label: '18',
          isSelected: is18Selected,
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onHoleCountChanged(18);
          },
        ),
        PillButtonData(
          label: customLabel,
          isSelected: isCustomSelected,
          onTap: () {
            HapticFeedback.lightImpact();
            _showCustomHoleCountDialog(context);
          },
        ),
      ],
    );
  }

  Future<void> _showCustomHoleCountDialog(BuildContext context) async {
    // Track modal opened
    locator.get<LoggingService>().track(
      'Modal Opened',
      properties: {'modal_type': 'dialog', 'modal_name': 'Custom Hole Count'},
    );

    final TextEditingController controller = TextEditingController();
    final int? customCount = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Hole Count'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of holes',
            hintText: 'Enter 1-99',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final int? value = int.tryParse(controller.text);
              if (value != null && value >= 1 && value <= 99) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (customCount != null) {
      widget.onHoleCountChanged(customCount);
    }
  }
}
