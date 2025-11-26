import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/buttons/animated_microphone_button.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/round_processing/round_processing_loading_screen.dart';
import 'package:turbo_disc_golf/services/voice_recording_service.dart';
import 'package:turbo_disc_golf/utils/constants/description_constants.dart';
import 'package:turbo_disc_golf/utils/panel_helpers.dart';

const String testCourseName = 'Foxwood';

class RecordRoundPanel extends StatefulWidget {
  const RecordRoundPanel({super.key});

  @override
  State<RecordRoundPanel> createState() => _RecordRoundPanelState();
}

class _RecordRoundPanelState extends State<RecordRoundPanel> {
  final VoiceRecordingService _voiceService = locator
      .get<VoiceRecordingService>();
  final TextEditingController _transcriptController = TextEditingController();
  final FocusNode _transcriptFocusNode = FocusNode();
  int _selectedTestIndex = 0;

  // Get keys (constant names) from fullRoundConstants
  final List<String> _testRoundDescriptionNames = DescriptionConstants
      .fullRoundConstants
      .keys
      .toList();

  // Get values (transcripts) from fullRoundConstants
  final List<String> _testRoundConstants = DescriptionConstants
      .fullRoundConstants
      .values
      .toList();

  // Get the transcript value directly from the list
  String get _selectedTranscript {
    return _testRoundConstants[_selectedTestIndex];
  }

  @override
  void initState() {
    super.initState();
    _voiceService.initialize();
    _voiceService.addListener(_onVoiceServiceUpdate);
    _transcriptFocusNode.addListener(_onTranscriptFocusChange);
  }

  void _onTranscriptFocusChange() {
    // Stop listening when user starts editing
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

  void _onVoiceServiceUpdate() {
    if (mounted) {
      // Update text controller only if user isn't currently editing
      if (!_transcriptFocusNode.hasFocus) {
        _transcriptController.text = _voiceService.transcribedText;
        // Move cursor to end
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
      await _voiceService.startListening();
    }
  }

  void _showTestConstantSelector() {
    // Unfocus text field to prevent keyboard from popping back up
    FocusScope.of(context).unfocus();
    displayBottomSheet(
      context,
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PanelHeader(
              title: 'Select Test Constant',
              onClose: () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              ...List.generate(
                _testRoundDescriptionNames.length,
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
                      _testRoundDescriptionNames[index],
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
                      // Prevent keyboard from popping up after modal closes
                      _transcriptFocusNode.unfocus();
                    },
                  ),
                ),
              ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
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

    // Replace the bottom sheet with the loading screen
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

  @override
  Widget build(BuildContext context) {
    final bool isListening = _voiceService.isListening;
    final bool hasTranscript = _transcriptController.text.isNotEmpty;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: MediaQuery.of(context).size.height - 64,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PanelHeader(
              title: 'Record Round',
              onClose: () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Describe your round and I\'ll track the details',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 12),
            // Editable transcript text field
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
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
                  child: TextField(
                    controller: _transcriptController,
                    focusNode: _transcriptFocusNode,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    cursorColor: const Color(0xFF2196F3),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Round description',
                      hintStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      fillColor: Colors.transparent,
                      filled: true,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  // Animated microphone button with sound wave indicator
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
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    // Change button
                    PrimaryButton(
                      label: 'Change',
                      width: 100,
                      height: 48,
                      backgroundColor: const Color(
                        0xFF9D4EDD,
                      ).withValues(alpha: 0.2),
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
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Continue',
                backgroundColor: const Color(0xFF2196F3),
                labelColor: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                width: double.infinity,
                height: 56,
                disabled: !hasTranscript || isListening,
                onPressed: _handleContinue,
              ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
