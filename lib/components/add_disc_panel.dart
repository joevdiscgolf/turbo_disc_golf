import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/disc_data.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Bottom sheet panel for adding a new disc to the user's bag.
///
/// Provides fields for:
/// - Name (required)
/// - Brand, Mold, Plastic (optional)
/// - Flight numbers: Speed, Glide, Turn, Fade (optional)
class AddDiscPanel extends StatefulWidget {
  const AddDiscPanel({
    super.key,
    this.initialName,
    this.onDiscAdded,
  });

  /// Pre-populated disc name (from search field)
  final String? initialName;

  /// Callback when a disc is successfully added
  final void Function(DGDisc disc)? onDiscAdded;

  @override
  State<AddDiscPanel> createState() => _AddDiscPanelState();
}

class _AddDiscPanelState extends State<AddDiscPanel> {
  static const String _panelName = 'Add Disc Panel';

  late final LoggingServiceBase _logger;

  // Form controllers
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _moldController;
  late final TextEditingController _plasticController;
  late final TextEditingController _speedController;
  late final TextEditingController _glideController;
  late final TextEditingController _turnController;
  late final TextEditingController _fadeController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({'panel_name': _panelName});

    // Track modal opened
    _logger.track(
      'Modal Opened',
      properties: {
        'modal_type': 'bottom_sheet',
        'modal_name': _panelName,
        'has_initial_name': widget.initialName != null,
      },
    );

    // Initialize controllers
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _brandController = TextEditingController();
    _moldController = TextEditingController();
    _plasticController = TextEditingController();
    _speedController = TextEditingController();
    _glideController = TextEditingController();
    _turnController = TextEditingController();
    _fadeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _moldController.dispose();
    _plasticController.dispose();
    _speedController.dispose();
    _glideController.dispose();
    _turnController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty && !_isSaving;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: SenseiColors.gray[50],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PanelHeader(title: 'Add New Disc'),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Disc Name',
                      hint: 'e.g., Star Destroyer',
                      required: true,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionLabel('Details (Optional)'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _brandController,
                            label: 'Brand',
                            hint: 'e.g., Innova',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _moldController,
                            label: 'Mold',
                            hint: 'e.g., Destroyer',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _plasticController,
                      label: 'Plastic',
                      hint: 'e.g., Star, Champion, ESP',
                    ),
                    const SizedBox(height: 16),
                    _buildSectionLabel('Flight Numbers (Optional)'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: _speedController,
                            label: 'Speed',
                            hint: '1-14',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumberField(
                            controller: _glideController,
                            label: 'Glide',
                            hint: '1-7',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumberField(
                            controller: _turnController,
                            label: 'Turn',
                            hint: '-5 to +1',
                            allowNegative: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumberField(
                            controller: _fadeController,
                            label: 'Fade',
                            hint: '0-5',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade400,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.black87),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: SenseiColors.blue, width: 2),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool allowNegative = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.black87),
          keyboardType: TextInputType.numberWithOptions(
            signed: allowNegative,
            decimal: false,
          ),
          inputFormatters: [
            if (allowNegative)
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))
            else
              FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: SenseiColors.blue, width: 2),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: SenseiColors.gray[50],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: PrimaryButton(
        label: _isSaving ? 'Adding...' : 'Add Disc',
        width: double.infinity,
        height: 56,
        backgroundColor: SenseiColors.blue,
        labelColor: Colors.white,
        disabled: !_canSave,
        loading: _isSaving,
        onPressed: _handleSave,
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_canSave) return;

    setState(() => _isSaving = true);

    final String name = _nameController.text.trim();
    final String? brand =
        _brandController.text.trim().isEmpty ? null : _brandController.text.trim();
    final String? mold =
        _moldController.text.trim().isEmpty ? null : _moldController.text.trim();
    final String? plastic =
        _plasticController.text.trim().isEmpty ? null : _plasticController.text.trim();
    final int? speed = int.tryParse(_speedController.text.trim());
    final int? glide = int.tryParse(_glideController.text.trim());
    final int? turn = int.tryParse(_turnController.text.trim());
    final int? fade = int.tryParse(_fadeController.text.trim());

    // Create the disc
    final DGDisc newDisc = DGDisc(
      id: BagService.generateDiscId(DGDisc(
        id: '',
        name: name,
        brand: brand,
        moldName: mold,
        plasticType: plastic,
        speed: speed,
        glide: glide,
        turn: turn,
        fade: fade,
      )),
      name: name,
      brand: brand,
      moldName: mold,
      plasticType: plastic,
      speed: speed,
      glide: glide,
      turn: turn,
      fade: fade,
    );

    // Add to bag
    final BagService bagService = locator.get<BagService>();
    final bool success = await bagService.addDisc(newDisc);

    if (success) {
      _logger.track(
        'Disc Added To Bag',
        properties: {
          'disc_id': newDisc.id,
          'disc_name': newDisc.name,
          'has_brand': brand != null,
          'has_flight_numbers': speed != null,
        },
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        widget.onDiscAdded?.call(newDisc);
        Navigator.of(context).pop();
      }
    } else {
      setState(() => _isSaving = false);
    }
  }
}
