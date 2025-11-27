import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/components/buttons/animated_microphone_button.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/components/voice_input/voice_description_card.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/round_history/components/temporary_holes_review_grid.dart';
import 'package:turbo_disc_golf/screens/round_processing/round_processing_loading_screen.dart';
import 'package:turbo_disc_golf/services/voice_recording_service.dart';
import 'package:turbo_disc_golf/state/record_round_cubit.dart';
import 'package:turbo_disc_golf/state/record_round_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/description_constants.dart';
import 'package:turbo_disc_golf/utils/panel_helpers.dart';

const String testCourseName = 'Foxwood';
const int totalHoles = 18;

enum RecordRoundStep { step1Setup, step2Holes }

class RecordRoundStepsPanel extends StatefulWidget {
  const RecordRoundStepsPanel({super.key, required this.bottomViewPadding});

  final double bottomViewPadding;

  @override
  State<RecordRoundStepsPanel> createState() => _RecordRoundStepsPanelState();
}

class _RecordRoundStepsPanelState extends State<RecordRoundStepsPanel> {
  late final RecordRoundCubit _cubit;
  late final VoiceRecordingService _voiceService;

  // Text editing
  late final TextEditingController _textEditingController;
  late final FocusNode _focusNode;

  // Step management
  RecordRoundStep _currentStep = RecordRoundStep.step1Setup;
  int _currentHoleIndex = 0;
  bool _showingReviewGrid = false;
  bool _shouldAutoStartListening = false;

  // Course/Date selection (Step 1)
  final List<String> _courses = <String>[
    'Select a course',
    'Redwood Park DGC',
    'Riverside Long',
    'Meadow Ridge',
  ];
  String? _selectedCourse;
  DateTime _selectedDateTime = DateTime.now();

  // Test constants
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
  static const Color _descAccent = Color(0xFFB39DDB); // light purple
  static const Color _createAccent = Color(0xFF9D4EDD); // purple-ish
  static const Color _courseAccent = Color(0xFF2196F3); // blue
  static const Color _dateAccent = Color(0xFF4CAF50); // green

  @override
  void initState() {
    super.initState();
    _cubit = BlocProvider.of<RecordRoundCubit>(context);
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();
    _voiceService = locator.get<VoiceRecordingService>();
    _voiceService.initialize();
    _voiceService.addListener(_onVoiceServiceUpdate);
    _focusNode.addListener(_onFocusChange);
    _textEditingController.addListener(_onTextControllerChange);

    if (_voiceService.transcribedText.isNotEmpty) {
      _textEditingController.text = _voiceService.transcribedText;
    }
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceServiceUpdate);
    _focusNode.removeListener(_onFocusChange);
    _textEditingController.removeListener(_onTextControllerChange);
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && _voiceService.isListening) {
      _voiceService.stopListening();
    }
  }

  void _onTextControllerChange() {
    if (!_voiceService.isListening && _focusNode.hasFocus) {
      _voiceService.updateText(_textEditingController.text);
    }
  }

  void _onVoiceServiceUpdate() {
    if (mounted) {
      if (_voiceService.isListening && !_focusNode.hasFocus) {
        _textEditingController.text = _voiceService.transcribedText;
        _textEditingController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textEditingController.text.length),
        );
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordRoundCubit, RecordRoundState>(
      builder: (context, recordRoundState) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _getPanelHeight(context),
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF5EEF8), Colors.white],
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
                    title: _currentStep == RecordRoundStep.step1Setup
                        ? 'Course & date'
                        : 'Record round',
                    onClose: () => Navigator.pop(context),
                  ),
                  if (_currentStep == RecordRoundStep.step1Setup)
                    _buildStep1Content()
                  else
                    _buildStep2Content(recordRoundState),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double? _getPanelHeight(BuildContext context) {
    if (_currentStep == RecordRoundStep.step1Setup) {
      // Step 1: Let Flutter auto-size based on content (MainAxisSize.min)
      return null;
    } else {
      // Step 2: Fixed full height
      return MediaQuery.of(context).size.height - 64;
    }
  }

  Widget _buildStep1Content() {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: widget.bottomViewPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _InfoCard(
                icon: Icons.landscape,
                title: 'Course *',
                subtitle: _selectedCourse ?? 'Select a course',
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
          _InfoCard(
                icon: Icons.access_time,
                title: 'Date & Time',
                subtitle: '${_formatDateTime(_selectedDateTime)}  (auto)',
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
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Continue to Hole Recording',
            labelColor: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            width: double.infinity,
            height: 56,
            disabled:
                !kDebugMode && _selectedCourse == null ||
                _selectedCourse == 'Select a course',
            onPressed: _handleContinueToHoleRecording,
          ),
          const SizedBox(height: 14),
          _buildDebugButtons(),
        ],
      ),
    );
  }

  Widget _buildStep2Content(RecordRoundState recordRoundState) {
    if (_showingReviewGrid && recordRoundState is RecordRoundActive) {
      return Expanded(
        child: TemporaryHolesReviewGrid(
          holeDescriptions: recordRoundState.holeDescriptions,
          onHoleTap: _onHoleTapFromGrid,
          onFinishAndParse: _finishAndParse,
          onBack: () => setState(() => _showingReviewGrid = false),
          allHolesFilled: _areAllHolesFilled(),
          bottomViewPadding: widget.bottomViewPadding,
        )
            .animate()
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1.0, 1.0),
              duration: 300.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: 250.ms, curve: Curves.easeOut),
      );
    }

    return _buildHoleEntryView(recordRoundState)
        .animate()
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1.0, 1.0),
          duration: 300.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 250.ms, curve: Curves.easeOut);
  }

  Widget _buildHoleEntryView(RecordRoundState recordRoundState) {
    final bool isListening = _voiceService.isListening;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: widget.bottomViewPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (recordRoundState is RecordRoundActive)
              _buildHeader(recordRoundState),
            const SizedBox(height: 12),
            Expanded(
              child:
                  VoiceDescriptionCard(
                        controller: _textEditingController,
                        focusNode: _focusNode,
                        isListening: isListening,
                        accent: _descAccent,
                        onClear: _handleClearText,
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
                                    ).withValues(alpha: 0.06)
                                  : const Color(
                                      0xFF2196F3,
                                    ).withValues(alpha: 0.06),
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 14),
            _buildNavigationButtons(),
            _buildDebugButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(RecordRoundActive state) {
    final double progress = (_currentHoleIndex + 1) / totalHoles;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.landscape, size: 16, color: _courseAccent),
                  const SizedBox(width: 6),
                  Text(
                    state.selectedCourse ?? 'Unknown Course',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Text(
                _formatDateTime(state.selectedDateTime),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Hole ${_currentHoleIndex + 1} of $totalHoles',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _descAccent,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(_descAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final bool allHolesFilled = _areAllHolesFilled();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'Previous',
                width: double.infinity,
                height: 44,
                backgroundColor: Colors.grey.shade200,
                labelColor: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                icon: Icons.arrow_back,
                iconColor: Colors.grey.shade700,
                disabled: _currentHoleIndex == 0,
                onPressed: _previousHole,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PrimaryButton(
                label: 'Next',
                width: double.infinity,
                height: 44,
                backgroundColor: _descAccent,
                labelColor: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                iconRight: Icons.arrow_forward,
                iconColor: Colors.white,
                disabled: _currentHoleIndex == totalHoles - 1,
                onPressed: _nextHole,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        PrimaryButton(
          label: allHolesFilled ? 'Finalize Round' : 'Review All',
          width: double.infinity,
          height: 56,
          backgroundColor: allHolesFilled ? _descAccent : Colors.blue.shade50,
          labelColor: allHolesFilled ? Colors.white : Colors.blue.shade700,
          fontSize: 14,
          fontWeight: allHolesFilled ? FontWeight.bold : FontWeight.w600,
          icon: allHolesFilled ? Icons.check_circle : Icons.grid_on,
          iconColor: allHolesFilled ? Colors.white : Colors.blue.shade700,
          onPressed: allHolesFilled ? _finishAndParse : _showReviewGrid,
        ),
      ],
    );
  }

  Widget _buildDebugButtons() {
    if (_currentStep == RecordRoundStep.step1Setup || kDebugMode) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          PrimaryButton(
            label: 'Change',
            width: 100,
            height: 44,
            backgroundColor: _createAccent.withValues(alpha: 0.18),
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
              onPressed: _handleParse,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCourseSelector() async {
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
                        final String course = _courses[index];
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
                            setState(() => _selectedCourse = course);
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
    final DateTime local = dt.toLocal();
    final String date =
        '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)}';
    final int hour = local.hour;
    final String minute = _twoDigits(local.minute);
    final String ampm = hour >= 12 ? 'PM' : 'AM';
    final int hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$date • $hour12:$minute $ampm';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  void _handleContinueToHoleRecording() {
    if (!kDebugMode && _selectedCourse == null ||
        _selectedCourse == 'Select a course') {
      return;
    }

    _cubit.setSelectedCourse(_selectedCourse ?? 'Default course name');
    _cubit.setSelectedTime(_selectedDateTime);

    setState(() {
      _currentStep = RecordRoundStep.step2Holes;
      _currentHoleIndex = 0;
      _textEditingController.text = '';
      _shouldAutoStartListening = false; // Don't auto-start on hole 1
    });
  }

  bool _areAllHolesFilled() {
    if (_cubit.state is! RecordRoundActive) return false;
    final RecordRoundActive state = _cubit.state as RecordRoundActive;
    for (int i = 0; i < totalHoles; i++) {
      final String? description = state.holeDescriptions[i];
      if (description == null || description.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  void _previousHole() {
    if (_currentHoleIndex > 0) {
      // Save current hole description
      _cubit.setHoleDescription(
        _textEditingController.text,
        index: _currentHoleIndex,
      );

      setState(() {
        _currentHoleIndex--;
        _textEditingController.text =
            (_cubit.state as RecordRoundActive)
                .holeDescriptions[_currentHoleIndex] ??
            '';
        _voiceService.updateText(_textEditingController.text);
        _shouldAutoStartListening = false;
      });
    }
  }

  void _nextHole() {
    _cubit.setHoleDescription(
      _textEditingController.text,
      index: _currentHoleIndex,
    );
    if (_currentHoleIndex < totalHoles - 1) {
      setState(() {
        _currentHoleIndex++;
        _textEditingController.text =
            (_cubit.state as RecordRoundActive)
                .holeDescriptions[_currentHoleIndex] ??
            '';
        _voiceService.clearText();
        // Auto-start listening when navigating to next hole (but not on hole 1)
        _shouldAutoStartListening = _currentHoleIndex > 0;
      });

      // Start listening after state is updated
      if (_shouldAutoStartListening) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_voiceService.isListening) {
            _voiceService.startListening(preserveExistingText: false);
          }
        });
      }
    } else {
      _finishAndParse();
    }
  }

  void _showReviewGrid() {
    setState(() => _showingReviewGrid = true);
  }

  void _onHoleTapFromGrid(int holeIndex) {
    setState(() {
      _showingReviewGrid = false;
      _currentHoleIndex = holeIndex;
      _textEditingController.text =
          (_cubit.state as RecordRoundActive).holeDescriptions[holeIndex] ?? '';
      _voiceService.updateText(_textEditingController.text);
      _shouldAutoStartListening =
          false; // Don't auto-start when coming from grid
    });
  }

  void _finishAndParse() {
    _cubit.setHoleDescription(
      _textEditingController.text,
      index: _currentHoleIndex,
    );

    final RecordRoundActive state = _cubit.state as RecordRoundActive;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => RoundProcessingLoadingScreen(
          transcript: state.fullTranscript,
          courseName: state.selectedCourse ?? 'Unknown Course',
          useSharedPreferences: false,
        ),
      ),
    );
  }

  Future<void> _toggleListening() async {
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
    } else {
      FocusScope.of(context).unfocus();
      await _voiceService.startListening(preserveExistingText: true);
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
                    selectedTileColor: _createAccent.withValues(alpha: 0.08),
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
                      setState(() => _selectedTestIndex = index);
                      Navigator.pop(context);
                      _focusNode.unfocus();
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

  void _handleClearText() {
    setState(() {
      _textEditingController.clear();
      _voiceService.clearText();
    });
  }

  void _handleParse() {
    final bool useCached = false;
    debugPrint('Test Parse Constant: Using cached round: $useCached');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RoundProcessingLoadingScreen(
            transcript: _selectedTranscript,
            courseName: testCourseName,
            useSharedPreferences: useCached,
          ),
        ),
      );
    }
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color accent;

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
            colors: [flattenedOverWhite(accent, 0.2), Colors.white],
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
                    color: accent.withValues(alpha: 0.08),
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
