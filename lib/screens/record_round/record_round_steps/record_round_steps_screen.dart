import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/buttons/animated_microphone_button.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/cards/round_data_input_card.dart';
import 'package:turbo_disc_golf/components/panels/select_image_source_panel.dart';
import 'package:turbo_disc_golf/components/voice_input/voice_description_card.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/screens/record_round/record_round_steps/panels/select_course_panel.dart';
import 'package:turbo_disc_golf/screens/round_history/components/temporary_holes_review_grid.dart';
import 'package:turbo_disc_golf/screens/round_processing/round_processing_loading_screen.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';
import 'package:turbo_disc_golf/state/record_round_cubit.dart';
import 'package:turbo_disc_golf/state/record_round_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
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
  bool _isParsingScorecard = false;

  // Course/Date selection (Step 1)
  DateTime _selectedDateTime = DateTime.now();

  // Accent colors
  static const Color _descAccent = Color(0xFFB39DDB); // light purple
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
    final RecordRoundState state = _recordRoundCubit.state;
    if (state is RecordRoundActive) {
      _loadTextFromCubit(state.currentHoleIndex);
    }
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          56 + MediaQuery.of(context).viewPadding.top,
        ),
        child: Stack(
          children: [
            // Hero widget that morphs from banner - fades to transparent
            Positioned.fill(
              child: Hero(
                tag: 'record_round_header',
                flightShuttleBuilder:
                    (
                      BuildContext flightContext,
                      Animation<double> animation,
                      HeroFlightDirection flightDirection,
                      BuildContext fromHeroContext,
                      BuildContext toHeroContext,
                    ) {
                      // During the flight, fade out the banner content
                      return FadeTransition(
                        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: const Interval(
                              0.0,
                              0.7,
                              curve: Curves.easeOut,
                            ),
                          ),
                        ),
                        child:
                            (flightDirection == HeroFlightDirection.push
                                    ? fromHeroContext.widget
                                    : toHeroContext.widget)
                                as Hero,
                      );
                    },
                child: const SizedBox(height: 56),
              ),
            ),
            // GenericAppBar on top
            GenericAppBar(
              topViewPadding: MediaQuery.of(context).viewPadding.top,
              title: 'Record Round',
              hasBackButton: false,
              backgroundColor: Colors.transparent,
              leftWidget: _clearAllButton(),
              rightWidget: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _handleClose,
              ),
            ),
          ],
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
          return Stack(
            children: [
              GestureDetector(
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
              ),
              if (_isParsingScorecard) _buildParsingOverlay(),
            ],
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
            const SizedBox(height: 8),
            _buildHoleInfoCard(recordRoundState),
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
            // if (kDebugMode || kReleaseMode) _buildDebugButtons(),
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
        // Date card (2/3) + Import button (1/3)
        _buildDateAndImportRow(state),
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
    String subtitle;
    if (state.selectedCourse != null) {
      subtitle = state.selectedCourse!.name;
      if (state.selectedLayoutId != null) {
        final CourseLayout? layout = state.selectedCourse!.getLayoutById(
          state.selectedLayoutId!,
        );
        if (layout != null) {
          subtitle += ' • ${layout.name}';
        }
      }
    } else {
      subtitle = 'Select a course';
    }

    final Widget card = RoundDataInputCard(
      icon: Icons.landscape,
      subtitle: subtitle,
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

  Widget _buildDateAndImportRow(RecordRoundActive state) {
    final bool hasImportedScores = state.importedScores != null;

    final Widget row = Row(
      children: [
        // Date card (takes remaining space)
        Expanded(
          child: RoundDataInputCard(
            icon: Icons.access_time,
            subtitle: _formatDateTime(state.selectedDateTime),
            onTap: _showDateTimeEditor,
            accent: _dateAccent,
          ),
        ),
        const SizedBox(width: 8),
        // Import button (icon only)
        _buildImportScorecardButton(hasImportedScores),
      ],
    );

    return widget.skipIntroAnimations
        ? row
        : row
              .animate(delay: 90.ms)
              .fadeIn(duration: 280.ms, curve: Curves.easeOut)
              .slideY(
                begin: 0.08,
                end: 0.0,
                duration: 280.ms,
                curve: Curves.easeOut,
              );
  }

  Widget _buildImportScorecardButton(bool hasImportedScores) {
    const Color lightPurple = Color(0xFFE1BEE7); // lighter purple for gradient

    return GestureDetector(
      onTap: _handleImportScorecard,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImportedScores
                ? Colors.green.shade300
                : lightPurple.withValues(alpha: 0.5),
          ),
          gradient: LinearGradient(
            transform: const GradientRotation(0.785), // ~45 degrees
            colors: [
              hasImportedScores
                  ? Colors.green.shade50
                  : lightPurple.withValues(alpha: 0.3),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Icon(
            hasImportedScores ? Icons.check : Icons.photo_camera,
            size: 20,
            color: hasImportedScores ? Colors.green : TurbColors.darkGray,
          ),
        ),
      ),
    );
  }

  Widget _buildHoleInfoCard(RecordRoundActive state) {
    final int currentHoleIndex = state.currentHoleIndex;

    // Get course layout for par and distance
    final CourseLayout? layout =
        state.selectedCourse?.getLayoutById(state.selectedLayoutId ?? '') ??
        state.selectedCourse?.defaultLayout;

    // Get par and distance from course layout (authoritative source)
    int? par;
    int? feet;
    if (layout != null && currentHoleIndex < layout.holes.length) {
      par = layout.holes[currentHoleIndex].par;
      feet = layout.holes[currentHoleIndex].feet;
    }

    // Get imported score (if available)
    final int? score = state.importedScores?[currentHoleIndex];

    // Calculate relative score
    int? relativeScore;
    if (score != null && par != null) {
      relativeScore = score - par;
    }

    // Semantic colors
    const Color underPar = Color(0xFF137e66); // green
    const Color overPar = Color(0xFFFF7A7A); // red
    const Color atPar = Color(0xFF9E9E9E); // gray
    final Color naColor = Colors.grey.shade400;

    Color scoreColor = naColor;
    if (relativeScore != null) {
      if (relativeScore < 0) {
        scoreColor = underPar;
      } else if (relativeScore > 0) {
        scoreColor = overPar;
      } else {
        scoreColor = atPar;
      }
    }

    // Format relative score string
    String relativeScoreStr = '';
    if (relativeScore != null) {
      if (relativeScore > 0) {
        relativeScoreStr = ' (+$relativeScore)';
      } else if (relativeScore < 0) {
        relativeScoreStr = ' ($relativeScore)';
      } else {
        relativeScoreStr = ' (E)';
      }
    }

    // Format display strings with N/A fallbacks
    final String parStr = par != null ? 'Par $par' : 'Par N/A';
    final String distanceStr = feet != null ? '$feet ft' : 'N/A ft';
    final String scoreStr = score != null ? '$score$relativeScoreStr' : 'N/A';

    final Widget card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Line 1: Hole number
          Text(
            'Hole ${currentHoleIndex + 1}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          // Line 2: Par • Distance • Score
          Row(
            children: [
              Text(
                parStr,
                style: TextStyle(
                  fontSize: 13,
                  color: par != null ? Colors.grey.shade700 : naColor,
                ),
              ),
              _buildInfoSeparator(),
              Text(
                distanceStr,
                style: TextStyle(
                  fontSize: 13,
                  color: feet != null ? Colors.grey.shade700 : naColor,
                ),
              ),
              _buildInfoSeparator(),
              Text(
                'Score: ',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              Text(
                scoreStr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: score != null
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: score != null ? scoreColor : naColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return widget.skipIntroAnimations
        ? card
        : card
              .animate(delay: 120.ms)
              .fadeIn(duration: 280.ms, curve: Curves.easeOut)
              .slideY(
                begin: 0.08,
                end: 0.0,
                duration: 280.ms,
                curve: Curves.easeOut,
              );
  }

  Widget _buildInfoSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '•',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      ),
    );
  }

  Widget _buildParsingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(radius: 16),
                const SizedBox(height: 16),
                Text(
                  'Parsing scorecard...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  Future<void> _showCourseSelector() async {
    displayBottomSheet(
      context,
      SelectCoursePanel(
        topViewPadding: MediaQuery.of(context).viewPadding.top,
        bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
      ),
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
    HapticFeedback.lightImpact();
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
          selectedCourse: state.selectedCourse,
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

  void _handleClearText() {
    _textEditingController.clear();
    _recordRoundCubit.clearCurrentHoleText();
  }

  Future<void> _handleImportScorecard() async {
    HapticFeedback.lightImpact();
    String imagePath;

    // In debug mode with test constant enabled, use test scorecard directly
    if (kDebugMode && useTestScorecardForImport) {
      debugPrint('Using test scorecard: $testScorecardPath');
      // Copy asset to temp file since parseScorecard needs a filesystem path
      final ByteData data = await rootBundle.load(testScorecardPath);
      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/test_scorecard.jpeg');
      await tempFile.writeAsBytes(data.buffer.asUint8List());
      imagePath = tempFile.path;
      debugPrint('Temp file created at: $imagePath');
    } else {
      // Show image source selection panel
      final ImageSource? source = await SelectImageSourcePanel.show(context);
      if (source == null || !mounted) return;

      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (image == null || !mounted) return;
      imagePath = image.path;
    }

    // Show loading overlay
    setState(() => _isParsingScorecard = true);

    try {
      List<HoleMetadata> holeMetadata;

      // Use mock data if enabled (skips AI parsing entirely)
      if (kDebugMode && useMockScorecardData) {
        debugPrint('Using mock scorecard data (skipping AI parsing)');
        holeMetadata = testScorecardData.map((Map<String, int> data) {
          return HoleMetadata(
            holeNumber: data['holeNumber']!,
            score: data['score']!,
            par: data['par']!,
            distanceFeet: data['distanceFeet'],
          );
        }).toList();
      } else {
        // Parse the scorecard image using AI
        holeMetadata = await locator
            .get<AiParsingService>()
            .parseScorecard(imagePath: imagePath);
      }

      if (!mounted) return;

      // Hide loading overlay
      setState(() => _isParsingScorecard = false);

      // Debug print without truncation for test data extraction
      if (kDebugMode && useTestScorecardForImport && !useMockScorecardData) {
        debugPrint('=== PARSED SCORECARD DATA (copy for testing) ===');
        debugPrint('Total holes parsed: ${holeMetadata.length}');
        for (final HoleMetadata hole in holeMetadata) {
          // Using print instead of debugPrint to avoid truncation
          // ignore: avoid_print
          print(
            'Hole ${hole.holeNumber}: score=${hole.score}, '
            'par=${hole.par}, distanceFeet=${hole.distanceFeet}',
          );
        }
        debugPrint('=== RAW DATA FOR CONSTANT ===');
        final StringBuffer buffer = StringBuffer();
        buffer.writeln('const List<Map<String, int>> testScorecardData = [');
        for (final HoleMetadata hole in holeMetadata) {
          buffer.writeln(
            "  {'holeNumber': ${hole.holeNumber}, 'score': ${hole.score}, "
            "'par': ${hole.par}, 'distanceFeet': ${hole.distanceFeet ?? 0}},",
          );
        }
        buffer.writeln('];');
        // ignore: avoid_print
        print(buffer.toString());
        debugPrint('=== END PARSED DATA ===');
      }

      if (holeMetadata.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not parse scorecard. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Update state with full metadata (scores, par, distance)
      _recordRoundCubit.setImportedHoleMetadata(holeMetadata);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${holeMetadata.length} hole scores'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isParsingScorecard = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error parsing scorecard: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleClearAll() async {
    HapticFeedback.lightImpact();
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
    return IconButton(
      icon: Icon(Icons.delete_sweep, color: Colors.grey.shade600),
      onPressed: _handleClearAll,
      tooltip: 'Clear All',
    );
  }

  void _handleClose() {
    HapticFeedback.lightImpact();
    // Check if any holes have descriptions - if not, reset to inactive state
    final RecordRoundState state = _recordRoundCubit.state;
    if (state is RecordRoundActive) {
      bool anyHolesFilled = false;
      for (int i = 0; i < totalHoles; i++) {
        final String? description = state.holeDescriptions[i];
        if (description != null && description.trim().isNotEmpty) {
          anyHolesFilled = true;
          break;
        }
      }

      // If no holes are filled, reset to inactive state
      if (!anyHolesFilled) {
        _recordRoundCubit.clearOnLogout();
      }
    }

    Navigator.of(context).pop();
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
    required this.hasDescription,
    required this.isCurrent,
    required this.onTap,
    this.score,
    this.par,
  });

  final int holeNumber;
  final bool hasDescription;
  final bool isCurrent;
  final VoidCallback onTap;
  final int? score;
  final int? par;

  static const Color _holeAccent = Color(0xFF2196F3); // blue
  static const Color _descriptionComplete = Color(0xFFE8F5E9); // light green
  static const Color _underPar = Color(0xFF137e66); // green (birdie/eagle)
  static const Color _overPar = Color(0xFFFF7A7A); // red (bogey+)
  static const Color _atPar = Color(0xFF9E9E9E); // gray (par)
  static const Color _noScore = Color(0xFFE0E0E0); // light gray (no score)

  Color _getScoreColor() {
    if (score == null || par == null) return _noScore;
    final int relative = score! - par!;
    if (relative < 0) return _underPar;
    if (relative > 0) return _overPar;
    return _atPar;
  }

  @override
  Widget build(BuildContext context) {
    final Color circleColor = _getScoreColor();
    final bool hasScore = score != null;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isCurrent
              ? _holeAccent.withValues(alpha: 0.1)
              : hasDescription
              ? _descriptionComplete
              : Colors.transparent,
          border: Border.all(
            color: isCurrent ? _holeAccent : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
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
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasScore ? circleColor.withValues(alpha: 0.15) : null,
                border: Border.all(
                  color: circleColor,
                  width: hasScore ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: hasScore
                    ? Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: circleColor,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini holes grid for inline display - 9 holes per row (2 rows for 18 holes)
class _MiniHolesGrid extends StatelessWidget {
  const _MiniHolesGrid({
    required this.state,
    required this.currentHoleIndex,
    required this.onHoleTap,
  });

  final RecordRoundActive state;
  final int currentHoleIndex;
  final Function(int) onHoleTap;

  static const int _holesPerRow = 9;

  @override
  Widget build(BuildContext context) {
    // Get the layout for par values
    final CourseLayout? layout =
        state.selectedCourse?.getLayoutById(state.selectedLayoutId ?? '') ??
        state.selectedCourse?.defaultLayout;

    // Calculate number of rows needed
    final int numRows = (totalHoles / _holesPerRow).ceil();

    return Column(
      children: List.generate(numRows, (rowIndex) {
        final int startHole = rowIndex * _holesPerRow;
        final int endHole = (startHole + _holesPerRow).clamp(0, totalHoles);

        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex < numRows - 1 ? 4 : 0),
          child: Row(
            children: List.generate(endHole - startHole, (colIndex) {
              final int index = startHole + colIndex;
              final String? description = state.holeDescriptions[index];
              final bool hasDescription =
                  description != null && description.trim().isNotEmpty;
              final bool isCurrent = index == currentHoleIndex;

              // Get score from imported scorecard (if available)
              final int? score = state.importedScores?[index];

              // Get par from course layout (if available)
              int? par;
              if (layout != null && index < layout.holes.length) {
                par = layout.holes[index].par;
              }

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: colIndex < _holesPerRow - 1 ? 4 : 0,
                  ),
                  child: _MiniHoleIndicator(
                    holeNumber: index + 1,
                    hasDescription: hasDescription,
                    isCurrent: isCurrent,
                    score: score,
                    par: par,
                    onTap: () => onHoleTap(index),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
