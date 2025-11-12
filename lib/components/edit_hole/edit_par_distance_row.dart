import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class EditParDistanceRow extends StatelessWidget {
  const EditParDistanceRow({
    super.key,
    required this.par,
    required this.distance,
    required this.strokes,
    required this.onParChanged,
    required this.onDistanceChanged,
    required this.parFocusNode,
    required this.distanceFocusNode,
    required this.parController,
    required this.distanceController,
  });

  final int par;
  final int distance;
  final int strokes;
  final Function(int) onParChanged;
  final Function(int) onDistanceChanged;
  final FocusNode parFocusNode;
  final FocusNode distanceFocusNode;
  final TextEditingController parController;
  final TextEditingController distanceController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _editableInfoCard(
              context,
              'Par',
              parFocusNode,
              Icons.flag_outlined,
              onChanged: onParChanged,
              controller: parController,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _editableInfoCard(
              context,
              'Distance',
              distanceFocusNode,
              Icons.straighten,
              suffix: 'ft',
              onChanged: onDistanceChanged,
              controller: distanceController,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _staticInfoCard(context, 'Throws', '$strokes')),
        ],
      ),
    );
  }

  Widget _staticInfoCard(BuildContext context, String label, String value) {
    return SizedBox(
      height: 80,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: TurbColors.gray[50]!),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editableInfoCard(
    BuildContext context,
    String label,
    FocusNode focusNode,
    IconData icon, {
    String? suffix,
    required Function(int) onChanged,
    required TextEditingController controller,
  }) {
    // Determine field width based on label
    final bool isParField = label == 'Par';

    return SizedBox(
      height: 80,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Par field: 60px, Distance field: 80% of container width
          final double fieldWidth = isParField
              ? 60.0
              : constraints.maxWidth * 0.8;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: TurbColors.gray[50]!),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      suffix: suffix != null
                          ? Text(suffix, style: Theme.of(context).textTheme.bodySmall)
                          : null,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (String value) {
                      final int? parsedInt = int.tryParse(value);
                      if (parsedInt != null) {
                        onChanged(parsedInt);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
