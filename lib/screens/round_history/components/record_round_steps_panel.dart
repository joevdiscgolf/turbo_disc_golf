import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';

import 'package:turbo_disc_golf/components/buttons/animated_microphone_button.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/cards/round_data_input_card.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/components/voice_input/voice_description_card.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/round_history/components/temporary_holes_review_grid.dart';
import 'package:turbo_disc_golf/screens/round_processing/round_processing_loading_screen.dart';
import 'package:turbo_disc_golf/services/voice_recording_service.dart';
import 'package:turbo_disc_golf/state/record_round_cubit.dart';
import 'package:turbo_disc_golf/state/record_round_state.dart';
import 'package:turbo_disc_golf/utils/constants/description_constants.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';
import 'package:turbo_disc_golf/utils/panel_helpers.dart';

const String testCourseName = 'Foxwood';
const int totalHoles = 18;

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

  // State management
  int _currentHoleIndex = 0;
  bool _showingReviewGrid = false;
  bool _shouldAutoStartListening = false;
  bool _isStartingListening = false;

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
      // Clear loading state when actually listening
      if (_voiceService.isListening && _isStartingListening) {
        _isStartingListening = false;
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
          height: MediaQuery.of(context).size.height - 64,
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
                    title: 'Record round',
                    onClose: () => Navigator.pop(context),
                  ),
                  _buildContent(recordRoundState),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(RecordRoundState recordRoundState) {
    if (_showingReviewGrid && recordRoundState is RecordRoundActive) {
      return Expanded(
        child:
            TemporaryHolesReviewGrid(
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
                        isSingleHole: true,
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
            const SizedBox(height: 20),
            Center(
              child:
                  Container(
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
                          isLoading: _isStartingListening,
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
            const SizedBox(height: 16),
            _buildNavigationButtons(),
            _buildDebugButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(RecordRoundActive state) {
    final double progress = (_currentHoleIndex + 1) / totalHoles;

    return Column(
      children: [
        // Course card (blue tint)
        RoundDataInputCard(
              icon: Icons.landscape,
              subtitle: state.selectedCourse ?? 'Select a course',
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
        const SizedBox(height: 8),
        // Date card (green tint)
        RoundDataInputCard(
              icon: Icons.access_time,
              subtitle: _formatDateTime(state.selectedDateTime),
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
        const SizedBox(height: 8),
        // Hole Progress Card
        GestureDetector(
          onTap: _showReviewGrid,
          behavior: HitTestBehavior.translucent,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'Hole ${_currentHoleIndex + 1} of $totalHoles',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!showInlineMiniHoleGrid)
                      Row(
                        children: [
                          Icon(
                            Icons.grid_on,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'View',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (!showInlineMiniHoleGrid) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                    ),
                  ),
                ],
                if (showInlineMiniHoleGrid) ...[
                  const SizedBox(height: 12),
                  _MiniHolesGrid(
                    state: state,
                    currentHoleIndex: _currentHoleIndex,
                    onHoleTap: _onHoleTapFromGrid,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    final bool allHolesFilled = _areAllHolesFilled();
    final bool isFirstHole = _currentHoleIndex == 0;
    final bool isLastHole = _currentHoleIndex == totalHoles - 1;
    final bool showFinalize = isLastHole;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;

        // SAFELY calculate previous button width
        double previousButtonWidth;

        if (isFirstHole) {
          previousButtonWidth = 0;
        } else if (isLastHole) {
          previousButtonWidth = 56; // locked small button
        } else {
          previousButtonWidth = (maxWidth - 8) / 2;
        }

        // Clamp to avoid negative/infinity widths
        previousButtonWidth = previousButtonWidth.clamp(0, maxWidth);

        final bool showPrevious = previousButtonWidth > 0;

        return Row(
          children: [
            if (showPrevious)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: previousButtonWidth,
                child: PrimaryButton(
                  label: isLastHole ? '' : 'Previous',
                  width: double.infinity,
                  height: 56,
                  backgroundColor: Colors.grey.shade200,
                  labelColor: Colors.grey.shade700,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  icon: FlutterRemix.arrow_left_s_line,
                  iconColor: Colors.grey.shade700,
                  onPressed: _previousHole,
                ),
              ),

            if (showPrevious) const SizedBox(width: 8),

            Expanded(
              child: PrimaryButton(
                label: showFinalize ? 'Finalize Round' : 'Next',
                width: double.infinity,
                height: 56,
                backgroundColor: showFinalize ? Colors.green : Colors.blue,
                labelColor: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                iconRight: showFinalize
                    ? Icons.check_circle
                    : FlutterRemix.arrow_right_s_line,
                iconColor: Colors.white,
                disabled: isLastHole && !allHolesFilled,
                onPressed: showFinalize ? _finishAndParse : _nextHole,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDebugButtons() {
    if (kDebugMode) {
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
    // Month names
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final String monthName = months[local.month - 1];
    final String date = '$monthName ${local.day}, ${local.year}';
    final int hour = local.hour;
    final String minute = _twoDigits(local.minute);
    final String ampm = hour >= 12 ? 'PM' : 'AM';
    final int hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$date  •  $hour12:$minute $ampm';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

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
        _shouldAutoStartListening =
            autoStartListeningOnNextHole && _currentHoleIndex > 0;
      });

      // Start listening after frame is built to avoid semantics errors
      if (_shouldAutoStartListening) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted && !_voiceService.isListening) {
            setState(() => _isStartingListening = true);
            await _voiceService.startListening(preserveExistingText: false);
          }
        });
      }
    } else {
      _finishAndParse();
    }
  }

  void _showReviewGrid() {
    // Save current hole description before showing grid
    _cubit.setHoleDescription(
      _textEditingController.text,
      index: _currentHoleIndex,
    );
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
      setState(() => _isStartingListening = false);
    } else {
      setState(() => _isStartingListening = true);
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

/// Mini hole indicator for inline grid - shows completion status and allows navigation
class _MiniHoleIndicator extends StatelessWidget {
  const _MiniHoleIndicator({
    required this.holeNumber,
    required this.isComplete,
    required this.isCurrent,
    required this.onTap,
  });

  final int holeNumber;
  final bool isComplete;
  final bool isCurrent;
  final VoidCallback onTap;

  static const Color _holeAccent = Color(0xFF2196F3); // blue

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isCurrent
              ? _holeAccent.withValues(alpha: 0.1)
              : Colors.transparent,
          border: isCurrent ? Border.all(color: _holeAccent, width: 1) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Icon(
            isComplete ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isComplete ? Colors.green : Colors.grey[400],
          ),
        ),
      ),
    );
  }
}

/// Mini holes grid for inline display - 9 holes per row
class _MiniHolesGrid extends StatelessWidget {
  const _MiniHolesGrid({
    required this.state,
    required this.currentHoleIndex,
    required this.onHoleTap,
  });

  final RecordRoundActive state;
  final int currentHoleIndex;
  final Function(int) onHoleTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(totalHoles, (index) {
        final String? description = state.holeDescriptions[index];
        final bool isComplete =
            description != null && description.trim().isNotEmpty;
        final bool isCurrent = index == currentHoleIndex;

        return _MiniHoleIndicator(
          holeNumber: index + 1,
          isComplete: isComplete,
          isCurrent: isCurrent,
          onTap: () => onHoleTap(index),
        );
      }),
    );
  }
}
