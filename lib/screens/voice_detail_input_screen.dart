import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/screens/record_round/record_round_screen.dart';
import 'package:turbo_disc_golf/screens/round_review/round_review_screen.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/services/voice_recording_service.dart';

// Test constant for image + voice mode (no hole distance/par info)

/// Screen for recording throw-by-throw voice details after scorecard image has been parsed.
/// The hole metadata (par, distance, score) is already known from the image.
/// User only needs to describe their individual throws for each hole.
class VoiceDetailInputScreen extends StatefulWidget {
  final List<HoleMetadata> holeMetadata;
  final String courseName;
  final String? testVoiceDescription;

  const VoiceDetailInputScreen({
    super.key,
    required this.holeMetadata,
    required this.courseName,
    this.testVoiceDescription,
  });

  @override
  State<VoiceDetailInputScreen> createState() => _VoiceDetailInputScreenState();
}

class _VoiceDetailInputScreenState extends State<VoiceDetailInputScreen>
    with SingleTickerProviderStateMixin {
  late final VoiceRecordingService _voiceService;
  late final RoundParser _roundParser;
  late AnimationController _animationController;
  final TextEditingController _transcriptController = TextEditingController();
  String? _lastNavigatedRoundId;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceRecordingService();
    _roundParser = locator.get<RoundParser>();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _initializeServices();

    // Listen to voice service changes
    _voiceService.addListener(_onVoiceServiceChange);
    _roundParser.addListener(_onParserChange);
  }

  Future<void> _initializeServices() async {
    await _voiceService.initialize();
  }

  void _onVoiceServiceChange() {
    setState(() {
      _transcriptController.text = _voiceService.transcribedText;
    });
  }

  void _onParserChange() {
    // Navigate to review when round is parsed
    if (_roundParser.parsedRound != null &&
        _roundParser.shouldNavigateToReview &&
        mounted) {
      final roundId = _roundParser.parsedRound!.id;

      // Only navigate if this is a new round (not already navigated to)
      if (roundId != _lastNavigatedRoundId) {
        _lastNavigatedRoundId = roundId;
        _roundParser.clearNavigationFlag();

        final round = _roundParser.parsedRound!;

        // Navigate to review screen with story shown on load
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RoundReviewScreen(round: round, showStoryOnLoad: true),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceServiceChange);
    _roundParser.removeListener(_onParserChange);
    _voiceService.dispose();
    _animationController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  void _toggleRecording() async {
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
      _animationController.stop();
    } else {
      // Try to initialize first if not initialized
      if (!_voiceService.isInitialized) {
        final initialized = await _voiceService.initialize();
        if (!initialized) {
          if (mounted) {
            setState(() {});
            if (_voiceService.lastError.contains('Settings')) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please enable microphone access in Settings, then try again',
                  ),
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
          return;
        }
      }

      await _voiceService.startListening();
      _animationController.repeat();
    }
    setState(() {});
  }

  void _parseRound() async {
    if (_transcriptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please record a description of your throws'),
        ),
      );
      return;
    }

    await _roundParser.parseVoiceTranscript(
      _transcriptController.text,
      courseName: widget.courseName,
      preParsedHoles: widget.holeMetadata,
    );

    if (_roundParser.lastError.isNotEmpty && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_roundParser.lastError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Throw Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Card(
              color: const Color(0xFF1E293B),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF137e66),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How to Record',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF137e66),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Describe your throws for each hole. You don\'t need to say the par, distance, or score - we already have that from your scorecard!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFF5F5F5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Example: "Hole 1, threw my Destroyer down the fairway, ended up in circle 1, made the putt for birdie."',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFB0B0B0),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Course name display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.golf_course, color: Color(0xFF137e66)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Course',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFFB0B0B0)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.courseName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Hole metadata summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.format_list_numbered,
                          color: Color(0xFF9D4EDD),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Holes from Scorecard',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF9D4EDD,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.holeMetadata.length} holes',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...widget.holeMetadata.take(5).map(_buildHoleSummary),
                    if (widget.holeMetadata.length > 5) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          '+ ${widget.holeMetadata.length - 5} more holes',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFFB0B0B0),
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Error display
            if (_voiceService.lastError.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D1818),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF7A7A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFFF7A7A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _voiceService.lastError,
                        style: const TextStyle(color: Color(0xFFFFBBBB)),
                      ),
                    ),
                  ],
                ),
              ),

            // Recording button
            Center(
              child: GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _voiceService.isListening
                            ? const Color(0xFF10E5FF).withValues(alpha: 0.9)
                            : const Color(0xFF9D7FFF),
                        boxShadow: _voiceService.isListening
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF10E5FF,
                                  ).withValues(alpha: 0.7),
                                  blurRadius: 20 * _animationController.value,
                                  spreadRadius: 5 * _animationController.value,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: const Color(
                                    0xFF9D7FFF,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  spreadRadius: 3,
                                ),
                              ],
                      ),
                      child: Icon(
                        _voiceService.isListening ? Icons.mic : Icons.mic_none,
                        size: 40,
                        color: const Color(0xFFF5F5F5),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Status text
            Center(
              child: Text(
                _voiceService.isListening
                    ? 'Listening... Describe your throws!'
                    : 'Tap mic to record throw details',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),

            const SizedBox(height: 24),

            // Test mode button - show if test voice description is provided
            if (widget.testVoiceDescription != null) ...[
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _transcriptController.text = widget.testVoiceDescription!;
                    _voiceService.updateText(widget.testVoiceDescription!);
                  });
                },
                icon: const Icon(Icons.science),
                label: const Text('Use Test Voice Description'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9D4EDD),
                  foregroundColor: const Color(0xFFF5F5F5),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Transcript display (optional, for debugging)
            if (_transcriptController.text.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transcript',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _transcriptController.text,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Parse button
            ElevatedButton.icon(
              onPressed:
                  _roundParser.isProcessing ||
                      _transcriptController.text.isEmpty
                  ? null
                  : _parseRound,
              icon: _roundParser.isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(
                _roundParser.isProcessing ? 'Processing...' : 'Parse Round',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF137e66),
                foregroundColor: const Color(0xFF0A0E17),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 32),

            // Test/Debug Section
            ExpansionTile(
              title: Row(
                children: [
                  const Icon(Icons.science, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Test & Debug Tools',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Load test transcript button
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _transcriptController.text =
                                flingsGivingRound2DescriptionNoHoleDistance;
                            _voiceService.updateText(
                              flingsGivingRound2DescriptionNoHoleDistance,
                            );
                          });
                        },
                        icon: const Icon(Icons.text_fields),
                        label: const Text('Load Test Voice Transcript'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9D4EDD),
                          foregroundColor: const Color(0xFFF5F5F5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoleSummary(HoleMetadata hole) {
    final relativeToPar = hole.score - hole.par;
    final relativeToParText = relativeToPar == 0
        ? 'E'
        : relativeToPar > 0
        ? '+$relativeToPar'
        : '$relativeToPar';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          // Hole number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF9D4EDD).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${hole.holeNumber}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9D4EDD),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Hole info
          Expanded(
            child: Text(
              'Par ${hole.par}${hole.distanceFeet != null ? " • ${hole.distanceFeet}ft" : ""}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

          // Score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getScoreColor(relativeToPar).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${hole.score}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(relativeToPar),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  relativeToParText,
                  style: TextStyle(
                    fontSize: 11,
                    color: _getScoreColor(relativeToPar),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int relativeToPar) {
    if (relativeToPar <= -2) {
      return Colors.purple;
    } else if (relativeToPar == -1) {
      return Colors.blue;
    } else if (relativeToPar == 0) {
      return Colors.green;
    } else if (relativeToPar == 1) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
