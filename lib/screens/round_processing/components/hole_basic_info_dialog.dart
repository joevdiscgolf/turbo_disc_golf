import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog for manually editing basic hole information (number, par, distance).
/// Used when a hole is missing required metadata fields.
class HoleBasicInfoDialog extends StatefulWidget {
  const HoleBasicInfoDialog({
    super.key,
    this.holeNumber,
    this.par,
    this.feet,
    required this.onSave,
  });

  final int? holeNumber;
  final int? par;
  final int? feet;
  final void Function({
    required int holeNumber,
    required int par,
    int? feet,
  }) onSave;

  @override
  State<HoleBasicInfoDialog> createState() => _HoleBasicInfoDialogState();
}

class _HoleBasicInfoDialogState extends State<HoleBasicInfoDialog> {
  late TextEditingController _holeNumberController;
  late TextEditingController _parController;
  late TextEditingController _feetController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _holeNumberController = TextEditingController(
      text: widget.holeNumber?.toString() ?? '',
    );
    _parController = TextEditingController(
      text: widget.par?.toString() ?? '3', // Default to par 3
    );
    _feetController = TextEditingController(
      text: widget.feet?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _holeNumberController.dispose();
    _parController.dispose();
    _feetController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final int holeNumber = int.parse(_holeNumberController.text);
      final int par = int.parse(_parController.text);
      final int? feet = _feetController.text.isEmpty
          ? null
          : int.parse(_feetController.text);

      widget.onSave(
        holeNumber: holeNumber,
        par: par,
        feet: feet,
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Hole Info',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Hole Number Field
                TextFormField(
                  controller: _holeNumberController,
                  decoration: InputDecoration(
                    labelText: 'Hole Number *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Hole number is required';
                    }
                    final int? number = int.tryParse(value);
                    if (number == null || number < 1 || number > 99) {
                      return 'Enter a valid hole number (1-99)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Par Field
                TextFormField(
                  controller: _parController,
                  decoration: InputDecoration(
                    labelText: 'Par *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Par is required';
                    }
                    final int? par = int.tryParse(value);
                    if (par == null || par < 2 || par > 6) {
                      return 'Enter a valid par (2-6)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Distance Field (Optional)
                TextFormField(
                  controller: _feetController,
                  decoration: InputDecoration(
                    labelText: 'Distance (ft)',
                    hintText: 'Optional',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null; // Optional field
                    }
                    final int? feet = int.tryParse(value);
                    if (feet == null || feet < 50 || feet > 2000) {
                      return 'Enter a valid distance (50-2000 ft)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Footer Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF137e66),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
