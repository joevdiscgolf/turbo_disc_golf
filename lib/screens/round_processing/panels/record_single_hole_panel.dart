// Updated RecordSingleHolePanel using VoiceDescriptionCard and unified background
// NOTE: Replace placeholders for VoiceDescriptionCard import if needed.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/buttons/animated_microphone_button.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/components/voice_input/voice_description_card.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/voice_recording_service.dart';
import 'package:turbo_disc_golf/utils/constants/description_constants.dart';

/// A reusable panel for recording a single hole via voice input.
/// Now uses VoiceDescriptionCard and applies unified background
class RecordSingleHolePanel extends StatefulWidget {
  const RecordSingleHolePanel({
    super.key,
    required this.holeNumber,
    this.holePar,
    this.holeFeet,
    required this.courseName,
    this.showTestButton = true,
    this.title,
    this.subtitle,
    required this.onParseComplete,
    required this.bottomViewPadding,
  });

  final int holeNumber;
  final int? holePar;
  final int? holeFeet;
  final String courseName;
  final bool showTestButton;
  final String? title;
  final String? subtitle;
  final void Function(PotentialDGHole? parsedHole) onParseComplete;
  final double bottomViewPadding;

  @override
  State<RecordSingleHolePanel> createState() => _RecordSingleHolePanelState();
}

class _RecordSingleHolePanelState extends State<RecordSingleHolePanel> {
  static const Color _descAccent = Color(0xFFB39DDB); // light purple

  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late VoiceRecordingService _voiceService;
  final ScrollController _scrollController = ScrollController();
  int _selectedTestIndex = 0;

  // Internal processing state
  bool _processingContinueButton = false;
  bool _processingTestButton = false;

  bool get _isProcessing => _processingContinueButton || _processingTestButton;
  set _isProcessing(bool isProcessing) {
    _processingContinueButton = false;
    _processingTestButton = false;
  }

  String _processingError = '';

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
      padding: EdgeInsets.only(bottom: widget.bottomViewPadding),
      height: MediaQuery.of(context).size.height - 64,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F4FF), // unified panel background
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHeader(
            title: widget.title ?? _defaultTitle,
            subtitle: widget.subtitle ?? _defaultSubtitle,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Error display
                  if (_voiceService.lastError.isNotEmpty)
                    _buildErrorBox(context),

                  // Parsing error display
                  if (_processingError.isNotEmpty)
                    _buildParsingErrorBox(context),

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
                    loading: _processingContinueButton,
                    disabled: _isProcessing,
                    onPressed: _handleContinue,
                  ),
                ],
              ),
            ),
          ),
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

  Widget _buildParsingErrorBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _processingError,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red.shade900),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _processingError = ''),
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
              disabled: _isProcessing,
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
                loading: _processingTestButton,
                disabled: _isProcessing,
                onPressed: _handleTestParse,
                width: double.infinity,
              ),
            ),
          ],
        ),
      ],
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
    if (_isProcessing) return;

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

  /// Parse transcript internally using AI service
  Future<void> _parseTranscript(
    String transcript, {
    required bool isTestConstant,
  }) async {
    setState(() {
      if (isTestConstant) {
        _processingTestButton = true;
      } else {
        _processingContinueButton = true;
      }
      _processingError = '';
    });

    try {
      final AiParsingService aiService = locator.get<AiParsingService>();
      final BagService bagService = locator.get<BagService>();

      // Ensure bag is loaded
      if (bagService.userBag.isEmpty) {
        await bagService.loadBag();
        if (bagService.userBag.isEmpty) {
          bagService.loadSampleBag();
        }
      }

      debugPrint('🎤 Parsing hole ${widget.holeNumber}');

      // Call AI parsing
      final PotentialDGHole? parsed = await aiService.parseSingleHole(
        voiceTranscript: transcript,
        userBag: bagService.userBag,
        holeNumber: widget.holeNumber,
        existingHolePar: widget.holePar,
        existingHoleFeet: widget.holeFeet,
        courseName: widget.courseName,
      );

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      HapticFeedback.mediumImpact();

      if (parsed != null) {
        debugPrint('✅ Successfully parsed hole ${widget.holeNumber}');

        // Pop panel before calling callback
        Navigator.of(context).pop();

        // Return parsed hole to parent
        widget.onParseComplete(parsed);
      } else {
        setState(() {
          _processingError = 'Failed to parse hole. Please try again.';
        });
      }
    } catch (e) {
      debugPrint('❌ Error parsing: $e');

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _processingError = 'Error: ${e.toString()}';
      });
    }
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
    _parseTranscript(transcript, isTestConstant: false);
  }

  void _handleTestParse() {
    final String test = _testConstantValues[_selectedTestIndex];
    _parseTranscript(test, isTestConstant: true);
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
