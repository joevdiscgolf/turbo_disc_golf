import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/buttons/animated_microphone_button.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/cards/round_data_input_card.dart';
import 'package:turbo_disc_golf/components/education/hole_description_examples_screen.dart';
import 'package:turbo_disc_golf/components/panels/date_time_picker_panel.dart';
import 'package:turbo_disc_golf/components/panels/select_image_source_panel.dart';
import 'package:turbo_disc_golf/components/voice_input/voice_description_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/screens/record_round/record_round_steps/panels/select_course_panel.dart';
import 'package:turbo_disc_golf/screens/round_history/components/temporary_holes_review_grid.dart';
import 'package:turbo_disc_golf/screens/round_processing/round_processing_loading_screen.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/state/record_round_cubit.dart';
import 'package:turbo_disc_golf/state/record_round_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/description_constants.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';
import 'package:turbo_disc_golf/utils/panel_helpers.dart';

const String testCourseName = 'Foxwood';
const int totalHoles = 18;
const String _hasSeenEducationKey = 'hasSeenHoleDescriptionEducation';

class RecordRoundStepsScreen extends StatefulWidget {
  const RecordRoundStepsScreen({
    super.key,
    required this.bottomViewPadding,
    this.skipIntroAnimations = false,
  });

  static const String screenName = 'Record Round Steps';
  static const String routeName = '/record-round-steps';

  final double bottomViewPadding;
  final bool skipIntroAnimations;

  @override
  State<RecordRoundStepsScreen> createState() => _RecordRoundStepsScreenState();
}

class _RecordRoundStepsScreenState extends State<RecordRoundStepsScreen> {
  late final RecordRoundCubit _recordRoundCubit;
  late final LoggingServiceBase _logger;

  // Text editing
  late final TextEditingController _textEditingController;
  late final FocusNode _focusNode;

  // State management
  bool _showingReviewGrid = false;
  bool _isParsingScorecard = false;

  // Course/Date selection (Step 1)
  DateTime _selectedDateTime = DateTime.now();

  // Debug test descriptions
  int _selectedTestDescriptionIndex = 0;
  static const List<String> _testRoundDescriptions = [
    DescriptionConstants.testRoundDescription,
    DescriptionConstants.testRoundDescription2,
    DescriptionConstants.testRoundDescription3,
    DescriptionConstants.testRoundDescription4,
    DescriptionConstants.flingsGivingRound2Description,
    DescriptionConstants.elevenUnderWhitesDescriptionNoHoleDistance,
  ];
  static const List<String> _testRoundDescriptionNames = [
    'testRoundDescription',
    'testRoundDescription2',
    'testRoundDescription3',
    'testRoundDescription4',
    'flingsGivingRound2Description',
    'elevenUnderWhitesDescriptionNoHoleDistance',
  ];

  // Accent colors
  static const Color _descAccent = Color(0xFFB39DDB); // light purple
  static const Color _courseAccent = Color(0xFF2196F3); // blue
  static const Color _dateAccent = Color(0xFF4CAF50); // green

  @override
  void initState() {
    super.initState();

    // Create scoped logger with base properties
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({
      'screen_name': RecordRoundStepsScreen.screenName,
    });

    // Track screen impression
    _logger.logScreenImpression('RecordRoundStepsScreen');

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

    // Check if first-time user and show education screen
    _checkFirstTimeEducation();
  }

  Future<void> _checkFirstTimeEducation() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool hasSeenEducation = prefs.getBool(_hasSeenEducationKey) ?? false;

    if (!hasSeenEducation && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await HoleDescriptionExamplesScreen.show(context);
          await prefs.setBool(_hasSeenEducationKey, true);
        }
      });
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
                onPressed: () {
                  _logger.track(
                    'Close Button Tapped',
                    properties: {'has_unsaved_data': _hasUnsavedData()},
                  );
                  _handleClose();
                },
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
                    top: MediaQuery.of(context).viewPadding.top + 112,
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
    final double bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomPadding + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(recordRoundState),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildHoleInfoCard(recordRoundState),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(height: 200, child: _buildVoiceCard(isListening)),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDebugButtons(),
            ),
          ],
          const SizedBox(height: 20),
          Center(
            child: _buildMicrophoneButton(
              isListening,
              recordRoundState.pausingBetweenHoles,
              isStartingListening,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildNavigationButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(RecordRoundActive state) {
    final int currentHoleIndex = state.currentHoleIndex;
    final int numHoles = state.numHoles;
    final double progress = (currentHoleIndex + 1) / numHoles;

    return Column(
      children: [
        // Course card + Import button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildCourseAndImportRow(state),
        ),
        const SizedBox(height: 8),
        // Date card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildDateCard(state),
        ),
        const SizedBox(height: 8),
        // Hole Progress / Mini Holes Grid
        if (showInlineMiniHoleGrid) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _MiniHolesGrid(
                state: state,
                currentHoleIndex: currentHoleIndex,
                onHoleTap: _onHoleTapFromGrid,
              ),
            ),
          ),
        ] else ...[
          // Fallback to progress bar in card (when grid is disabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                _logger.track(
                  'Progress Card Button Tapped',
                  properties: {'current_hole': currentHoleIndex + 1},
                );
                _showReviewGrid();
              },
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
                              'Hole ${currentHoleIndex + 1} of $numHoles',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
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
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVoiceCard(bool isListening) {
    final Widget card = VoiceDescriptionCard(
      controller: _textEditingController,
      focusNode: _focusNode,
      isListening: isListening,
      accent: _descAccent,
      onClear: () {
        _logger.track(
          'Clear Text Button Tapped',
          properties: {
            'hole_number': _recordRoundCubit.state is RecordRoundActive
                ? (_recordRoundCubit.state as RecordRoundActive)
                          .currentHoleIndex +
                      1
                : null,
          },
        );
        _handleClearText();
      },
      isSingleHole: true,
      onHelpTap: () {
        _logger.track('Help Button Tapped', properties: {});

        _logger.track(
          'Modal Opened',
          properties: {
            'modal_type': 'full_screen_modal',
            'modal_name': 'Hole Description Examples',
            'trigger_source': 'button',
          },
        );

        HoleDescriptionExamplesScreen.show(context);
      },
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
        onTap: () {
          final RecordRoundState state = _recordRoundCubit.state;
          final bool willBeListening = state is RecordRoundActive
              ? !state.isListening
              : true;
          final int? currentHole = state is RecordRoundActive
              ? state.currentHoleIndex + 1
              : null;

          _logger.track(
            'Microphone Button Tapped',
            properties: {
              'action': willBeListening ? 'start_listening' : 'stop_listening',
              'hole_number': currentHole,
            },
          );

          _toggleListening();
        },
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

  Widget _buildDebugButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          // Dropdown to select test description
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: DropdownButton<int>(
                value: _selectedTestDescriptionIndex,
                isExpanded: true,
                underline: const SizedBox(),
                items: List.generate(
                  _testRoundDescriptions.length,
                  (index) => DropdownMenuItem<int>(
                    value: index,
                    child: Text(
                      _testRoundDescriptionNames[index],
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                onChanged: (int? newIndex) {
                  if (newIndex != null) {
                    setState(() {
                      _selectedTestDescriptionIndex = newIndex;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Parse button
          Expanded(
            child: PrimaryButton(
              label: 'Parse',
              width: double.infinity,
              height: 44,
              backgroundColor: Colors.orange,
              labelColor: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              onPressed: () {
                HapticFeedback.lightImpact();
                _parseTestDescription();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseAndImportRow(RecordRoundActive state) {
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

    // Use orange gradient when no course selected, blue when selected
    final Color courseAccent = state.selectedCourse != null
        ? _courseAccent
        : const Color(0xFFFF9800); // Orange to draw attention

    final Widget row = Row(
      children: [
        // Course card (takes remaining space)
        Expanded(
          child: RoundDataInputCard(
            icon: Icons.landscape,
            subtitle: subtitle,
            onTap: () {
              _logger.track(
                'Select Course Button Tapped',
                properties: {
                  'has_course_selected': state.selectedCourse != null,
                },
              );

              _logger.track(
                'Modal Opened',
                properties: {
                  'modal_type': 'bottom_sheet',
                  'modal_name': 'Course Selector',
                  'trigger_source': 'button',
                },
              );

              _showCourseSelector();
            },
            accent: courseAccent,
          ),
        ),
        const SizedBox(width: 8),
        // Import button (icon only)
        _buildImportScorecardButton(),
      ],
    );

    return widget.skipIntroAnimations
        ? row
        : row
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
      onTap: () {
        _logger.track('Select Date Time Button Tapped', properties: {});

        _logger.track(
          'Modal Opened',
          properties: {
            'modal_type': 'bottom_sheet',
            'modal_name': 'Date Time Picker',
            'trigger_source': 'button',
          },
        );

        _showDateTimeEditor();
      },
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

  Widget _buildImportScorecardButton() {
    const Color lightPurple = Color(0xFFE1BEE7); // lighter purple for gradient

    return GestureDetector(
      onTap: () {
        _logger.track('Import Scorecard Button Tapped', properties: {});

        _logger.track(
          'Modal Opened',
          properties: {
            'modal_type': 'bottom_sheet',
            'modal_name': 'Image Source Selection',
            'trigger_source': 'button',
          },
        );

        _handleImportScorecard();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: lightPurple.withValues(alpha: 0.5)),
          gradient: LinearGradient(
            transform: const GradientRotation(0.785), // ~45 degrees
            colors: [lightPurple.withValues(alpha: 0.3), Colors.white],
          ),
        ),
        child: Center(
          child: Icon(Icons.photo_camera, size: 20, color: TurbColors.darkGray),
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

    // Format display strings
    final String parStr = par?.toString() ?? '-';
    final String distanceStr = feet != null ? '$feet ft' : '-';

    final Widget card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Par section
            Expanded(
              child: _buildInfoSection(
                label: 'Par',
                value: parStr,
                valueColor: par != null
                    ? Colors.grey.shade800
                    : Colors.grey.shade400,
              ),
            ),
            _buildVerticalDivider(),
            // Score section (editable)
            Expanded(
              child: _buildEditableScoreSection(
                score: score,
                par: par,
                holeIndex: currentHoleIndex,
              ),
            ),
            _buildVerticalDivider(),
            // Distance section
            Expanded(
              child: _buildInfoSection(
                label: 'Distance',
                value: distanceStr,
                valueColor: feet != null
                    ? Colors.grey.shade800
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
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

  Widget _buildInfoSection({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableScoreSection({
    required int? score,
    required int? par,
    required int holeIndex,
  }) {
    // Calculate relative score for color coding
    int? relativeScore;
    if (score != null && par != null) {
      relativeScore = score - par;
    }
    final Color scoreColor = _getScoreColorForRelative(relativeScore);
    final Color displayColor = score != null
        ? scoreColor
        : Colors.grey.shade400;

    // Buttons are disabled when there's no score
    final bool hasScore = score != null;
    final Color buttonColor = hasScore
        ? TurbColors.gray[600]!
        : Colors.grey.shade300;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Score',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Minus button - flexible to allow shrinking
            Flexible(
              child: GestureDetector(
                onTap: hasScore
                    ? () {
                        _logger.track(
                          'Decrement Score Button Tapped',
                          properties: {
                            'hole_number': holeIndex + 1,
                            'previous_score': score,
                            'new_score': score - 1,
                          },
                        );

                        HapticFeedback.lightImpact();
                        _recordRoundCubit.decrementHoleScore(holeIndex);
                      }
                    : null,
                behavior: HitTestBehavior.opaque,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 32,
                    maxWidth: 32,
                    maxHeight: 32,
                  ),
                  child: Center(
                    child: Icon(Icons.remove, size: 18, color: buttonColor),
                  ),
                ),
              ),
            ),
            // Score display - fixed size
            Text(
              score?.toString() ?? '-',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: displayColor,
              ),
            ),
            // Plus button - flexible to allow shrinking
            Flexible(
              child: GestureDetector(
                onTap: hasScore
                    ? () {
                        _logger.track(
                          'Increment Score Button Tapped',
                          properties: {
                            'hole_number': holeIndex + 1,
                            'previous_score': score,
                            'new_score': score + 1,
                          },
                        );

                        HapticFeedback.lightImpact();
                        _recordRoundCubit.incrementHoleScore(holeIndex);
                      }
                    : null,
                behavior: HitTestBehavior.opaque,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 32,
                    maxWidth: 32,
                    maxHeight: 32,
                  ),
                  child: Center(
                    child: Icon(Icons.add, size: 18, color: buttonColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.grey.shade300,
    );
  }

  /// Returns the appropriate color for a score based on relative to par.
  /// Matches the design from CompactScorecard.
  Color _getScoreColorForRelative(int? scoreToPar) {
    if (scoreToPar == null) return Colors.grey.shade400;
    if (scoreToPar == 0) {
      return Colors.grey.shade700; // Par - neutral
    } else if (scoreToPar <= -3) {
      return const Color(0xFFFFD700); // Albatross or better - gold
    } else if (scoreToPar == -2) {
      return const Color(0xFF2196F3); // Eagle - blue
    } else if (scoreToPar == -1) {
      return const Color(0xFF137e66); // Birdie - green
    } else if (scoreToPar == 1) {
      return const Color(0xFFFF7A7A); // Bogey - light red
    } else if (scoreToPar == 2) {
      return const Color(0xFFE53935); // Double bogey - medium red
    } else {
      return const Color(0xFFB71C1C); // Triple bogey+ - dark red
    }
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
    final int numHoles = state.numHoles;
    final bool allHolesFilled = _areAllHolesFilled();
    final bool isFirstHole = currentHoleIndex == 0;
    final bool isLastHole = currentHoleIndex == numHoles - 1;
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
              onPressed: () {
                _logger.track(
                  'Previous Hole Button Tapped',
                  properties: {
                    'current_hole': currentHoleIndex + 1,
                    'previous_hole': currentHoleIndex,
                  },
                );
                _previousHole();
              },
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
                disabled: showFinalize && !allHolesFilled,
                onPressed: () {
                  final String eventName = showFinalize
                      ? 'Finalize Round Button Tapped'
                      : 'Next Hole Button Tapped';

                  _logger.track(
                    eventName,
                    properties: {
                      'current_hole': currentHoleIndex + 1,
                      'is_last_hole': isLastHole,
                      'next_hole': isLastHole ? null : currentHoleIndex + 2,
                    },
                  );

                  if (showFinalize) {
                    _finishAndParse();
                  } else {
                    _nextHole();
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCourseSelector() async {
    // Unfocus the text field before showing the course selector
    _focusNode.unfocus();

    displayBottomSheet(
      context,
      SelectCoursePanel(
        topViewPadding: MediaQuery.of(context).viewPadding.top,
        bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
      ),
    );
  }

  Future<void> _showDateTimeEditor() async {
    // Unfocus the text field before showing the date picker
    _focusNode.unfocus();

    if (useBeautifulDatePicker) {
      await _showBeautifulDateTimePicker();
    } else {
      await _showMaterialDateTimePicker();
    }
  }

  Future<void> _showBeautifulDateTimePicker() async {
    await DateTimePickerPanel.show(
      context: context,
      initialDateTime: _selectedDateTime,
      onConfirm: (DateTime updatedDateTime) {
        _logger.track(
          'Beautiful Date Time Picker Confirmed',
          properties: {'date_changed': updatedDateTime != _selectedDateTime},
        );

        setState(() {
          _selectedDateTime = updatedDateTime;
        });
        _recordRoundCubit.setSelectedTime(updatedDateTime);
      },
    );
  }

  Future<void> _showMaterialDateTimePicker() async {
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

      _logger.track(
        'Material Date Picker Confirmed',
        properties: {'date_changed': updatedDateTime != _selectedDateTime},
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

    _logger.track(
      'Material Date Time Picker Confirmed',
      properties: {'date_changed': updatedDateTime != _selectedDateTime},
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
    for (int i = 0; i < state.numHoles; i++) {
      final String? description = state.holeDescriptions[i];
      if (description == null || description.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  bool _hasUnsavedData() {
    final RecordRoundState state = _recordRoundCubit.state;
    if (state is! RecordRoundActive) return false;

    // Check if any holes have descriptions
    for (int i = 0; i < state.numHoles; i++) {
      final String? description = state.holeDescriptions[i];
      if (description != null && description.trim().isNotEmpty) {
        return true;
      }
    }

    // Check if course is selected
    return state.selectedCourse != null;
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

    if (state.currentHoleIndex < state.numHoles - 1) {
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
    final RecordRoundState state = _recordRoundCubit.state;
    final int? currentHole = state is RecordRoundActive
        ? state.currentHoleIndex + 1
        : null;

    _logger.track(
      'Hole Number Button Tapped',
      properties: {'from_hole': currentHole, 'to_hole': holeIndex + 1},
    );

    // Save any manual edits before navigating
    _recordRoundCubit.updateCurrentHoleText(_textEditingController.text);

    await _recordRoundCubit.navigateToHole(holeIndex);
    setState(() => _showingReviewGrid = false);
    _loadTextFromCubit(holeIndex);
  }

  void _finishAndParse() {
    final RecordRoundState state = _recordRoundCubit.state;
    final int numHoles = state is RecordRoundActive ? state.numHoles : 0;

    _logger.track(
      'Finish and Parse Button Tapped',
      properties: {
        'total_holes': numHoles,
        'holes_with_descriptions': _getHolesWithDescriptions(),
      },
    );

    _logger.track(
      'Navigation Action',
      properties: {
        'from_screen': RecordRoundStepsScreen.screenName,
        'to_screen': 'Round Processing Loading',
        'action_type': 'replace',
        'trigger': 'button',
      },
    );

    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(
        builder: (context) => const RoundProcessingLoadingScreen(),
      ),
    );
  }

  int _getHolesWithDescriptions() {
    final RecordRoundState state = _recordRoundCubit.state;
    if (state is! RecordRoundActive) return 0;

    return state.holeDescriptions.values
        .where((String description) => description.isNotEmpty)
        .length;
  }

  void _parseTestDescription() {
    // Update the cubit with the test transcript before navigating
    // Set hole 0's description to the full test transcript
    _recordRoundCubit.setHoleDescription(
      _testRoundDescriptions[_selectedTestDescriptionIndex],
      index: 0,
    );

    Navigator.of(context).pushReplacement(
      CupertinoPageRoute(
        builder: (context) => const RoundProcessingLoadingScreen(),
      ),
    );
  }

  Future<void> _toggleListening() async {
    FocusScope.of(context).unfocus();

    final RecordRoundState state = _recordRoundCubit.state;
    final bool willBeListening = state is RecordRoundActive
        ? !state.isListening
        : true;

    final String eventName = willBeListening
        ? 'Voice Input Started'
        : 'Voice Input Stopped';
    _logger.track(
      eventName,
      properties: {
        'hole_number': state is RecordRoundActive
            ? state.currentHoleIndex + 1
            : null,
      },
    );

    _recordRoundCubit.toggleListening();
  }

  void _handleClearText() {
    final RecordRoundState state = _recordRoundCubit.state;
    final int? holeNumber = state is RecordRoundActive
        ? state.currentHoleIndex + 1
        : null;
    final String clearedText = _textEditingController.text;

    _logger.track(
      'Hole Description Cleared',
      properties: {
        'hole_number': holeNumber,
        'text_length_cleared': clearedText.length,
      },
    );

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
        holeMetadata = await locator.get<AiParsingService>().parseScorecard(
          imagePath: imagePath,
        );
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

      _logger.track(
        'Scorecard Parsed Successfully',
        properties: {'holes_imported': holeMetadata.length},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${holeMetadata.length} hole scores'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isParsingScorecard = false);

      _logger.track(
        'Scorecard Parse Failed',
        properties: {'error': e.toString()},
      );

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

    _logger.track(
      'All Holes Cleared',
      properties: {'holes_cleared': _getHolesWithDescriptions()},
    );

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
      onPressed: () {
        final RecordRoundState state = _recordRoundCubit.state;
        final int numHoles = state is RecordRoundActive ? state.numHoles : 0;

        _logger.track(
          'Clear All Button Tapped',
          properties: {'total_holes': numHoles},
        );

        _handleClearAll();
      },
      tooltip: 'Clear All',
    );
  }

  void _handleClose() {
    HapticFeedback.lightImpact();
    // Check if any holes have descriptions or course is selected
    final RecordRoundState state = _recordRoundCubit.state;
    if (state is RecordRoundActive) {
      bool anyHolesFilled = false;
      for (int i = 0; i < state.numHoles; i++) {
        final String? description = state.holeDescriptions[i];
        if (description != null && description.trim().isNotEmpty) {
          anyHolesFilled = true;
          break;
        }
      }

      final bool hasCourseSelected = state.selectedCourse != null;

      // Only reset to inactive if no holes filled AND no course selected
      if (!anyHolesFilled && !hasCourseSelected) {
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

/// Paints a dashed rounded rectangle border
// class _DashedBorderPainter extends CustomPainter {
//   _DashedBorderPainter({
//     required this.color,
//     required this.borderRadius,
//     this.strokeWidth = 1.0,
//     this.dashWidth = 4.0,
//     this.dashSpace = 3.0,
//   });

//   final Color color;
//   final double borderRadius;
//   final double strokeWidth;
//   final double dashWidth;
//   final double dashSpace;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint paint = Paint()
//       ..color = color
//       ..strokeWidth = strokeWidth
//       ..style = PaintingStyle.stroke;

//     final RRect rrect = RRect.fromRectAndRadius(
//       Rect.fromLTWH(0, 0, size.width, size.height),
//       Radius.circular(borderRadius),
//     );

//     final Path path = Path()..addRRect(rrect);
//     final Path dashedPath = _createDashedPath(path);
//     canvas.drawPath(dashedPath, paint);
//   }

//   Path _createDashedPath(Path source) {
//     final Path dashedPath = Path();
//     for (final PathMetric metric in source.computeMetrics()) {
//       double distance = 0.0;
//       while (distance < metric.length) {
//         final double length = dashWidth.clamp(0, metric.length - distance);
//         dashedPath.addPath(
//           metric.extractPath(distance, distance + length),
//           Offset.zero,
//         );
//         distance += dashWidth + dashSpace;
//       }
//     }
//     return dashedPath;
//   }

//   @override
//   bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
//     return oldDelegate.color != color ||
//         oldDelegate.borderRadius != borderRadius ||
//         oldDelegate.strokeWidth != strokeWidth ||
//         oldDelegate.dashWidth != dashWidth ||
//         oldDelegate.dashSpace != dashSpace;
//   }
// }

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
  static const Color _noScore = Color(0xFFE0E0E0); // light gray (no score)
  static const Color _completeGreen = Color(0xFF4CAF50); // green for complete

  /// Returns the appropriate color for a score based on how far it is from par.
  /// Matches the design from CompactScorecard.
  Color _getScoreColor() {
    if (score == null || par == null) return _noScore;
    final int scoreToPar = score! - par!;
    if (scoreToPar == 0) {
      return Colors.transparent; // Par - no circle
    } else if (scoreToPar <= -3) {
      return const Color(0xFFFFD700); // Albatross or better - gold
    } else if (scoreToPar == -2) {
      return const Color(0xFF2196F3); // Eagle - blue
    } else if (scoreToPar == -1) {
      return const Color(0xFF137e66); // Birdie - green
    } else if (scoreToPar == 1) {
      return const Color(0xFFFF7A7A); // Bogey - light red
    } else if (scoreToPar == 2) {
      return const Color(0xFFE53935); // Double bogey - medium red
    } else {
      return const Color(0xFFB71C1C); // Triple bogey+ - dark red
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasScore = score != null && par != null;
    final bool isPar = hasScore && score == par;
    final Color circleColor = _getScoreColor();

    // Background and border: blue for current, green for complete, no border for incomplete
    BoxDecoration decoration;
    if (isCurrent) {
      decoration = BoxDecoration(
        color: _holeAccent.withValues(alpha: 0.1),
        border: Border.all(color: _holeAccent, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      );
    } else if (hasDescription) {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _completeGreen.withValues(alpha: 0.08),
            _completeGreen.withValues(alpha: 0.15),
          ],
        ),
        border: Border.all(color: _completeGreen, width: 1),
        borderRadius: BorderRadius.circular(6),
      );
    } else {
      decoration = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      );
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: decoration,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              _buildScoreIndicator(hasScore, isPar, circleColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(bool hasScore, bool isPar, Color circleColor) {
    // No score imported - show empty circle
    if (!hasScore) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _noScore, width: 1.5),
        ),
      );
    }

    // Par score - just show the number, no circle
    if (isPar) {
      return SizedBox(
        width: 20,
        height: 20,
        child: Center(
          child: Text(
            '$score',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      );
    }

    // Non-par score - solid color circle with white text
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(shape: BoxShape.circle, color: circleColor),
      child: Center(
        child: Text(
          '$score',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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

    // Use state.numHoles for variable hole count support
    final int numHoles = state.numHoles;

    // Calculate number of rows needed
    final int numRows = (numHoles / _holesPerRow).ceil();

    return Column(
      children: List.generate(numRows, (rowIndex) {
        final int startHole = rowIndex * _holesPerRow;
        final int endHole = (startHole + _holesPerRow).clamp(0, numHoles);
        final int holesInRow = endHole - startHole;

        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex < numRows - 1 ? 8 : 0),
          child: Row(
            children: List.generate(_holesPerRow * 2 - 1, (i) {
              // Add spacers between items (odd indices)
              if (i.isOdd) {
                return const SizedBox(width: 6);
              }

              final int colIndex = i ~/ 2;

              // Add spacer for empty slots in partial rows
              if (colIndex >= holesInRow) {
                return const Expanded(child: SizedBox(height: 44));
              }

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
                child: _MiniHoleIndicator(
                  holeNumber: index + 1,
                  hasDescription: hasDescription,
                  isCurrent: isCurrent,
                  score: score,
                  par: par,
                  onTap: () => onHoleTap(index),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
