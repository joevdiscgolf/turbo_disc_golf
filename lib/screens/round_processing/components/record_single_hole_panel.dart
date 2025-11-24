import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/buttons/animated_microphone_button.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/services/voice_recording_service.dart';
import 'package:turbo_disc_golf/utils/constants/description_constants.dart';

/// A reusable panel for recording a single hole via voice input.
///
/// This panel provides voice recording UI without baked-in business logic,
/// making it suitable for multiple use cases:
/// - Adding a hole to a PotentialDgRound in round confirmation flow
/// - Re-recording a hole during round processing
/// - Editing a hole from the round review screen
///
/// The panel uses callbacks to delegate business logic to the parent widget,
/// allowing for flexible integration with different flows and state management.
class RecordSingleHolePanel extends StatefulWidget {
  const RecordSingleHolePanel({
    super.key,
    required this.holeNumber,
    this.holePar,
    this.holeFeet,
    this.isProcessing = false,
    this.showTestButton = false,
    this.title,
    this.subtitle,
    required this.onContinuePressed,
    this.onTestingPressed,
    this.onCancel,
  });

  /// The hole number to display (e.g., "Record Hole 5")
  final int holeNumber;

  /// Optional par value to display in subtitle
  final int? holePar;

  /// Optional distance in feet to display in subtitle
  final int? holeFeet;

  /// Whether the parent is currently processing the transcript.
  /// When true, the continue button shows a loading indicator.
  final bool isProcessing;

  /// Whether to show the testing button (typically only in debug mode)
  final bool showTestButton;

  /// Optional custom title. Defaults to "Record Hole {holeNumber}"
  final String? title;

  /// Optional custom subtitle. Defaults to hole metadata or instructions.
  final String? subtitle;

  /// Called when the user presses continue with a valid transcript.
  /// The parent should handle the business logic (e.g., processing with AI,
  /// updating state, navigation).
  final void Function(String transcript) onContinuePressed;

  /// Optional callback for the testing button (debug mode).
  /// Should be provided when showTestButton is true.
  /// Receives the selected test constant string.
  final void Function(String testConstant)? onTestingPressed;

  /// Optional callback when the user cancels/closes the panel.
  final VoidCallback? onCancel;

  @override
  State<RecordSingleHolePanel> createState() => _RecordSingleHolePanelState();
}

class _RecordSingleHolePanelState extends State<RecordSingleHolePanel> {
  late VoiceRecordingService _voiceService;
  final ScrollController _scrollController = ScrollController();
  int _selectedTestIndex = 0;

  // Get list of test constant keys and values
  List<String> get _testConstantKeys =>
      DescriptionConstants.singleHoleDescriptionConstants.keys.toList();
  List<String> get _testConstantValues =>
      DescriptionConstants.singleHoleDescriptionConstants.values.toList();

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceRecordingService();
    _initializeVoiceService();
    _voiceService.addListener(_onVoiceServiceUpdate);
  }

  Future<void> _initializeVoiceService() async {
    await _voiceService.initialize();
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceServiceUpdate);
    _voiceService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onVoiceServiceUpdate() {
    if (mounted) {
      setState(() {});
      // Auto-scroll to bottom when new text arrives
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _toggleListening() async {
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
    } else {
      // Try to initialize first if not initialized
      if (!_voiceService.isInitialized) {
        final bool initialized = await _voiceService.initialize();
        if (!initialized) {
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _voiceService.lastError.isNotEmpty
                      ? _voiceService.lastError
                      : 'Unable to initialize voice recording',
                ),
              ),
            );
          }
          return;
        }
      }
      await _voiceService.startListening();
    }
  }

  void _showTestConstantSelector() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  _testConstantKeys.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      selected: _selectedTestIndex == index,
                      selectedTileColor: const Color(
                        0xFF9D4EDD,
                      ).withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        _testConstantKeys[index],
                        style: TextStyle(
                          fontWeight: _selectedTestIndex == index
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedTestIndex == index
                              ? const Color(0xFF9D4EDD)
                              : null,
                        ),
                      ),
                      trailing: _selectedTestIndex == index
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF9D4EDD),
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedTestIndex = index;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleContinue() {
    final String transcript = _voiceService.transcribedText.trim();

    if (transcript.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please record or enter a description for this hole'),
        ),
      );
      return;
    }

    // Delegate business logic to parent via callback
    widget.onContinuePressed(transcript);
  }

  void _handleCancel() {
    widget.onCancel?.call();
    Navigator.of(context).pop();
  }

  String get _defaultTitle => 'Record Hole ${widget.holeNumber}';

  String get _defaultSubtitle {
    if (widget.holePar != null) {
      final String parText = 'Par ${widget.holePar}';
      final String feetText = widget.holeFeet != null
          ? ' • ${widget.holeFeet} ft'
          : '';
      return '$parText$feetText';
    }
    return 'Describe your throws, disc choices, distances, and results';
  }

  @override
  Widget build(BuildContext context) {
    final String transcript = _voiceService.transcribedText;
    final bool isListening = _voiceService.isListening;
    final bool hasTranscript = transcript.isNotEmpty;
    final bool showContinueButton =
        hasTranscript && !isListening && !widget.isProcessing;

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.mic, color: Color(0xFF9D4EDD)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title ?? _defaultTitle,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              widget.subtitle ?? _defaultSubtitle,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _handleCancel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Error display
                  if (_voiceService.lastError.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFFA726).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFF8F00),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _voiceService.lastError,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFF664D03)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Transcript container
                  Container(
                    height: 150,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isListening
                            ? const Color(0xFF2196F3)
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: transcript.isEmpty
                        ? Center(
                            child: Text(
                              isListening
                                  ? 'Listening...'
                                  : 'Tap the microphone to start',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: Colors.grey[400],
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          )
                        : SingleChildScrollView(
                            controller: _scrollController,
                            child: Text(
                              transcript,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(height: 1.5),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  // Animated microphone button
                  Center(
                    child: AnimatedMicrophoneButton(
                      isListening: isListening,
                      onTap: _toggleListening,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      isListening ? 'Tap to stop' : 'Tap to start',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ),

                  // Testing button (debug mode only)
                  if (widget.showTestButton && kDebugMode) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        // Change button
                        PrimaryButton(
                          label: 'Change',
                          width: 100,
                          height: 48,
                          backgroundColor:
                              const Color(0xFF9D4EDD).withValues(alpha: 0.2),
                          labelColor: const Color(0xFF9D4EDD),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          onPressed: _showTestConstantSelector,
                        ),
                        const SizedBox(width: 12),
                        // Parse button
                        Expanded(
                          child: PrimaryButton(
                            label: 'Parse',
                            width: double.infinity,
                            height: 48,
                            backgroundColor: const Color(0xFF9D4EDD),
                            labelColor: Colors.white,
                            icon: Icons.science,
                            iconColor: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            disabled: widget.onTestingPressed == null,
                            onPressed: () {
                              if (widget.onTestingPressed != null) {
                                widget.onTestingPressed!(
                                  _testConstantValues[_selectedTestIndex],
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Continue button
                  if (showContinueButton) ...[
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Continue',
                      width: double.infinity,
                      height: 56,
                      backgroundColor: const Color(0xFF2196F3),
                      labelColor: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      loading: widget.isProcessing,
                      disabled: widget.isProcessing,
                      onPressed: _handleContinue,
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),

        // Processing overlay
        if (widget.isProcessing)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2196F3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Processing...',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Analyzing your recording',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
