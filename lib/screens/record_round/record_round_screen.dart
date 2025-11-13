import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/import_score/import_score_screen.dart';
import 'package:turbo_disc_golf/screens/round_processing/round_processing_loading_screen.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_round_service.dart';
import 'package:turbo_disc_golf/services/voice_recording_service.dart';
import 'package:turbo_disc_golf/utils/constants/description_constants.dart';

const testRoundDescriptions = [
  DescriptionConstants.testRoundDescription,
  DescriptionConstants.testRoundDescription2,
  DescriptionConstants.testRoundDescription3,
  DescriptionConstants.testRoundDescription4,
  DescriptionConstants.flingsGivingRound2Description,
  DescriptionConstants.elevenUnderWhitesDescriptionNoHoleDistance,
];

const String testCourseName = 'Foxwood';

class RecordRoundScreen extends StatefulWidget {
  const RecordRoundScreen({super.key});

  @override
  State<RecordRoundScreen> createState() => _RecordRoundScreenState();
}

class _RecordRoundScreenState extends State<RecordRoundScreen>
    with SingleTickerProviderStateMixin {
  static const descriptionIndex = 4;
  String get getCorrectTestDescription =>
      testRoundDescriptions[descriptionIndex];
  late final VoiceRecordingService _voiceService;
  late final BagService _bagService;
  late AnimationController _animationController;
  final TextEditingController _transcriptController = TextEditingController();
  final TextEditingController _courseNameController = TextEditingController();
  bool _testMode = true;
  bool _useSharedPreferences = false;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceRecordingService();
    _bagService = locator.get<BagService>();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _initializeServices();

    // Listen to voice service changes only
    _voiceService.addListener(_onVoiceServiceChange);

    locator.get<FirestoreRoundService>().getRounds().then((rounds) {
      debugPrint('Firestore rounds: ${rounds.length}');
    });
  }

  Future<void> _initializeServices() async {
    await _voiceService.initialize();
    await _bagService.loadBag();

    // Load sample bag if empty for testing
    if (_bagService.userBag.isEmpty) {
      _bagService.loadSampleBag();
    }
  }

  void _onVoiceServiceChange() {
    setState(() {
      _transcriptController.text = _voiceService.transcribedText;
    });
  }

  Future<void> _processAndNavigate({
    required String transcript,
    String? courseName,
    required bool useSharedPreferences,
  }) async {
    debugPrint('RecordRoundScreen: Starting round processing');

    // Show loading screen
    if (!mounted) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (context, _, __) => RoundProcessingLoadingScreen(
          transcript: transcript,
          courseName: courseName,
          useSharedPreferences: useSharedPreferences,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceServiceChange);
    _voiceService.dispose();
    _animationController.dispose();
    _transcriptController.dispose();
    _courseNameController.dispose();
    super.dispose();
  }

  // void _toggleRecording() async {
  //   if (_voiceService.isListening) {
  //     await _voiceService.stopListening();
  //     _animationController.stop();
  //   } else {
  //     // Try to initialize first if not initialized
  //     if (!_voiceService.isInitialized) {
  //       final initialized = await _voiceService.initialize();
  //       if (!initialized) {
  //         // If still not initialized, show error
  //         if (mounted) {
  //           setState(() {});
  //           // Check if it's a permission issue
  //           if (_voiceService.lastError.contains('Settings')) {
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               const SnackBar(
  //                 content: Text(
  //                   'Please enable microphone access in Settings, then try again',
  //                 ),
  //                 duration: Duration(seconds: 4),
  //               ),
  //             );
  //           }
  //         }
  //         return;
  //       }
  //     }

  //     await _voiceService.startListening();
  //     _animationController.repeat();
  //   }
  //   setState(() {});
  // }

  // void _parseRound() async {
  //   if (_transcriptController.text.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Please record or enter a round description'),
  //       ),
  //     );
  //     return;
  //   }

  //   await _roundParser.parseVoiceTranscript(
  //     _transcriptController.text,
  //     courseName: _courseNameController.text.isNotEmpty
  //         ? _courseNameController.text
  //         : null,
  //     useSharedPreferences: _useSharedPreferences,
  //   );

  //   if (_roundParser.lastError.isNotEmpty && mounted) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text(_roundParser.lastError)));
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Header
            Text(
              'Record Your Round',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to input your round data',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFB0B0B0)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Option 1: Image + Voice
            Card(
              color: const Color(0xFF1E293B),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF137e66,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              '1',
                              style: TextStyle(
                                color: Color(0xFF137e66),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Image + Voice Input',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Upload a scorecard screenshot to capture hole info (par, distance, score), then describe your throws with voice.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFB0B0B0),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ImportScoreScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Import from Screenshot'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF137e66),
                        foregroundColor: const Color(0xFF0A0E17),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Divider with "OR"
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFF334155))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'OR',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFF334155))),
              ],
            ),

            const SizedBox(height: 24),

            // // Option 2: Voice Only
            // Card(
            //   color: const Color(0xFF1E293B),
            //   child: Padding(
            //     padding: const EdgeInsets.all(16.0),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Row(
            //           children: [
            //             Container(
            //               width: 32,
            //               height: 32,
            //               decoration: BoxDecoration(
            //                 color: const Color(
            //                   0xFF9D7FFF,
            //                 ).withValues(alpha: 0.2),
            //                 borderRadius: BorderRadius.circular(8),
            //               ),
            //               child: const Center(
            //                 child: Text(
            //                   '2',
            //                   style: TextStyle(
            //                     color: Color(0xFF9D7FFF),
            //                     fontWeight: FontWeight.bold,
            //                     fontSize: 18,
            //                   ),
            //                 ),
            //               ),
            //             ),
            //             const SizedBox(width: 12),
            //             Text(
            //               'Voice-Only Input',
            //               style: Theme.of(context).textTheme.titleMedium
            //                   ?.copyWith(fontWeight: FontWeight.bold),
            //             ),
            //           ],
            //         ),
            //         const SizedBox(height: 12),
            //         Text(
            //           'Describe your entire round with voice, including hole numbers, par, distance, and all your throws.',
            //           style: Theme.of(context).textTheme.bodySmall?.copyWith(
            //             color: const Color(0xFFB0B0B0),
            //           ),
            //         ),
            //         const SizedBox(height: 16),
            //         TextField(
            //           controller: _courseNameController,
            //           decoration: const InputDecoration(
            //             labelText: 'Course Name (Optional)',
            //             border: OutlineInputBorder(),
            //             hintText: 'Enter the course name',
            //           ),
            //         ),
            //         const SizedBox(height: 16),

            //         // Error display
            //         if (_voiceService.lastError.isNotEmpty)
            //           Container(
            //             padding: const EdgeInsets.all(12),
            //             margin: const EdgeInsets.only(bottom: 16),
            //             decoration: BoxDecoration(
            //               color: const Color(0xFF2D1818),
            //               borderRadius: BorderRadius.circular(8),
            //               border: Border.all(color: const Color(0xFFFF7A7A)),
            //             ),
            //             child: Row(
            //               children: [
            //                 const Icon(
            //                   Icons.error_outline,
            //                   color: Color(0xFFFF7A7A),
            //                 ),
            //                 const SizedBox(width: 8),
            //                 Expanded(
            //                   child: Text(
            //                     _voiceService.lastError,
            //                     style: const TextStyle(
            //                       color: Color(0xFFFFBBBB),
            //                     ),
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),

            //         // Recording button
            //         Center(
            //           child: GestureDetector(
            //             onTap: _toggleRecording,
            //             child: AnimatedBuilder(
            //               animation: _animationController,
            //               builder: (context, child) {
            //                 return Container(
            //                   width: 80,
            //                   height: 80,
            //                   decoration: BoxDecoration(
            //                     shape: BoxShape.circle,
            //                     color: _voiceService.isListening
            //                         ? const Color(
            //                             0xFF10E5FF,
            //                           ).withValues(alpha: 0.9)
            //                         : const Color(0xFF9D7FFF),
            //                     boxShadow: _voiceService.isListening
            //                         ? [
            //                             BoxShadow(
            //                               color: const Color(
            //                                 0xFF10E5FF,
            //                               ).withValues(alpha: 0.7),
            //                               blurRadius:
            //                                   20 * _animationController.value,
            //                               spreadRadius:
            //                                   5 * _animationController.value,
            //                             ),
            //                           ]
            //                         : [
            //                             BoxShadow(
            //                               color: const Color(
            //                                 0xFF9D7FFF,
            //                               ).withValues(alpha: 0.4),
            //                               blurRadius: 10,
            //                               spreadRadius: 3,
            //                             ),
            //                           ],
            //                   ),
            //                   child: Icon(
            //                     _voiceService.isListening
            //                         ? Icons.mic
            //                         : Icons.mic_none,
            //                     size: 40,
            //                     color: const Color(0xFFF5F5F5),
            //                   ),
            //                 );
            //               },
            //             ),
            //           ),
            //         ),
            //         const SizedBox(height: 8),

            //         // Status text
            //         Center(
            //           child: Text(
            //             _testMode
            //                 ? 'Test Mode Active'
            //                 : _voiceService.isListening
            //                 ? 'Listening... Describe your round!'
            //                 : 'Tap mic to record',
            //             style: Theme.of(context).textTheme.bodyMedium,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Test mode toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Test Mode', style: TextStyle(fontSize: 16)),
                      Switch(
                        value: _testMode,
                        onChanged: (value) {
                          setState(() {
                            _testMode = value;
                            if (value) {
                              _transcriptController.text =
                                  getCorrectTestDescription;
                              _voiceService.updateText(
                                getCorrectTestDescription,
                              );
                            }
                            // Don't auto-clear when disabled - user can use clear button
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      const Tooltip(
                        message: 'Uses test constant',
                        child: Icon(Icons.info_outline, size: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Use Shared Preferences toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Use Cached Round',
                        style: TextStyle(fontSize: 16),
                      ),
                      Switch(
                        value: _useSharedPreferences,
                        onChanged: (value) {
                          setState(() {
                            _useSharedPreferences = value;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      const Tooltip(
                        message: 'Load from storage instead of calling AI',
                        child: Icon(Icons.info_outline, size: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Round Description TextField with Clear Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _transcriptController,
                          maxLines: 8,
                          minLines: 5,
                          decoration: InputDecoration(
                            labelText: 'Round Description',
                            hintText:
                                'Enter or paste your round description...',
                            border: const OutlineInputBorder(),
                            alignLabelWithHint: true,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Clear transcript',
                              onPressed: () async {
                                // Show confirmation dialog
                                final bool? confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Clear Transcript?'),
                                    content: const Text(
                                      'This will clear all text. This cannot be undone.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFFFF7A7A,
                                          ),
                                        ),
                                        child: const Text('Clear'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  setState(() {
                                    _transcriptController.clear();
                                    _voiceService.clearText();
                                  });
                                }
                              },
                            ),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Test Parse button
                  if (_testMode)
                    ElevatedButton.icon(
                      onPressed: () {
                        _processAndNavigate(
                          transcript: getCorrectTestDescription,
                          courseName: testCourseName,
                          useSharedPreferences: _useSharedPreferences,
                        );
                      },
                      icon: const Icon(Icons.science),
                      label: const Text('Test Parse Constant'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9D4EDD),
                        foregroundColor: const Color(0xFFF5F5F5),
                      ),
                    ),

                  if (_testMode) const SizedBox(height: 12),

                  // Test Image + Voice button
                  if (_testMode)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ImportScoreScreen(
                              testMode: true,
                              testVoiceDescription: DescriptionConstants
                                  .flingsGivingRound2DescriptionNoHoleDistance,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Test Image + Voice (Pre-processed)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF137e66),
                        foregroundColor: const Color(0xFF0A0E17),
                      ),
                    ),
                ],
              ),
            ),
            // // Test/Debug Section
            // ExpansionTile(
            //   title: Row(
            //     children: [
            //       const Icon(Icons.science, size: 20),
            //       const SizedBox(width: 8),
            //       Text(
            //         'Test & Debug Tools',
            //         style: Theme.of(context).textTheme.titleSmall,
            //       ),
            //     ],
            //   ),
            //   children: [
            //     Padding(
            //       padding: const EdgeInsets.all(16.0),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.stretch,
            //         children: [
            //           // Test mode toggle
            //           Row(
            //             mainAxisAlignment: MainAxisAlignment.center,
            //             children: [
            //               const Text(
            //                 'Test Mode',
            //                 style: TextStyle(fontSize: 16),
            //               ),
            //               Switch(
            //                 value: _testMode,
            //                 onChanged: (value) {
            //                   setState(() {
            //                     _testMode = value;
            //                     if (value) {
            //                       _transcriptController.text =
            //                           getCorrectTestDescription;
            //                       _voiceService.updateText(
            //                         getCorrectTestDescription,
            //                       );
            //                     } else {
            //                       _transcriptController.clear();
            //                       _voiceService.clearText();
            //                     }
            //                   });
            //                 },
            //               ),
            //               const SizedBox(width: 8),
            //               const Tooltip(
            //                 message: 'Uses test constant',
            //                 child: Icon(Icons.info_outline, size: 16),
            //               ),
            //             ],
            //           ),

            //           const SizedBox(height: 8),

            //           // Use Shared Preferences toggle
            //           Row(
            //             mainAxisAlignment: MainAxisAlignment.center,
            //             children: [
            //               const Text(
            //                 'Use Cached Round',
            //                 style: TextStyle(fontSize: 16),
            //               ),
            //               Switch(
            //                 value: _useSharedPreferences,
            //                 onChanged: (value) {
            //                   setState(() {
            //                     _useSharedPreferences = value;
            //                   });
            //                 },
            //               ),
            //               const SizedBox(width: 8),
            //               const Tooltip(
            //                 message: 'Load from storage instead of calling AI',
            //                 child: Icon(Icons.info_outline, size: 16),
            //               ),
            //             ],
            //           ),

            //           const SizedBox(height: 16),

            //           // Test Parse button
            //           if (_testMode)
            //             ElevatedButton.icon(
            //               onPressed: _roundParser.isProcessing
            //                   ? null
            //                   : () async {
            //                       await _roundParser.parseVoiceTranscript(
            //                         getCorrectTestDescription,
            //                         courseName: testCourseName,
            //                         useSharedPreferences: _useSharedPreferences,
            //                       );

            //                       if (_roundParser.lastError.isNotEmpty &&
            //                           context.mounted) {
            //                         ScaffoldMessenger.of(context).showSnackBar(
            //                           SnackBar(
            //                             content: Text(_roundParser.lastError),
            //                           ),
            //                         );
            //                       }
            //                     },
            //               icon: _roundParser.isProcessing
            //                   ? const SizedBox(
            //                       height: 20,
            //                       width: 20,
            //                       child: CircularProgressIndicator(
            //                         strokeWidth: 2,
            //                       ),
            //                     )
            //                   : const Icon(Icons.science),
            //               label: Text(
            //                 _roundParser.isProcessing
            //                     ? 'Processing...'
            //                     : 'Test Parse Constant',
            //               ),
            //               style: ElevatedButton.styleFrom(
            //                 backgroundColor: const Color(0xFF9D4EDD),
            //                 foregroundColor: const Color(0xFFF5F5F5),
            //               ),
            //             ),

            //           if (_testMode) const SizedBox(height: 12),

            //           // Test Image + Voice button
            //           if (_testMode)
            //             ElevatedButton.icon(
            //               onPressed: () {
            //                 Navigator.of(context).push(
            //                   MaterialPageRoute(
            //                     builder: (context) => const ImportScoreScreen(
            //                       testMode: true,
            //                       testVoiceDescription:
            //                           flingsGivingRound2DescriptionNoHoleDistance,
            //                     ),
            //                   ),
            //                 );
            //               },
            //               icon: const Icon(Icons.image),
            //               label: const Text(
            //                 'Test Image + Voice (Pre-processed)',
            //               ),
            //               style: ElevatedButton.styleFrom(
            //                 backgroundColor: const Color(0xFF137e66),
            //                 foregroundColor: const Color(0xFF0A0E17),
            //               ),
            //             ),
            //         ],
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}
