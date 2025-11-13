import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/round_processing/round_processing_loading_screen.dart';
import 'package:turbo_disc_golf/services/voice_recording_service.dart';
import 'package:turbo_disc_golf/utils/constants/description_constants.dart';

const String testCourseName = 'Foxwood';

class RecordRoundPanel extends StatefulWidget {
  const RecordRoundPanel({super.key});

  @override
  State<RecordRoundPanel> createState() => _RecordRoundPanelState();
}

class _RecordRoundPanelState extends State<RecordRoundPanel> {
  final VoiceRecordingService _voiceService = locator
      .get<VoiceRecordingService>();
  final ScrollController _scrollController = ScrollController();
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
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceServiceUpdate);
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
                      selectedTileColor: const Color(0xFF9D4EDD).withValues(alpha: 0.1),
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
    final String transcript = _voiceService.transcribedText;

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
    final String transcript = _voiceService.transcribedText;
    final bool isListening = _voiceService.isListening;
    final bool hasTranscript = transcript.isNotEmpty;

    return Container(
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
                    'Record Round',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Describe your round and I\'ll track the details',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
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
              // Animated microphone button with sound wave indicator
              Center(
                child: _AnimatedMicrophoneButton(
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
                    ElevatedButton(
                      onPressed: _showTestConstantSelector,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9D4EDD).withValues(alpha: 0.2),
                        foregroundColor: const Color(0xFF9D4EDD),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Parse button
                    Expanded(
                      child: ElevatedButton.icon(
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
                        icon: const Icon(Icons.science),
                        label: const Text(
                          'Parse',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9D4EDD),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (hasTranscript && !isListening) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedMicrophoneButton extends StatelessWidget {
  const _AnimatedMicrophoneButton({
    required this.isListening,
    required this.onTap,
  });

  final bool isListening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isListening
                ? [const Color(0xFFEF5350), const Color(0xFFD32F2F)]
                : [const Color(0xFF64B5F6), const Color(0xFF2196F3)],
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (isListening
                          ? const Color(0xFFEF5350)
                          : const Color(0xFF2196F3))
                      .withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: isListening
              ? const _SoundWaveIndicator(key: ValueKey('soundwave'))
              : const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 32,
                  key: ValueKey('mic'),
                ),
        ),
      ),
    );
  }
}

class _SoundWaveIndicator extends StatefulWidget {
  const _SoundWaveIndicator({super.key});

  @override
  State<_SoundWaveIndicator> createState() => _SoundWaveIndicatorState();
}

class _SoundWaveIndicatorState extends State<_SoundWaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Create staggered animation for each bar
              final double delay = index * 0.1;
              final double animationValue = (_controller.value + delay) % 1.0;

              // Use sine wave for smooth up/down motion
              final double height =
                  6 + (18 * (0.5 + 0.5 * sin(animationValue * 2 * pi)));

              return Container(
                width: 3,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
