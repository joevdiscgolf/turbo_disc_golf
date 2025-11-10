import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/services/voice_recording_service.dart';

/// Dialog for re-recording voice description for a specific hole.
///
/// Allows the user to record a new voice description for a hole that's
/// missing data, then sends it to Gemini for re-processing.
class HoleReRecordDialog extends StatefulWidget {
  const HoleReRecordDialog({
    super.key,
    required this.holeNumber,
    required this.holeIndex,
    this.holePar,
    this.holeFeet,
    this.onReProcessed,
  });

  final int holeNumber;
  final int holeIndex;
  final int? holePar;
  final int? holeFeet;
  final VoidCallback? onReProcessed; // Called when re-processing completes

  @override
  State<HoleReRecordDialog> createState() => _HoleReRecordDialogState();
}

class _HoleReRecordDialogState extends State<HoleReRecordDialog>
    with SingleTickerProviderStateMixin {
  late VoiceRecordingService _voiceService;
  late AnimationController _animationController;
  final TextEditingController _transcriptController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceRecordingService();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _initializeVoiceService();
    _voiceService.addListener(_onVoiceServiceChange);
  }

  Future<void> _initializeVoiceService() async {
    await _voiceService.initialize();
  }

  void _onVoiceServiceChange() {
    if (mounted) {
      setState(() {
        _transcriptController.text = _voiceService.transcribedText;
      });
    }
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceServiceChange);
    _voiceService.dispose();
    _animationController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
      _animationController.stop();
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
      _animationController.repeat();
    }
    setState(() {});
  }

  Future<void> _processTranscript() async {
    if (_transcriptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please record or enter a description for this hole'),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Show loading snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Re-processing hole with AI...')),
      );
    }

    // Call RoundParser to re-process the hole
    final RoundParser roundParser = locator.get<RoundParser>();
    final bool success = await roundParser.reProcessHole(
      holeIndex: widget.holeIndex,
      voiceTranscript: _transcriptController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    // Show result
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hole re-processed successfully!'),
          backgroundColor: Color(0xFF137e66),
        ),
      );
      widget.onReProcessed?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${roundParser.lastError.isNotEmpty ? roundParser.lastError : 'Failed to re-process hole'}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Close dialog
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
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
                        'Re-record Hole ${widget.holeNumber}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (widget.holePar != null)
                        Text(
                          'Par ${widget.holePar}${widget.holeFeet != null ? ' • ${widget.holeFeet} ft' : ''}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF9D4EDD).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Describe this hole in detail: your throws, disc choices, distances, and results.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),

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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF664D03),
                            ),
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
                            : const Color(0xFF9D4EDD),
                        boxShadow: _voiceService.isListening
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF10E5FF)
                                      .withValues(alpha: 0.7),
                                  blurRadius: 20 * _animationController.value,
                                  spreadRadius: 5 * _animationController.value,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: const Color(0xFF9D4EDD)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  spreadRadius: 3,
                                ),
                              ],
                      ),
                      child: Icon(
                        _voiceService.isListening
                            ? Icons.mic
                            : Icons.mic_none,
                        size: 40,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Status text
            Center(
              child: Text(
                _voiceService.isListening
                    ? 'Listening... Describe this hole!'
                    : 'Tap mic to record',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: _voiceService.isListening
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
              ),
            ),
            const SizedBox(height: 24),

            // Transcript text field
            TextField(
              controller: _transcriptController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Hole Description',
                hintText: 'Or type your description here...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _processTranscript,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_isProcessing ? 'Processing...' : 'Re-Process'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9D4EDD),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
