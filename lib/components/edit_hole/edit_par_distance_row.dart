import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class EditParDistanceRow extends StatefulWidget {
  const EditParDistanceRow({
    super.key,
    required this.par,
    required this.distance,
    required this.strokes,
    required this.onParChanged,
    required this.onDistanceChanged,
    required this.parFocusNode,
    required this.distanceFocusNode,
  });

  final int? par;
  final int? distance;
  final int strokes;
  final Function(int newPar) onParChanged;
  final Function(int newDistance) onDistanceChanged;
  final FocusNode parFocusNode;
  final FocusNode distanceFocusNode;

  @override
  State<EditParDistanceRow> createState() => _EditParDistanceRowState();
}

class _EditParDistanceRowState extends State<EditParDistanceRow> {
  late final TextEditingController _parController;
  late final TextEditingController _distanceController;

  @override
  void dispose() {
    super.dispose();
    _parController.dispose();
    _distanceController.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.par != null) {
      _parController = TextEditingController(text: widget.par?.toString());
    } else {
      _parController = TextEditingController();
    }

    if (widget.distance != null) {
      _distanceController = TextEditingController(
        text: widget.distance?.toString(),
      );
    } else {
      _distanceController = TextEditingController();
    }
  }

  @override
  void didUpdateWidget(EditParDistanceRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update par controller if par value changed
    if (widget.par != oldWidget.par) {
      _parController.text = widget.par?.toString() ?? '';
    }

    // Update distance controller if distance value changed
    if (widget.distance != oldWidget.distance) {
      _distanceController.text = widget.distance?.toString() ?? '';
    }
  }

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
              widget.parFocusNode,
              Icons.flag_outlined,
              onChanged: widget.onParChanged,
              controller: _parController,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _editableInfoCard(
              context,
              'Distance',
              widget.distanceFocusNode,
              Icons.straighten,
              suffix: 'ft',
              onChanged: widget.onDistanceChanged,
              controller: _distanceController,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _staticInfoCard(context, 'Throws', '${widget.strokes}'),
          ),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                          ? Text(
                              suffix,
                              style: Theme.of(context).textTheme.bodySmall,
                            )
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
