import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:turbo_disc_golf/components/buttons/animated_microphone_button.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/components/voice_input/voice_description_card.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/round_processing/round_processing_loading_screen.dart';
import 'package:turbo_disc_golf/services/voice_recording_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/description_constants.dart';
import 'package:turbo_disc_golf/utils/panel_helpers.dart';

const String testCourseName = 'Foxwood';

/// RecordRoundPanelV2
/// - Soft panel background gradient
/// - Subtle card gradients with semantic accent tints
/// - Unified description card, larger with live transcript
/// - Course selector (select/create)
/// - Keeps original voice recording & parse/continue logic
class RecordRoundPanelV2 extends StatefulWidget {
  const RecordRoundPanelV2({super.key, required this.bottomViewPadding});

  final double bottomViewPadding;

  @override
  State<RecordRoundPanelV2> createState() => _RecordRoundPanelV2State();
}

class _RecordRoundPanelV2State extends State<RecordRoundPanelV2> {
  final VoiceRecordingService _voiceService = locator
      .get<VoiceRecordingService>();
  final TextEditingController _transcriptController = TextEditingController();
  final FocusNode _transcriptFocusNode = FocusNode();

  // Course management
  final List<String> _courses = <String>[
    'Select a course',
    'Redwood Park DGC',
    'Riverside Long',
    'Meadow Ridge',
  ];
  String _selectedCourse = 'Select a course';

  // Date/time
  DateTime _selectedDateTime = DateTime.now();

  // Test constants (same as original file)
  int _selectedTestIndex = 0;
  final List<String> _testRoundDescriptionNames = DescriptionConstants
      .fullRoundConstants
      .keys
      .toList();
  final List<String> _testRoundConstants = DescriptionConstants
      .fullRoundConstants
      .values
      .toList();

  String get _selectedTranscript => _testRoundConstants[_selectedTestIndex];

  // Accent colors
  static const Color _courseAccent = Color(0xFF2196F3); // blue
  static const Color _dateAccent = Color(0xFF4CAF50); // green
  static const Color _descAccent = Color(0xFFB39DDB); // light purple
  static const Color _createAccent = Color(0xFF9D4EDD); // purple-ish

  @override
  void initState() {
    super.initState();
    _voiceService.initialize();
    _voiceService.addListener(_onVoiceServiceUpdate);
    _transcriptFocusNode.addListener(_onTranscriptFocusChange);
  }

  void _onTranscriptFocusChange() {
    if (_transcriptFocusNode.hasFocus && _voiceService.isListening) {
      _voiceService.stopListening();
    }
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceServiceUpdate);
    _transcriptFocusNode.removeListener(_onTranscriptFocusChange);
    _transcriptController.dispose();
    _transcriptFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isListening = _voiceService.isListening;
    final bool hasTranscript = _transcriptController.text.isNotEmpty;
    final double panelHeight = MediaQuery.of(context).size.height - 64;

    return SizedBox(
      height: MediaQuery.of(context).size.height - 64,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: panelHeight,
          decoration: BoxDecoration(
            // Soft gradient fading from light purple to white
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF5EEF8), // Light purple tint
                Colors.white, // Fade to white
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              PanelHeader(
                title: 'Record round',
                onClose: () => Navigator.pop(context),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: widget.bottomViewPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Course card (blue tint)
                      _InfoCard(
                            icon: Icons.landscape,
                            title: 'Course',
                            subtitle: _selectedCourse == 'Select a course'
                                ? 'Select a course'
                                : _selectedCourse,
                            onTap: _showCourseSelector,
                            accent: _courseAccent,
                          )
                          .animate()
                          .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.08,
                            end: 0.0,
                            duration: 280.ms,
                            curve: Curves.easeOut,
                          ),
                      const SizedBox(height: 12),

                      // Date card (green tint)
                      _InfoCard(
                            icon: Icons.access_time,
                            title: 'Date & Time',
                            subtitle:
                                '${_formatDateTime(_selectedDateTime)}  (auto)',
                            onTap: _showDateTimeEditor,
                            accent: _dateAccent,
                          )
                          .animate(delay: 90.ms)
                          .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.08,
                            end: 0.0,
                            duration: 280.ms,
                            curve: Curves.easeOut,
                          ),
                      const SizedBox(height: 12),

                      // Description (light purple tint) — larger
                      Expanded(
                        child:
                            VoiceDescriptionCard(
                                  controller: _transcriptController,
                                  focusNode: _transcriptFocusNode,
                                  isListening: isListening,
                                  accent: _descAccent,
                                )
                                .animate(delay: 180.ms)
                                .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                                .slideY(
                                  begin: 0.08,
                                  end: 0.0,
                                  duration: 280.ms,
                                  curve: Curves.easeOut,
                                ),
                      ),

                      const SizedBox(height: 18),

                      // Microphone with state-based glow
                      Center(
                        child:
                            Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        isListening
                                            ? const Color(
                                                0xFFFF7A7A,
                                              ).withValues(
                                                alpha: 0.06,
                                              ) // Red glow when listening
                                            : const Color(
                                                0xFF2196F3,
                                              ).withValues(
                                                alpha: 0.06,
                                              ), // Blue glow when idle
                                        Colors.transparent,
                                      ],
                                      stops: const [0.4, 1.0],
                                    ),
                                  ),
                                  child: AnimatedMicrophoneButton(
                                    isListening: isListening,
                                    onTap: _toggleListening,
                                  ),
                                )
                                .animate(delay: 270.ms)
                                .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                                .scale(
                                  begin: const Offset(0.85, 0.85),
                                  end: const Offset(1.0, 1.0),
                                  duration: 300.ms,
                                  curve: Curves.easeOutBack,
                                ),
                      ),

                      Center(
                        child: Text(
                          isListening ? 'Tap to stop' : 'Tap to start',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Debug buttons (Change + Parse) preserved
                      if (true) ...[
                        Row(
                          children: [
                            PrimaryButton(
                              label: 'Change',
                              width: 100,
                              height: 44,
                              backgroundColor: _createAccent.withValues(
                                alpha: 0.18,
                              ),
                              labelColor: _createAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              onPressed: _showTestConstantSelector,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PrimaryButton(
                                label: 'Parse',
                                width: double.infinity,
                                height: 44,
                                backgroundColor: _createAccent,
                                labelColor: Colors.white,
                                icon: Icons.science,
                                iconColor: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                onPressed: () async {
                                  final bool useCached = false;
                                  debugPrint(
                                    'Test Parse Constant: Using cached round: $useCached',
                                  );
                                  if (context.mounted) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            RoundProcessingLoadingScreen(
                                              transcript: _selectedTranscript,
                                              courseName: testCourseName,
                                              useSharedPreferences: useCached,
                                            ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Continue button
                      PrimaryButton(
                        label: 'Continue',
                        labelColor: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        width: double.infinity,
                        height: 56,
                        disabled: !hasTranscript || isListening,
                        onPressed: _handleContinue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onVoiceServiceUpdate() {
    if (mounted) {
      if (!_transcriptFocusNode.hasFocus) {
        _transcriptController.text = _voiceService.transcribedText;
        _transcriptController.selection = TextSelection.fromPosition(
          TextPosition(offset: _transcriptController.text.length),
        );
      }
      setState(() {});
    }
  }

  Future<void> _toggleListening() async {
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
    } else {
      FocusScope.of(context).unfocus();
      await _voiceService.startListening();
    }
  }

  void _showTestConstantSelector() {
    FocusScope.of(context).unfocus();
    displayBottomSheet(
      context,
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Test Constant',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(
                _testRoundDescriptionNames.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    selected: _selectedTestIndex == index,
                    selectedTileColor: _createAccent.withValues(alpha: (0.08)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      _testRoundDescriptionNames[index],
                      style: TextStyle(
                        fontWeight: _selectedTestIndex == index
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedTestIndex == index
                            ? _createAccent
                            : null,
                      ),
                    ),
                    trailing: _selectedTestIndex == index
                        ? const Icon(Icons.check_circle, color: _createAccent)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedTestIndex = index;
                      });
                      Navigator.pop(context);
                      _transcriptFocusNode.unfocus();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _handleContinue() {
    final String transcript = _transcriptController.text;
    if (transcript.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No transcript available')));
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RoundProcessingLoadingScreen(
          transcript: transcript,
          useSharedPreferences: false,
        ),
      ),
    );
  }

  Future<void> _showCourseSelector() async {
    FocusScope.of(context).unfocus();
    displayBottomSheet(
      context,
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Course',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: _courses.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index < _courses.length) {
                        final course = _courses[index];
                        final bool selected = course == _selectedCourse;
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: selected
                              ? _courseAccent.withValues(alpha: 0.08)
                              : null,
                          leading: Icon(
                            Icons.landscape,
                            color: selected ? _courseAccent : Colors.black87,
                          ),
                          title: Text(
                            course,
                            style: selected
                                ? const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _courseAccent,
                                  )
                                : null,
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: _courseAccent,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedCourse = course;
                            });
                            Navigator.pop(context);
                          },
                        );
                      } else {
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: _createAccent.withValues(alpha: 0.08),
                          leading: const Icon(
                            Icons.add_circle_outline,
                            color: _createAccent,
                          ),
                          title: const Text(
                            'Create new course',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showCreateCourseDialog();
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateCourseDialog() async {
    final TextEditingController nameController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Course'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Course name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final String name = nameController.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _courses.add(name);
                    _selectedCourse = name;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDateTimeEditor() async {
    FocusScope.of(context).unfocus();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) return;

    final TimeOfDay initialTime = TimeOfDay.fromDateTime(_selectedDateTime);
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime == null) {
      setState(() {
        _selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
      return;
    }

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final date =
        '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)}';
    final hour = local.hour;
    final minute = _twoDigits(local.minute);
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$date • $hour12:$minute $ampm';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}

/// Info card with subtle gradient tint and shared icon bubble.
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color accent;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final bool isClickable = onTap != null;
    final Color baseColor = Colors.grey.shade50;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: flattenedOverWhite(accent, 0.3)),
          gradient: LinearGradient(
            transform: GradientRotation(math.pi / 4),
            colors: [
              flattenedOverWhite(accent, 0.2),
              Colors.white, // Fade to white at bottom right
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Circular icon container with radial gradient
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.white, accent.withValues(alpha: 0.0)],
                  stops: const [0.6, 1.0],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.08), // Colored shadow
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isClickable ? Colors.grey[500] : Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }
}
