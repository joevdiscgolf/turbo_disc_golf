import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/services/voice_recording_service.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/gemini_service.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/screens/round_review_screen.dart';
import 'package:turbo_disc_golf/screens/raw_response_dialog.dart';

class VoiceRecordingScreen extends StatefulWidget {
  const VoiceRecordingScreen({super.key});

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen>
    with SingleTickerProviderStateMixin {
  String get getCorrectTestDescription =>
      _useSecondaryDescription ? testRoundDescription2 : testRoundDescription;
  late final VoiceRecordingService _voiceService;
  late final BagService _bagService;
  late final GeminiService _geminiService;
  late final RoundParser _roundParser;
  late AnimationController _animationController;
  final TextEditingController _transcriptController = TextEditingController();
  final TextEditingController _courseNameController = TextEditingController();
  bool _testMode = false;

  static const bool _useSecondaryDescription = true;

  // TEST STRING - PASTE YOUR TEST INPUT HERE
  static const String testRoundDescription = '''
Hole 1 was a 350 foot par 3. I threw my Star Destroyer with a backhand hyzer about 300 feet, ended up in circle 1. Made the putt with my Judge for birdie.

Hole 2, 425 feet par 4. Threw my Champion Firebird forehand on a flex shot about 275 feet, had to throw around some trees. Then threw my ESP Buzzz with a standstill shot about 120 feet to get to circle 2. Missed the first putt from 45 feet, made the comeback putt for par.

Hole 3 was a tight tunnel shot, 380 feet par 3. Threw my Opto River backhand flat, hit the gap perfectly and parked it about 15 feet from the basket. Made the putt for another birdie.

Hole 4, downhill 285 feet par 3. Wind was blowing left to right. Threw my ESP Buzzz on an anhyzer, it flipped up and rode the wind, landed pin high but 30 feet right. Made a nice approach with my Judge to 5 feet, made the par putt.

Hole 5 was a bomber hole, 550 feet par 4. Threw my Star Destroyer backhand with a hyzer flip, got a full flight about 400 feet. Second shot threw my Opto River 130 feet to circle 1. Made the 20 foot putt for birdie.

Hole 6, island hole 200 feet par 3 over water. Played it safe with my Classic Judge, threw it straight at the basket. Landed on the island about 40 feet short. Missed the putt, tapped in for par.

Hole 7, 475 feet par 4 dogleg left. Threw Champion Firebird forehand around the corner about 280 feet. Had 195 feet left, threw my ESP Buzzz but it faded early into the rough. Pitch out with my Judge to 25 feet, made the putt for par.

Hole 8, uphill 315 feet par 3. Threw my Opto River with a hyzer flip but it turned over too much and went OB right. Re-teed, threw my ESP Buzzz straight up the gut 280 feet. Made the 35 foot putt for bogey after the penalty.

Hole 9, 390 feet par 4 with low ceiling. Had to throw my Champion Firebird on a low forehand roller. It rolled about 320 feet and stayed in bounds. Approached with my Judge from 70 feet to circle 1. Two putts for par.

Hole 10, open 425 feet par 3. Threw Star Destroyer on a flex shot, got about 380 feet. Long jump putt from 45 feet hit the cage but didn't go in. Tapped in for par.

Hole 11 was short, 265 feet par 3 but heavily wooded. Threw a forehand with my ESP Buzzz through the gap. It hit a tree about 200 feet out and kicked left. Scrambled with my Judge, hit another tree. Third shot made it to circle 2. Made a 50 footer for par!

Hole 12, 510 feet par 5. First throw Star Destroyer backhand got 350 feet. Second shot Opto River went 140 feet to circle 1. Made the putt for eagle.

Hole 13, elevated basket 340 feet par 3. The pin was on a 20 foot high mound. Threw my Champion Firebird on a spike hyzer to land soft, ended up 60 feet short. Threw my Judge up the hill to 10 feet. Made the putt for par.

Hole 14, 185 feet par 3 ace run. Threw my Judge on a slight hyzer line right at the chains. Hit the top band and dropped straight down. 2 feet away! Easy birdie.

Hole 15, 600 feet par 5 with water right. Threw Star Destroyer backhand staying safe left, about 380 feet. Second shot ESP Buzzz 180 feet, still had 40 feet. Upshot with the Judge to 8 feet, made it for birdie.

Hole 16 was a tunnel shot then opens up, 445 feet par 4. Threw Opto River low and straight through the tunnel, made it through clean about 280 feet. Threw my ESP Buzzz for the approach but it went long, 40 feet past. Made the comeback putt for birdie.

Hole 17, 290 feet par 3 slight uphill. Headwind was brutal. Threw my Champion Firebird flat and it fought through the wind, parked it 15 feet away. Made the putt for birdie.

Hole 18, finishing hole 465 feet par 4. Wanted to end strong. Threw Star Destroyer on a perfect hyzer flip, got my longest drive of the day at 420 feet! Made a great putt with my Judge from 45 feet for an eagle to finish the round!
'''; // <-- PASTE YOUR TEST STRING HERE

  // TEST STRING - PASTE YOUR TEST INPUT HERE
  static const String testRoundDescription2 = '''
Hole one is a 700 ft par-4 I threw my Destroyer on a big backhand line and it landed in the middle of the Fairway then I threw my md4 and parked it about 5 ft away and tapped it in for the birdie. Hole two is a 250 ft part 3 I threw my fd3 to Circle one about 25 ft away missed the putt off the cage and then miss the par putt because it's bad back at me so I took a bogey there whole three is a 380 ft downhill Par 3 pretty open I threw a power forehand but the right to left wind crushed it down 70 ft short then I tried to make the pup from 70 ft and it rolled to 15 ft and then I missed that 15-ft putt so I took a bogey whole four is a 260 ft Par 3 and there's one tree you have to miss and get underneath and I threw a perfect shot with my md4 got underneath the tree and made it to 10 ft and tap that in for birdie 05 is a 620 ft par 4 I threw a high turnover backhand with my dd3 into the middle of the Fairway and then through a good standstill backhand approach from 180 ft and made that 15 footer for birdie hole six is a short 250 ft part 3 but it is has a specific Landing Zone I threw my logic about 30 ft long and right and then I made that 35 ft come back or pot for birdie and whole seven is a par four 500 ft with a double Mando that you have to hit I made it through the double Mando off the tee and I threw a great second shot to get myself parked for the birdie top that in for the birdie three whole eight is a short 200-ft Par 3 I threw my forehand razor claw tactic to about 25 ft long and left made that birdie putt whole nine is a 320 ft downhill for hand wide open I threw my fd3 on a forehand and it landed 10 ft away from the basket Hole 10 is a pretty wide open 370 ft Par 3 I threw my PD on a hyzer and parked out under the basket 3 ft away tap that in for birdie whole 11 I threw my forehand fd3 a bit wide it's a 270-ft par 3 I ended up 35 ft short and left and made a great 35 ft pot for birdie Hole 12 is a 780 ft par 5 and I threw my cloudbreaker off the tee landed a bit left side of the Fairway which is what I wanted and then threw my second shot which caught a tree and landed short so I laid up and tapped in my birdie for and then whole 13 is a 400 ft downhill Par 3 with out of bounds on the right side I threw a forehand and it was too right and nose up and it faded out out of bounds on the right so I threw my second shot from out of bounds and that missed so I had a bogey putt which I made from 25 ft whole 14 is a 900 ft par 5 I threw my Destroyer on a flexshot off the tee then I threw a different Destroyer on a Flex Shot around the right side and then I laid up with a hundred foot four-hand approach to give myself a short birdie putt which I made for birdie whole 15 is a low ceiling tight Par 3 250 ft I threw a good shot down the middle low and left myself 25 ft left and short made that birdie putt whole 16 is a 260 ft Par 3 with a gap of trees that you have to hit late in the Fairway and I perfectly threw my backhand through that Gap and I ended up 25 ft past the basket and made that putt for birdie whole 17 is a 600 ft par 4 with a double mandatory that you have to go through halfway up the Fairway I threw a backhand just short of that and then through a backhand Md4 to 25 ft and then I missed that Putt and then I made a 25-ft par putt whole 18 is a 620 ft par 4 where you have to hit a gap in the trees 200 ft off the tee I hit the Gap but threw it a little bit too high so I got dropped down 340 ft short but had a wide open shot to throw my PD on a backhand and landed about 20 ft away and I made that birdie putt 
'''; // <-- PASTE YOUR TEST STRING HERE

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceRecordingService();
    _bagService = BagService();
    _geminiService = GeminiService(); // You'll need to add API key management
    _roundParser = RoundParser(
      geminiService: _geminiService,
      bagService: _bagService,
    );

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

  void _onParserChange() {
    if (_roundParser.parsedRound != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoundReviewScreen(
            round: _roundParser.parsedRound!,
            roundParser: _roundParser,
            bagService: _bagService,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceServiceChange);
    _roundParser.removeListener(_onParserChange);
    _voiceService.dispose();
    _animationController.dispose();
    _transcriptController.dispose();
    _courseNameController.dispose();
    super.dispose();
  }

  void _toggleRecording() async {
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
      _animationController.stop();
    } else {
      await _voiceService.startListening();
      _animationController.repeat();
    }
    setState(() {});
  }

  void _parseRound() async {
    if (_transcriptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please record or enter a round description'),
        ),
      );
      return;
    }

    await _roundParser.parseVoiceTranscript(
      _transcriptController.text,
      courseName: _courseNameController.text.isNotEmpty
          ? _courseNameController.text
          : null,
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
      appBar: AppBar(
        title: const Text('Record Your Round'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _courseNameController,
              decoration: const InputDecoration(
                labelText: 'Course Name (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Enter the course name',
              ),
            ),
            const SizedBox(height: 24),

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
                        // Load constant test string
                        _transcriptController.text = getCorrectTestDescription;
                        _voiceService.updateText(getCorrectTestDescription);
                      } else {
                        _transcriptController.clear();
                        _voiceService.clearText();
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                const Tooltip(
                  message: 'Uses TEST_ROUND_DESCRIPTION constant from line 27',
                  child: Icon(Icons.info_outline, size: 16),
                ),
              ],
            ),

            // Test Parse button - only visible in test mode
            if (_testMode) ...[
              ElevatedButton.icon(
                onPressed: _roundParser.isProcessing
                    ? null
                    : () async {
                        // Parse the test constant directly
                        await _roundParser.parseVoiceTranscript(
                          getCorrectTestDescription,
                          courseName: _courseNameController.text.isNotEmpty
                              ? _courseNameController.text
                              : null,
                        );

                        if (_roundParser.lastError.isNotEmpty &&
                            context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_roundParser.lastError)),
                          );
                        } else if (_geminiService.lastRawResponse != null &&
                            context.mounted) {
                          // Show raw response dialog after successful parsing
                          showDialog(
                            context: context,
                            builder: (context) => RawResponseDialog(
                              rawResponse: _geminiService.lastRawResponse!,
                            ),
                          );
                        }
                      },
                icon: _roundParser.isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.science),
                label: Text(
                  _roundParser.isProcessing
                      ? 'Processing...'
                      : 'Test Parse Constant',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Show Raw Response button - only if there's a response
              if (_geminiService.lastRawResponse != null)
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => RawResponseDialog(
                        rawResponse: _geminiService.lastRawResponse!,
                      ),
                    );
                  },
                  icon: const Icon(Icons.code),
                  label: const Text('Show Last Raw Response'),
                ),
            ],

            const SizedBox(height: 24),

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
                            ? Colors.red.withValues(alpha: 0.8)
                            : Theme.of(context).primaryColor,
                        boxShadow: _voiceService.isListening
                            ? [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 20 * _animationController.value,
                                  spreadRadius: 5 * _animationController.value,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        _voiceService.isListening ? Icons.mic : Icons.mic_none,
                        size: 40,
                        color: Colors.white,
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
                _testMode
                    ? 'Test Mode Active - Edit TEST_ROUND_DESCRIPTION in code'
                    : _voiceService.isListening
                    ? 'Listening... Describe your round!'
                    : 'Tap mic to record with voice',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
