// Updated RecordSingleHolePanel using VoiceDescriptionCard and unified background
// NOTE: Replace placeholders for VoiceDescriptionCard import if needed.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/buttons/animated_microphone_button.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/voice_input/voice_description_card.dart';
import 'package:turbo_disc_golf/services/voice_recording_service.dart';
import 'package:turbo_disc_golf/utils/constants/description_constants.dart';

/// A reusable panel for recording a single hole via voice input.
/// Now uses VoiceDescriptionCard and applies unified background
class RecordSingleHolePanelV2 extends StatefulWidget {
  const RecordSingleHolePanelV2({
    super.key,
    required this.holeNumber,
    this.holePar,
    this.holeFeet,
    this.isProcessing = false,
    this.showTestButton = true,
    this.title,
    this.subtitle,
    required this.onContinuePressed,
    required this.onTestingPressed,
  });

  final int holeNumber;
  final int? holePar;
  final int? holeFeet;
  final bool isProcessing;
  final bool showTestButton;
  final String? title;
  final String? subtitle;
  final void Function(String transcript) onContinuePressed;
  final void Function(String testConstant) onTestingPressed;

  @override
  State<RecordSingleHolePanelV2> createState() =>
      _RecordSingleHolePanelV2State();
}

class _RecordSingleHolePanelV2State extends State<RecordSingleHolePanelV2> {
  static const Color _descAccent = Color(0xFFB39DDB); // light purple

  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late VoiceRecordingService _voiceService;
  final ScrollController _scrollController = ScrollController();
  int _selectedTestIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    final bool isListening = _voiceService.isListening;

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 24),
      height: MediaQuery.of(context).size.height - 64,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F4FF), // unified panel background
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title ?? _defaultTitle,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.subtitle ?? _defaultSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Error display
              if (_voiceService.lastError.isNotEmpty) _buildErrorBox(context),

              // --- REPLACED WITH UNIVERSAL COMPONENT ---
              Expanded(
                child: VoiceDescriptionCard(
                  isListening: isListening,
                  controller: _textEditingController,
                  focusNode: _focusNode,
                  accent: _descAccent,
                ),
              ),
              const SizedBox(height: 24),

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

              if (widget.showTestButton && kDebugMode) _buildTestingRow(),

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

              const SizedBox(height: 16),
            ],
          ),

          if (widget.isProcessing) _buildProcessingOverlay(context),
        ],
      ),
    );
  }

  Widget _buildErrorBox(BuildContext context) {
    return Container(
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF664D03)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestingRow() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            PrimaryButton(
              label: 'Change',
              width: 100,
              height: 48,
              backgroundColor: const Color(0xFF9D4EDD).withValues(alpha: 0.2),
              labelColor: const Color(0xFF9D4EDD),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              onPressed: _showTestConstantSelector,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: 'Parse',
                height: 48,
                backgroundColor: const Color(0xFF9D4EDD),
                labelColor: Colors.white,
                icon: Icons.science,
                iconColor: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,

                onPressed: () {
                  widget.onTestingPressed(
                    _testConstantValues[_selectedTestIndex],
                  );
                },
                width: double.infinity,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProcessingOverlay(BuildContext context) {
    return Positioned.fill(
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
              children: const [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF2196F3),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Processing...',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Analyzing your recording',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onVoiceServiceUpdate() {
    if (mounted) {
      setState(() {});
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
      if (!_voiceService.isInitialized) {
        final bool ok = await _voiceService.initialize();
        if (!ok) {
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(_voiceService.lastError)));
          }
          return;
        }
      }
      await _voiceService.startListening();
    }
  }

  void _showTestConstantSelector() {
    showModalBottomSheet(
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
                ...List.generate(_testConstantKeys.length, (index) {
                  final selected = _selectedTestIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      selected: selected,
                      selectedTileColor: const Color(
                        0xFF9D4EDD,
                      ).withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        _testConstantKeys[index],
                        style: TextStyle(
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected ? const Color(0xFF9D4EDD) : null,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF9D4EDD),
                            )
                          : null,
                      onTap: () {
                        setState(() => _selectedTestIndex = index);
                        Navigator.pop(context);
                      },
                    ),
                  );
                }),
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
    widget.onContinuePressed(transcript);
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
}
