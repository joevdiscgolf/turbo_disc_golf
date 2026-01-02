import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course_data.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Bottom sheet / modal for creating a course + default layout
class CreateCourseSheet extends StatefulWidget {
  const CreateCourseSheet({super.key, required this.onCourseCreated});

  final void Function(Course course) onCourseCreated;

  @override
  State<CreateCourseSheet> createState() => _CreateCourseSheetState();
}

class _CreateCourseSheetState extends State<CreateCourseSheet> {
  final Uuid _uuid = const Uuid();
  final ImagePicker _picker = ImagePicker();

  // ─────────────────────────────────────────────
  // Course-level state
  // ─────────────────────────────────────────────
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  // ─────────────────────────────────────────────
  // Layout-level state
  // ─────────────────────────────────────────────
  final TextEditingController _layoutNameController = TextEditingController(
    text: 'Main Layout',
  );
  int _numberOfHoles = 18;

  late List<CourseHole> _holes;

  // ─────────────────────────────────────────────
  // Image parsing state
  // ─────────────────────────────────────────────
  bool _isParsingImage = false;
  String? _parseError;

  @override
  void initState() {
    super.initState();
    _initializeHoles();
  }

  void _initializeHoles() {
    _holes = List.generate(_numberOfHoles, (index) {
      final holeNumber = index + 1;
      return CourseHole(
        holeNumber: holeNumber,
        par: 3,
        feet: 300,
        holeType: HoleType.open,
        pins: const [HolePin(id: 'A', par: 3, feet: 300, label: 'Default')],
        defaultPinId: 'A',
      );
    });
  }

  void _updateHoleCount(int newCount) {
    setState(() {
      _numberOfHoles = newCount;
      _initializeHoles();
    });
  }

  // ─────────────────────────────────────────────
  // Image parsing
  // ─────────────────────────────────────────────
  Future<void> _pickAndParseImage() async {
    setState(() => _parseError = null);

    // Capture the messenger before async gap
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    // Show source selection dialog
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() => _isParsingImage = true);

      final AiParsingService aiService = locator.get<AiParsingService>();
      final List<HoleMetadata> holeMetadata = await aiService.parseScorecard(
        imagePath: image.path,
      );

      if (holeMetadata.isEmpty) {
        setState(() {
          _parseError = 'No course data found. Try another image.';
          _isParsingImage = false;
        });
        return;
      }

      setState(() {
        _numberOfHoles = holeMetadata.length;
        _holes = holeMetadata.map((metadata) {
          return CourseHole(
            holeNumber: metadata.holeNumber,
            par: metadata.par,
            feet: metadata.distanceFeet ?? 300,
            holeType: HoleType.open,
            pins: [
              HolePin(
                id: 'A',
                par: metadata.par,
                feet: metadata.distanceFeet ?? 300,
                label: 'Default',
              ),
            ],
            defaultPinId: 'A',
          );
        }).toList();
        _isParsingImage = false;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text('Successfully parsed ${holeMetadata.length} holes!'),
        ),
      );
    } catch (e) {
      setState(() {
        _parseError = 'Failed to parse: ${e.toString()}';
        _isParsingImage = false;
      });
    }
  }

  // ─────────────────────────────────────────────
  // Save
  // ─────────────────────────────────────────────
  void _saveCourse() {
    if (_courseNameController.text.trim().isEmpty) {
      _showError('Course name is required');
      return;
    }

    if (_holes.isEmpty) {
      _showError('Layout must have at least one hole');
      return;
    }

    final layout = CourseLayout(
      id: _uuid.v4(),
      name: _layoutNameController.text.trim(),
      holes: _holes,
      isDefault: true,
    );

    final course = Course(
      id: _uuid.v4(),
      name: _courseNameController.text.trim(),
      layouts: [layout],
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      state: _stateController.text.trim().isEmpty
          ? null
          : _stateController.text.trim(),
      country: _countryController.text.trim().isEmpty
          ? null
          : _countryController.text.trim(),
    );

    widget.onCourseCreated(course);
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 1.0,
        builder: (context, scrollController) {
          return Material(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PanelHeader(
                    title: 'Create Course',
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCourseSection(),
                        Divider(
                          height: 32,
                          color: TurbColors.gray.shade100,
                          thickness: 1,
                        ),
                        _buildLayoutSection(),
                        Divider(
                          height: 32,
                          color: TurbColors.gray.shade100,
                          thickness: 1,
                        ),
                        _buildHolesSection(),
                        const SizedBox(height: 24),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Section header helper
  // ─────────────────────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
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

  // ─────────────────────────────────────────────
  // Course info
  // ─────────────────────────────────────────────
  Widget _buildCourseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Course Info',
          icon: Icons.location_on,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _courseNameController,
          decoration: const InputDecoration(labelText: 'Course name'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _stateController,
                decoration: const InputDecoration(labelText: 'State'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _countryController,
          decoration: const InputDecoration(labelText: 'Country'),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Layout
  // ─────────────────────────────────────────────
  Widget _buildLayoutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Default Layout',
          icon: Icons.grid_view,
          color: Colors.teal,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _layoutNameController,
          decoration: const InputDecoration(labelText: 'Layout name'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Number of holes:'),
            const SizedBox(width: 12),
            DropdownButton<int>(
              value: _numberOfHoles,
              items: const [
                DropdownMenuItem(value: 9, child: Text('9')),
                DropdownMenuItem(value: 18, child: Text('18')),
              ],
              onChanged: (value) {
                if (value != null) _updateHoleCount(value);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _isParsingImage ? null : _pickAndParseImage,
          icon: _isParsingImage
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.camera_alt),
          label: Text(
            _isParsingImage ? 'Parsing Image...' : 'Upload from Image',
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
        if (_parseError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _parseError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Holes + pins
  // ─────────────────────────────────────────────
  Widget _buildHolesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Holes',
          icon: Icons.sports_golf,
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        ..._holes.map(_buildHoleRow),
      ],
    );
  }

  Widget _buildHoleRow(CourseHole hole) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Hole number
            SizedBox(
              width: 60,
              child: Text(
                'Hole ${hole.holeNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Par field (smaller)
            Flexible(
              flex: 2,
              child: _numberField(
                label: 'Par',
                value: hole.par,
                onChanged: (v) {
                  setState(() {
                    _holes = _holes.map((h) {
                      if (h.holeNumber != hole.holeNumber) return h;
                      return h.copyWith(par: v);
                    }).toList();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),

            // Feet field (smaller)
            Flexible(
              flex: 3,
              child: _numberField(
                label: 'Feet',
                value: hole.feet,
                onChanged: (v) {
                  setState(() {
                    _holes = _holes.map((h) {
                      if (h.holeNumber != hole.holeNumber) return h;
                      return h.copyWith(feet: v);
                    }).toList();
                  });
                },
              ),
            ),
            const SizedBox(width: 16),

            // Hole type buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _holeTypeButton(
                  hole: hole,
                  type: HoleType.open,
                  icon: Icons.wb_sunny,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                _holeTypeButton(
                  hole: hole,
                  type: HoleType.slightlyWooded,
                  icon: Icons.park,
                  color: Colors.amber,
                ),
                const SizedBox(width: 4),
                _holeTypeButton(
                  hole: hole,
                  type: HoleType.wooded,
                  icon: Icons.forest,
                  color: Colors.green[800]!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _holeTypeButton({
    required CourseHole hole,
    required HoleType type,
    required IconData icon,
    required Color color,
  }) {
    final bool isSelected = hole.holeType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _holes = _holes.map((h) {
            if (h.holeNumber != hole.holeNumber) return h;
            return h.copyWith(holeType: type);
          }).toList();
        });
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? color : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _numberField({
    required String label,
    required int value,
    required void Function(int) onChanged,
  }) {
    return TextFormField(
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (v) {
        final parsed = int.tryParse(v);
        if (parsed != null) onChanged(parsed);
      },
    );
  }

  // ─────────────────────────────────────────────
  // Save
  // ─────────────────────────────────────────────
  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF137e66), Color(0xFF1a9f7f)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: _saveCourse,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Create Course',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
