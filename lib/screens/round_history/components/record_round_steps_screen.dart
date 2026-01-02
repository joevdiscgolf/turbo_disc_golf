import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/buttons/animated_microphone_button.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/cards/round_data_input_card.dart';
import 'package:turbo_disc_golf/components/voice_input/voice_description_card.dart';
import 'package:turbo_disc_golf/screens/round_history/components/temporary_holes_review_grid.dart';
import 'package:turbo_disc_golf/screens/round_processing/round_processing_loading_screen.dart';
import 'package:turbo_disc_golf/state/record_round_cubit.dart';
import 'package:turbo_disc_golf/state/record_round_state.dart';
import 'package:turbo_disc_golf/utils/constants/description_constants.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';
import 'package:turbo_disc_golf/utils/panel_helpers.dart';

const String testCourseName = 'Foxwood';
const int totalHoles = 18;

class RecordRoundStepsScreen extends StatefulWidget {
  const RecordRoundStepsScreen({
    super.key,
    required this.bottomViewPadding,
    this.skipIntroAnimations = false,
  });

  final double bottomViewPadding;
  final bool skipIntroAnimations;

  @override
  State<RecordRoundStepsScreen> createState() => _RecordRoundStepsScreenState();
}

class _RecordRoundStepsScreenState extends State<RecordRoundStepsScreen> {
  late final RecordRoundCubit _recordRoundCubit;

  // Text editing
  late final TextEditingController _textEditingController;
  late final FocusNode _focusNode;

  // State management
  bool _showingReviewGrid = false;

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
    _recordRoundCubit = BlocProvider.of<RecordRoundCubit>(context);
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _textEditingController.addListener(_onTextChanged);

    // Initialize voice service in cubit
    _recordRoundCubit.initializeVoiceService();

    // Load hole 1's saved text (if any)
    _loadTextFromCubit(0);
  }

  @override
  void dispose() {
    _recordRoundCubit.disposeVoiceService();
    _focusNode.removeListener(_onFocusChange);
    _textEditingController.removeListener(_onTextChanged);
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // User started typing, stop listening
      _recordRoundCubit.stopListening();
    }
    // Note: No need to save on unfocus - _onTextChanged handles it automatically
  }

  void _onTextChanged() {
    // Automatically update cubit state whenever text changes (typing, voice, etc.)
    _recordRoundCubit.updateCurrentHoleText(_textEditingController.text);
  }

  // Explicit load from cubit
  void _loadTextFromCubit(int holeIndex) {
    final RecordRoundState state = _recordRoundCubit.state;
    if (state is RecordRoundActive) {
      final String savedText = state.holeDescriptions[holeIndex] ?? '';
      _textEditingController.text = savedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GenericAppBar(
        topViewPadding: MediaQuery.of(context).viewPadding.top,
        title: 'Record round',
        hasBackButton: false,
        backgroundColor: Colors.transparent,
        leftWidget: _clearAllButton(),
        rightWidget: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      body: BlocConsumer<RecordRoundCubit, RecordRoundState>(
          listener: (context, recordRoundstate) {
            if (recordRoundstate is! RecordRoundActive) return;

            final String? holeText = recordRoundstate
                .holeDescriptions[recordRoundstate.currentHoleIndex];

            // Only update if text is different to avoid loops and unnecessary updates
            if (holeText != null && holeText != _textEditingController.text) {
              // Temporarily remove listener to prevent triggering _onTextChanged
              _textEditingController.removeListener(_onTextChanged);

              _textEditingController.text = holeText;
              _textEditingController.selection = TextSelection.fromPosition(
                TextPosition(offset: holeText.length),
              );

              // Re-add listener
              _textEditingController.addListener(_onTextChanged);
            }
          },
          listenWhen: (previous, current) {
            // Listen when hole descriptions change
            if (previous is RecordRoundActive && current is RecordRoundActive) {
              return previous.holeDescriptions != current.holeDescriptions;
            }
            return false;
          },
          builder: (context, recordRoundState) {
            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).viewPadding.top + 120,
                ),
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
                child: _mainBody(recordRoundState),
              ),
            );
          },
        ),
    );
  }

  Widget _mainBody(RecordRoundState recordRoundState) {
    if (_showingReviewGrid && recordRoundState is RecordRoundActive) {
      final Widget grid = TemporaryHolesReviewGrid(
        holeDescriptions: recordRoundState.holeDescriptions,
        onHoleTap: _onHoleTapFromGrid,
        onFinishAndParse: _finishAndParse,
        onBack: () => setState(() => _showingReviewGrid = false),
        allHolesFilled: _areAllHolesFilled(),
        bottomViewPadding: widget.bottomViewPadding,
      );

      if (widget.skipIntroAnimations) {
        return grid;
      }

      return grid
          .animate()
          .scale(
            begin: const Offset(0.85, 0.85),
            end: const Offset(1.0, 1.0),
            duration: 300.ms,
            curve: Curves.easeOutBack,
          )
          .fadeIn(duration: 250.ms, curve: Curves.easeOut);
    }

    final Widget entryView = _buildHoleEntryView(recordRoundState);

    if (widget.skipIntroAnimations) {
      return entryView;
    }

    return entryView
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
    if (recordRoundState is! RecordRoundActive) {
      return const SizedBox();
    }

    final bool isListening = recordRoundState.isListening;
    final bool isStartingListening = recordRoundState.isStartingListening;

    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 16, right: 16),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom,
        ),
        height:
            MediaQuery.of(context).size.height -
            (MediaQuery.of(context).viewPadding.top + 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(recordRoundState),
            const SizedBox(height: 12),
            Expanded(child: _buildVoiceCard(isListening)),
            const SizedBox(height: 20),
            Center(
              child: _buildMicrophoneButton(
                isListening,
                recordRoundState.pausingBetweenHoles,
                isStartingListening,
              ),
            ),
            const SizedBox(height: 20),
            if (kDebugMode || kReleaseMode) _buildDebugButtons(),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(RecordRoundActive state) {
    final int currentHoleIndex = state.currentHoleIndex;
    final double progress = (currentHoleIndex + 1) / totalHoles;

    return Column(
      children: [
        // Course card (blue tint)
        _buildCourseCard(state),
        const SizedBox(height: 8),
        // Date card (green tint)
        _buildDateCard(state),
        const SizedBox(height: 8),
        // Hole Progress Card
        GestureDetector(
          onTap: _showReviewGrid,
          behavior: HitTestBehavior.translucent,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: showHoleProgressLabel ? 8 : 12,
              horizontal: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                if (showHoleProgressLabel)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Hole ${currentHoleIndex + 1} of $totalHoles',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
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
                  if (showHoleProgressLabel) const SizedBox(height: 12),
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
                  if (showHoleProgressLabel) const SizedBox(height: 12),
                  _MiniHolesGrid(
                    state: state,
                    currentHoleIndex: currentHoleIndex,
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

  Widget _buildVoiceCard(bool isListening) {
    final Widget card = VoiceDescriptionCard(
      controller: _textEditingController,
      focusNode: _focusNode,
      isListening: isListening,
      accent: _descAccent,
      onClear: _handleClearText,
      isSingleHole: true,
    );

    return widget.skipIntroAnimations
        ? card
        : card
              .animate(delay: 180.ms)
              .fadeIn(duration: 280.ms, curve: Curves.easeOut)
              .slideY(
                begin: 0.08,
                end: 0.0,
                duration: 280.ms,
                curve: Curves.easeOut,
              );
  }

  Widget _buildMicrophoneButton(
    bool isListening,
    bool pausingBetweenHoles,
    bool isStartingListening,
  ) {
    final Widget button = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            isListening
                ? const Color(0xFFFF7A7A).withValues(alpha: 0.06)
                : const Color(0xFF2196F3).withValues(alpha: 0.06),
            Colors.transparent,
          ],
          stops: const [0.4, 1.0],
        ),
      ),
      child: AnimatedMicrophoneButton(
        showListeningWaveState: isListening || pausingBetweenHoles,
        isLoading: isStartingListening,
        onTap: _toggleListening,
      ),
    );

    return widget.skipIntroAnimations
        ? button
        : button
              .animate(delay: 270.ms)
              .fadeIn(duration: 300.ms, curve: Curves.easeOut)
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.0, 1.0),
                duration: 300.ms,
                curve: Curves.easeOutBack,
              );
  }

  Widget _buildCourseCard(RecordRoundActive state) {
    final Widget card = RoundDataInputCard(
      icon: Icons.landscape,
      subtitle: state.selectedCourse ?? 'Select a course',
      onTap: _showCourseSelector,
      accent: _courseAccent,
    );

    return widget.skipIntroAnimations
        ? card
        : card
              .animate()
              .fadeIn(duration: 280.ms, curve: Curves.easeOut)
              .slideY(
                begin: 0.08,
                end: 0.0,
                duration: 280.ms,
                curve: Curves.easeOut,
              );
  }

  Widget _buildDateCard(RecordRoundActive state) {
    final Widget card = RoundDataInputCard(
      icon: Icons.access_time,
      subtitle: _formatDateTime(state.selectedDateTime),
      onTap: _showDateTimeEditor,
      accent: _dateAccent,
    );

    return widget.skipIntroAnimations
        ? card
        : card
              .animate(delay: 90.ms)
              .fadeIn(duration: 280.ms, curve: Curves.easeOut)
              .slideY(
                begin: 0.08,
                end: 0.0,
                duration: 280.ms,
                curve: Curves.easeOut,
              );
  }

  Widget _buildNavigationButtons() {
    final RecordRoundState state = _recordRoundCubit.state;
    if (state is! RecordRoundActive) return const SizedBox();

    final int currentHoleIndex = state.currentHoleIndex;
    final bool allHolesFilled = _areAllHolesFilled();
    final bool isFirstHole = currentHoleIndex == 0;
    final bool isLastHole = currentHoleIndex == totalHoles - 1;
    final bool showFinalize = isLastHole;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;

        // Calculate previous button width
        final double previousButtonWidth = isFirstHole
            ? 0.0
            : isLastHole
            ? 56.0
            : (maxWidth - 8) / 2;

        return Row(
          children: [
            _AnimatedPreviousButton(
              isFirstHole: isFirstHole,
              isLastHole: isLastHole,
              targetWidth: previousButtonWidth,
              onPressed: _previousHole,
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: isFirstHole ? 0 : 8,
            ),
            Expanded(
              child: PrimaryButton(
                label: showFinalize ? 'Finalize' : 'Next',
                width: double.infinity,
                height: 56,
                backgroundColor: showFinalize ? Colors.green : Colors.blue,
                labelColor: Colors.white,
                icon: showFinalize ? Icons.check : null,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                disabled:
                    !(kDebugMode || kReleaseMode) &&
                    (isLastHole && !allHolesFilled),
                onPressed: showFinalize ? _finishAndParse : _nextHole,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDebugButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          PrimaryButton(
            label: 'Change',
            width: 100,
            height: 56,
            backgroundColor: _createAccent.withValues(alpha: 0.18),
            labelColor: _createAccent,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            onPressed: _showTestConstantSelector,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PrimaryButton(
              label: 'Parse',
              width: double.infinity,
              height: 56,
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
                            _recordRoundCubit.setSelectedCourse(course);
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
                  _recordRoundCubit.setSelectedCourse(name);
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
      final DateTime updatedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _selectedDateTime.hour,
        _selectedDateTime.minute,
      );
      setState(() {
        _selectedDateTime = updatedDateTime;
      });
      _recordRoundCubit.setSelectedTime(updatedDateTime);
      return;
    }

    final DateTime updatedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    setState(() {
      _selectedDateTime = updatedDateTime;
    });
    _recordRoundCubit.setSelectedTime(updatedDateTime);
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
    if (_recordRoundCubit.state is! RecordRoundActive) return false;
    final RecordRoundActive state =
        _recordRoundCubit.state as RecordRoundActive;
    for (int i = 0; i < totalHoles; i++) {
      final String? description = state.holeDescriptions[i];
      if (description == null || description.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  Future<void> _previousHole() async {
    final RecordRoundState state = _recordRoundCubit.state;
    if (state is! RecordRoundActive) return;

    if (state.currentHoleIndex > 0) {
      // Save any manual edits before navigating
      _recordRoundCubit.updateCurrentHoleText(_textEditingController.text);

      await _recordRoundCubit.navigateToHole(state.currentHoleIndex - 1);
      _loadTextFromCubit(state.currentHoleIndex - 1);
    }
  }

  Future<void> _nextHole() async {
    final RecordRoundState state = _recordRoundCubit.state;
    if (state is! RecordRoundActive) return;

    if (state.currentHoleIndex < totalHoles - 1) {
      // Save any manual edits before navigating
      _recordRoundCubit.updateCurrentHoleText(_textEditingController.text);

      await _recordRoundCubit.navigateToHole(state.currentHoleIndex + 1);
      _loadTextFromCubit(state.currentHoleIndex + 1);
    } else {
      _finishAndParse();
    }
  }

  void _showReviewGrid() {
    if (showInlineMiniHoleGrid) {
      return;
    }
    setState(() => _showingReviewGrid = true);
  }

  Future<void> _onHoleTapFromGrid(int holeIndex) async {
    // Save any manual edits before navigating
    _recordRoundCubit.updateCurrentHoleText(_textEditingController.text);

    await _recordRoundCubit.navigateToHole(holeIndex);
    setState(() => _showingReviewGrid = false);
    _loadTextFromCubit(holeIndex);
  }

  void _finishAndParse() {
    final RecordRoundActive state =
        _recordRoundCubit.state as RecordRoundActive;
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(
        builder: (context) => RoundProcessingLoadingScreen(
          transcript: state.fullTranscript,
          courseName: state.selectedCourse ?? 'Unknown Course',
          numHoles: state.numHoles,
          useSharedPreferences: false,
        ),
      ),
    );
  }

  Future<void> _toggleListening() async {
    FocusScope.of(context).unfocus();
    _recordRoundCubit.toggleListening();
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
    _textEditingController.clear();
    _recordRoundCubit.clearCurrentHoleText();
  }

  Future<void> _handleClearAll() async {
    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    await _recordRoundCubit.clearAllHoles();

    // // Show confirmation dialog
    // final bool? confirmed = await showDialog<bool>(
    //   context: context,
    //   builder: (context) {
    //     return AlertDialog(
    //       title: const Text('Clear All Data?'),
    //       content: const Text(
    //         'This will discard all hole descriptions and reset the recording. This cannot be undone.',
    //       ),
    //       actions: [
    //         TextButton(
    //           onPressed: () => Navigator.of(context).pop(false),
    //           child: const Text('Cancel'),
    //         ),
    //         TextButton(
    //           onPressed: () => Navigator.of(context).pop(true),
    //           child: Text(
    //             'Clear All',
    //             style: TextStyle(
    //               color: Colors.red.shade600,
    //               fontWeight: FontWeight.bold,
    //             ),
    //           ),
    //         ),
    //       ],
    //     );
    //   },
    // );

    // // If user confirmed, reset the recording
    // if (confirmed == true) {
    // await _recordRoundCubit.resetRecording();
    // }
  }

  Widget _clearAllButton() {
    return GestureDetector(
      onTap: _handleClearAll,
      child: Container(
        width: 40,
        color: Colors.transparent,
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleParse() {
    final bool useCached = false;
    debugPrint('Test Parse Constant: Using cached round: $useCached');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
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

/// Animated previous button that smoothly transitions between full-width with text
/// and icon-only modes without using AnimatedSwitcher
class _AnimatedPreviousButton extends StatelessWidget {
  const _AnimatedPreviousButton({
    required this.isFirstHole,
    required this.isLastHole,
    required this.targetWidth,
    required this.onPressed,
  });

  final bool isFirstHole;
  final bool isLastHole;
  final double targetWidth;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      opacity: isFirstHole ? 0.0 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: targetWidth,
        height: 56,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onPressed();
            },
            borderRadius: BorderRadius.circular(32),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Text - visible when NOT last hole
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      opacity: isLastHole ? 0.0 : 1.0,
                      child: Text(
                        'Previous',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Icon - visible when IS last hole
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      opacity: isLastHole ? 1.0 : 0.0,
                      child: Icon(
                        FlutterRemix.arrow_left_s_line,
                        color: Colors.grey.shade700,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
        height: 40,
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isCurrent
              ? _holeAccent.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isCurrent ? _holeAccent : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              '$holeNumber',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isCurrent ? _holeAccent : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 2),
            Icon(
              isComplete ? Icons.check_circle : Icons.circle_outlined,
              size: 14,
              color: isComplete ? Colors.green : Colors.grey[400],
            ),
          ],
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
