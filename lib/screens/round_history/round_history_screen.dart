import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/record_round/record_round_screen.dart';
import 'package:turbo_disc_golf/screens/round_review/round_review_screen.dart';
import 'package:turbo_disc_golf/screens/round_review/round_review_screen_v2.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_round_service.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';
import 'package:turbo_disc_golf/services/voice_recording_service.dart';
import 'package:turbo_disc_golf/utils/testing_constants.dart';

class RoundHistoryScreen extends StatelessWidget {
  const RoundHistoryScreen({super.key});

  void _showRecordRoundSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _RecordRoundSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<DGRound>>(
          future: locator.get<FirestoreRoundService>().getRounds(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading rounds',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final rounds = snapshot.data ?? [];

            if (rounds.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.golf_course,
                      size: 80,
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No rounds yet',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first round to get started!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rounds.length,
              itemBuilder: (context, index) {
                final round = rounds[index];
                return _RoundHistoryRow(round: round);
              },
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF64B5F6), Color(0xFF2196F3)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showRecordRoundSheet(context),
                  customBorder: const CircleBorder(),
                  child: const Center(
                    child: Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundHistoryRow extends StatelessWidget {
  const _RoundHistoryRow({required this.round});

  final DGRound round;

  @override
  Widget build(BuildContext context) {
    final totalScore = round.holes.fold<int>(
      0,
      (sum, hole) => sum + hole.holeScore,
    );
    final totalPar = round.holes.fold<int>(0, (sum, hole) => sum + hole.par);
    final relativeToPar = totalScore - totalPar;
    final relativeToParText = relativeToPar == 0
        ? 'E'
        : relativeToPar > 0
        ? '+$relativeToPar'
        : '$relativeToPar';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Set the existing round so the parser can calculate stats
          locator.get<RoundParser>().setRound(round);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => useRoundReviewScreenV2
                  ? RoundReviewScreenV2(round: round)
                  : RoundReviewScreen(round: round),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      round.courseName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreColor(relativeToPar),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      relativeToParText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.pin_drop,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${round.holes.length} holes',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.sports_golf,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Score: $totalScore',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(Par: $totalPar)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int relativeToPar) {
    if (relativeToPar <= -3) {
      return Colors.purple; // Eagle or better
    } else if (relativeToPar < 0) {
      return Colors.blue; // Under par
    } else if (relativeToPar == 0) {
      return Colors.green; // Even par
    } else if (relativeToPar <= 3) {
      return Colors.orange; // Slightly over par
    } else {
      return Colors.red; // Way over par
    }
  }
}

class _RecordRoundSheet extends StatefulWidget {
  const _RecordRoundSheet();

  @override
  State<_RecordRoundSheet> createState() => _RecordRoundSheetState();
}

class _RecordRoundSheetState extends State<_RecordRoundSheet> {
  final VoiceRecordingService _voiceService = locator
      .get<VoiceRecordingService>();
  final ScrollController _scrollController = ScrollController();

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

  void _handleContinue() {
    // todo: Process the transcript and continue with round creation
    Navigator.pop(context);
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
                ElevatedButton.icon(
                  onPressed: () async {
                    final RoundParser roundParser = locator.get<RoundParser>();
                    final RoundStorageService storageService =
                        locator.get<RoundStorageService>();

                    // Check if there's a cached round available
                    final bool useCached = await storageService.hasCachedRound();
                    debugPrint(
                      'Test Parse Constant: Using cached round: $useCached',
                    );

                    await roundParser.parseVoiceTranscript(
                      testRoundDescription,
                      courseName: testCourseName,
                      useSharedPreferences: useCached,
                    );

                    if (roundParser.lastError.isNotEmpty && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(roundParser.lastError)),
                      );
                    } else if (roundParser.parsedRound != null &&
                        context.mounted) {
                      // Set the round so the parser can calculate stats
                      roundParser.setRound(roundParser.parsedRound!);

                      // Close the bottom sheet
                      Navigator.pop(context);

                      // Navigate to the review screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => useRoundReviewScreenV2
                              ? RoundReviewScreenV2(
                                  round: roundParser.parsedRound!,
                                  showStoryOnLoad: true,
                                )
                              : RoundReviewScreen(
                                  round: roundParser.parsedRound!,
                                  showStoryOnLoad: true,
                                ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.science),
                  label: const Text(
                    'Test Parse Constant',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              color: (isListening
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
            return FadeTransition(
              opacity: animation,
              child: child,
            );
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
              final double animationValue =
                  (_controller.value + delay) % 1.0;

              // Use sine wave for smooth up/down motion
              final double height = 6 + (18 * (0.5 + 0.5 * sin(animationValue * 2 * pi)));

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
