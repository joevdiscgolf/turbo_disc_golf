import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Shared component for layout configuration (name, hole count, image parser).
/// Used by both CreateCourseSheet and CreateLayoutSheet.
class LayoutInfoSection extends StatelessWidget {
  const LayoutInfoSection({
    super.key,
    required this.headerTitle,
    required this.layoutName,
    required this.numberOfHoles,
    required this.isParsingImage,
    this.parseError,
    required this.onLayoutNameChanged,
    required this.onHoleCountChanged,
    required this.onParseImage,
  });

  /// The header title (e.g., "Default Layout" or "Layout")
  final String headerTitle;

  /// Current layout name
  final String layoutName;

  /// Current number of holes
  final int numberOfHoles;

  /// Whether image parsing is in progress
  final bool isParsingImage;

  /// Error message from image parsing
  final String? parseError;

  /// Callback when layout name changes
  final ValueChanged<String> onLayoutNameChanged;

  /// Callback when hole count changes
  final ValueChanged<int> onHoleCountChanged;

  /// Callback to trigger image parsing
  final VoidCallback onParseImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(headerTitle, Icons.grid_view, Colors.teal),
        const SizedBox(height: 12),
        TextField(
          onChanged: onLayoutNameChanged,
          decoration: const InputDecoration(labelText: 'Layout name'),
          controller: TextEditingController(text: layoutName)
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: layoutName.length),
            ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Number of holes',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        _buildHoleCountSelector(context),
        const SizedBox(height: 16),
        _buildImageParserButton(context),
        if (parseError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              parseError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildHoleCountSelector(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              style: ButtonStyle(
                side: WidgetStateProperty.all(
                  BorderSide(color: TurbColors.gray.shade300),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              segments: [
                ButtonSegment<int>(
                  value: 9,
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text('9', maxLines: 1),
                  ),
                ),
                ButtonSegment<int>(
                  value: 18,
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text('18', maxLines: 1),
                  ),
                ),
                ButtonSegment<int>(
                  value: 0,
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      numberOfHoles != 9 && numberOfHoles != 18
                          ? 'Custom ($numberOfHoles)'
                          : 'Custom',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              selected: {
                numberOfHoles == 9 || numberOfHoles == 18 ? numberOfHoles : 0,
              },
              onSelectionChanged: (Set<int> selection) {
                HapticFeedback.lightImpact();
                final int value = selection.first;
                if (value == 0) {
                  _showCustomHoleCountDialog(context);
                } else {
                  onHoleCountChanged(value);
                }
              },
            ),
          ),
          // Transparent overlay on custom segment to allow re-tapping
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showCustomHoleCountDialog(context);
              },
              child: Container(
                width: MediaQuery.of(context).size.width / 3 - 16,
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomHoleCountDialog(BuildContext context) async {
    // Track modal opened
    locator.get<LoggingService>().track('Modal Opened', properties: {
      'modal_type': 'dialog',
      'modal_name': 'Custom Hole Count',
    });

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
      onHoleCountChanged(customCount);
    }
  }

  Widget _buildImageParserButton(BuildContext context) {
    return GestureDetector(
      onTap: isParsingImage ? null : onParseImage,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TurbColors.gray.shade50,
          border: Border.all(color: TurbColors.gray.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isParsingImage ? Icons.hourglass_empty : Icons.camera_alt,
              color: TurbColors.gray.shade600,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isParsingImage ? 'Parsing Image...' : 'Upload scorecard image',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: TurbColors.gray.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Auto-fill par & distance from photo',
                    style: TextStyle(
                      fontSize: 12,
                      color: TurbColors.gray.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isParsingImage)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}
