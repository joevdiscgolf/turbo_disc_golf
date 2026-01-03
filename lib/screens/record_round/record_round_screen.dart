import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/screens/import_score/import_score_screen.dart';
import 'package:turbo_disc_golf/screens/round_processing/round_processing_loading_screen.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/voice/base_voice_recording_service.dart';
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
  late final BaseVoiceRecordingService _voiceService;
  late final BagService _bagService;
  late AnimationController _animationController;
  final TextEditingController _transcriptController = TextEditingController();
  final TextEditingController _courseNameController = TextEditingController();
  bool _testMode = true;
  bool _useSharedPreferences = false;

  @override
  void initState() {
    super.initState();
    _voiceService = locator.get<BaseVoiceRecordingService>();
    _bagService = locator.get<BagService>();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _initializeServices();

    // Listen to voice service changes only
    _voiceService.addListener(_onVoiceServiceChange);
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
    Course? selectedCourse,
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
          selectedCourse: selectedCourse,
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
    final double topViewPadding = MediaQuery.of(context).viewPadding.top;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: GenericAppBar(
        topViewPadding: topViewPadding,
        title: 'Record Your Round',
        hasBackButton: false,
        rightWidget: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subtitle
            Text(
              'Import from screenshot or paste description',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFFB0B0B0)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Compact Image + Voice Card
            _buildImageVoiceCard(context),

            const SizedBox(height: 12),

            // Compact Divider with "OR"
            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFF334155))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
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

            const SizedBox(height: 12),

            // Test Mode Toggles - Compact
            if (_testMode) _buildTestModeToggles(),

            // Round Description TextField - Prominent
            _buildRoundDescriptionField(),

            const SizedBox(height: 12),

            // Test Buttons - Compact
            if (_testMode) _buildTestButtons(),

            // Extra bottom padding for keyboard visibility
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImageVoiceCard(BuildContext context) {
    return Card(
      color: const Color(0xFF1E293B),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            CupertinoPageRoute(builder: (context) => const ImportScoreScreen()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF137e66).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.image,
                  color: Color(0xFF137e66),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import from Screenshot',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Upload scorecard + voice description',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFB0B0B0),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestModeToggles() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('Test Mode', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 4),
                  Tooltip(
                    message: 'Uses test constant',
                    child: Icon(Icons.info_outline, size: 14),
                  ),
                ],
              ),
              Switch(
                value: _testMode,
                onChanged: (value) {
                  setState(() {
                    _testMode = value;
                    if (value) {
                      _transcriptController.text = getCorrectTestDescription;
                      _voiceService.updateText(getCorrectTestDescription);
                    }
                  });
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('Use Cached Round', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 4),
                  Tooltip(
                    message: 'Load from storage',
                    child: Icon(Icons.info_outline, size: 14),
                  ),
                ],
              ),
              Switch(
                value: _useSharedPreferences,
                onChanged: (value) {
                  setState(() {
                    _useSharedPreferences = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoundDescriptionField() {
    return Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Round Description',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_transcriptController.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: () async {
                      final bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear Description?'),
                          content: const Text(
                            'This will clear all text. This cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFFF7A7A),
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
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF7A7A),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _transcriptController,
              maxLines: 6,
              minLines: 4,
              style: const TextStyle(fontSize: 15),
              scrollPadding: const EdgeInsets.only(bottom: 300),
              decoration: InputDecoration(
                hintText: 'Enter or paste your round description here...',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF137e66),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Create a test Course object
            final String courseId = testCourseName.toLowerCase().replaceAll(
              ' ',
              '-',
            );
            final CourseLayout testLayout = CourseLayout(
              id: 'default',
              name: 'Default Layout',
              isDefault: true,
              holes: List.generate(
                18,
                (int i) => CourseHole(holeNumber: i + 1, par: 3, feet: 300),
              ),
            );
            final Course testCourse = Course(
              id: courseId,
              name: testCourseName,
              layouts: [testLayout],
            );

            _processAndNavigate(
              transcript: getCorrectTestDescription,
              selectedCourse: testCourse,
              useSharedPreferences: _useSharedPreferences,
            );
          },
          icon: const Icon(Icons.science, size: 18),
          label: const Text('Test Parse Constant'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9D4EDD),
            foregroundColor: const Color(0xFFF5F5F5),
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => const ImportScoreScreen(
                  testMode: true,
                  testVoiceDescription: DescriptionConstants
                      .flingsGivingRound2DescriptionNoHoleDistance,
                ),
              ),
            );
          },
          icon: const Icon(Icons.image, size: 18),
          label: const Text('Test Image + Voice'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF137e66),
            foregroundColor: const Color(0xFF0A0E17),
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
      ],
    );
  }
}
