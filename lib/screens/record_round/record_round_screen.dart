import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/screens/import_score/import_score_screen.dart';
import 'package:turbo_disc_golf/screens/round_review/round_review_screen.dart';
import 'package:turbo_disc_golf/services/bag_service.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_round_service.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';
import 'package:turbo_disc_golf/services/voice_recording_service.dart';

const String testRoundDescription = '''
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
''';

// TEST STRING - PASTE YOUR TEST INPUT HERE
const String testRoundDescription2 = '''
Hole one is a 700 ft par-4 I threw my Destroyer on a big backhand line and it landed in the middle of the Fairway then I threw my md4 and parked it about 5 ft away and tapped it in for the birdie. Hole two is a 250 ft part 3 I threw my fd3 to Circle one about 25 ft away missed the putt off the cage and then miss the par putt because it's bad back at me so I took a bogey there whole three is a 380 ft downhill Par 3 pretty open I threw a power forehand but the right to left wind crushed it down 70 ft short then I tried to make the pup from 70 ft and it rolled to 15 ft and then I missed that 15-ft putt so I took a bogey whole four is a 260 ft Par 3 and there's one tree you have to miss and get underneath and I threw a perfect shot with my md4 got underneath the tree and made it to 10 ft and tap that in for birdie 05 is a 620 ft par 4 I threw a high turnover backhand with my dd3 into the middle of the Fairway and then through a good standstill backhand approach from 180 ft and made that 15 footer for birdie hole six is a short 250 ft part 3 but it is has a specific Landing Zone I threw my logic about 30 ft long and right and then I made that 35 ft come back or pot for birdie and whole seven is a par four 500 ft with a double Mando that you have to hit I made it through the double Mando off the tee and I threw a great second shot to get myself parked for the birdie top that in for the birdie three whole eight is a short 200-ft Par 3 I threw my forehand razor claw tactic to about 25 ft long and left made that birdie putt whole nine is a 320 ft downhill for hand wide open I threw my fd3 on a forehand and it landed 10 ft away from the basket Hole 10 is a pretty wide open 370 ft Par 3 I threw my PD on a hyzer and parked out under the basket 3 ft away tap that in for birdie whole 11 I threw my forehand fd3 a bit wide it's a 270-ft par 3 I ended up 35 ft short and left and made a great 35 ft pot for birdie Hole 12 is a 780 ft par 5 and I threw my cloudbreaker off the tee landed a bit left side of the Fairway which is what I wanted and then threw my second shot which caught a tree and landed short so I laid up and tapped in my birdie for and then whole 13 is a 400 ft downhill Par 3 with out of bounds on the right side I threw a forehand and it was too right and nose up and it faded out out of bounds on the right so I threw my second shot from out of bounds and that missed so I had a bogey putt which I made from 25 ft whole 14 is a 900 ft par 5 I threw my Destroyer on a flexshot off the tee then I threw a different Destroyer on a Flex Shot around the right side and then I laid up with a hundred foot four-hand approach to give myself a short birdie putt which I made for birdie whole 15 is a low ceiling tight Par 3 250 ft I threw a good shot down the middle low and left myself 25 ft left and short made that birdie putt whole 16 is a 260 ft Par 3 with a gap of trees that you have to hit late in the Fairway and I perfectly threw my backhand through that Gap and I ended up 25 ft past the basket and made that putt for birdie whole 17 is a 600 ft par 4 with a double mandatory that you have to go through halfway up the Fairway I threw a backhand just short of that and then through a backhand Md4 to 25 ft and then I missed that Putt and then I made a 25-ft par putt whole 18 is a 620 ft par 4 where you have to hit a gap in the trees 200 ft off the tee I hit the Gap but threw it a little bit too high so I got dropped down 340 ft short but had a wide open shot to throw my PD on a backhand and landed about 20 ft away and I made that birdie putt 
''';

// TEST STRING - PASTE YOUR TEST INPUT HERE
const String testRoundDescription3 = '''
Whole one is a 260 ft downhill Par 3 I threw my md3 on a backhand and it came up like 45 ft short but right online and then I hit a 45 footer for birdie hold two is a 400 ft power floor slightly uphill I threw my instinct on a backhand but the headwind flipped it up a little bit into the tree so I just had to lay up for birdie and tap that in for a birdie Whole three is a 230 ft Par 3 I pulled my forehand to the left off the tee and hit a tree so I had to lay up which left me a 32 ft putt for par which I made whole four is a 250 ft Par 3 wide open I threw my tactic on my backhand hyzer and ended up 15 ft short and left and made that putt whole five is a 250 ft tunnel shot down a gap and I threw a perfect backend shot with my tactic and tap that in for birdie hole 6 is a 220 ft Par 3 wide open and I just threw a forehand and put it really close to 10 ft already that whole seven is a 240-ft par 3 that requires a high Heiser over the trees so I threw my tactic on a high Heiser and came up short and had to make a 35 ft putt for birdie which I did whole eight is a 500 ft par-4 I threw my drive a little bit left into the trees so it came down like a hundred feet short and I threw a hundred foot jump putter approach and tap that in for birdie whole nine is a 210-ft par 3 I threw my tactic and ended up about 30 ft short and left and made that birdie putt whole 10 is a 340 ft downhill Par 3 I threw a forehand with a destroyer and ended up 25 ft long and I missed the putt because it went straight through the basket so I got to par on that hole hole 11 is a 500 ft Straight Ahead Par Four I hit a tree off shortly off the tee because I released it left with my backhand and then I threw another back in which I released left and hit another tree and had to do a forehand layup to tap in for the par hole 12 is a 280 foot Par 3 wide open I threw a high hyzer with my tactic and ended up 45 ft short and made that birdie putt whole 13 is a 360 ft Par 3 I threw my Glacier on a backhand and ended up 30 ft long and I made that putt for birdie whole 14 is a 260 ft dead straight Par 3 I threw my tactic to about 10 ft and tap that in for birdie whole 15 as a 240 ft wide open hole and I threw a forehand tactic to about 10 ft tap that in for birdie whole 16 is a 360 ft slightly uphill Par 3 through a gap in the trees I threw my buzz and ended up 30 ft left and a little bit short and made that putt for birdie and then hole 17 is a 650-ft par 4 I threw my drive really far but on the left side of the Fairway and had to throw a backhand with an fd3 skip shot to give myself a 30-ft putt which I made for the birdie and then whole 18 is a 280 ft Par 3 pretty wide open I threw my md3 on a backhand and ended up about 10 ft away and tap that in for birdie 
''';

const String testRoundDescription4 = '''
Whole one is a 200-ft par 3 on a hill that is sloped I threw my tactic on a backhand and parked it and tap that in for the birdie Hole 2 is a downhill 160 ft hole wide open I threw my tactic to 30 ft and then made the birdie putt whole three is a wide open 250 ft hole I threw my md3 on the backhand and ended up 40 ft short attempted that part ended up 20 ft long and then missed that putt for par so I took a bogey whole four is a 250 ft backhand through the woods it's a backhand hyzer line I hit a tree and landed in the Fairway and then through a forehand to approach the basket and tapped in for the par hole five is a short 140 ft Par 3 I threw a forehand to 20 ft and made the birdie putt '06 is a short 180 ft Par 3 I threw a backhand standstill shot with my Putter and parked that took the birdie whole seven is a tunnel forehand Shot Through the Woods I threw my Vanguard on a forehand and ended up 30 ft short and right and made a putt around a tree to get the birdie whole eight is a 180 ft Par 3 through some trees I hit a gap with a forehand and parked it and tapped it in for birdie with my tactic hole nine is a pretty tightly wooded hole I threw a backhand and it hit a tree and I had to lay up with a forehand on the second shot and then made the par putt for par whole 10 is a 280 ft uphill Par 3 I threw my Vanguard but ended up 70 ft left and long so I laid that up and tapped in for the par hole 11 is a 315-ft par 3 I threw my with a low ceiling I threw my instinct to 25 ft just inside the bushes and made the birdie putt whole 12 is a 330 ft wide open Par 3 I threw my Glacier on a backhand and parked it and tapped it in for the birdie whole 13 is a tight low ceiling hole that I threw a forehand on and hit a tree and laid up and tapped in for the par the next hole hole 14 was a 220 ft Par 3 I threw a backhand hyzer with my md3 to 10 ft and tap that in for the birdie whole 15 is a low ceiling shot I tried to throw a forehand but hit a tree it's a 300 ft hole and then I threw my approach to 30 ft and made the pot for par hole 16 is a 320 ft Par 3 through the woods tight Fairway I threw a forehand and hit the last tree and ended up 60 ft left and try to make the pot missed tapped in for the par hole 17 is a 260 ft Par 3 I had to hit a gap on a forehand with my Vanguard and parked the shot so tapped in for birdie and then hole 18 is a tight backhand shot about 300 ft I hit a tree with my Vanguard and kicked left then my neck shot I tried to scramble to get close but that also hit a tree my third shot was a putt and I hit a tree and dropped down so I had to put to try to make the bogey and I miss that from 30 ft and I tapped in for double bogey on the 18th hole 
''';

const String flingsGivingRound2Description = '''
Whole one is a 600 ft par 4 that's wide open in downhill at the start and then goes into the trees for the second part I threw my halo Destroyer off the tee on a backhand just flat and it ended up just into the trees and 140 ft away and I threw a forehand up shot with my razor claw and that parked at 10 ft away so I buried hold two is a 170 ft Par 3 pretty wide open I threw a forehand tactic out to the left side on Heiser and parked it two feet away all three is a wide open 370 ft Par 3 I threw my PD on a backhand hyzer and ended up 25 ft left with a birdie putt I miss that Putt and then I missed the comeback butt from 25 ft so I tapped in for a bogey on that hole whole four is a 380 ft Par 3 it's pretty wide open but the green is protected by some trees I threw a backhand hyzer with a pd2 out to the right and then I ended up 25 ft long and out of bounds and I made my par put from 25 ft whole five was a 440 ft par 4 I threw a forehand off the tee and had another forehand approach from 140 ft into the green and made a 23 ft pot for birdie whole six is a wide open and 30 ft Par 3 I threw a backhand hyzer with my md4 to 25 ft and made the putt whole seven is a 500 ft powerful through a bunch of trees pretty tight I hit the first tree with my cloud breaker on a backhand and then I threw my second shot with a backhand dd3 and hit another tree and ended up 250 ft short I threw a forehand pd2 through the trees to try to get a par but it ended up 45 ft away I tried to make the 45 foot pot for par I missed that and went out of bounds past the basket and then I missed my 15-ft pot for double bogey and tapped in for a triple bogey.Call 8 is a 240 ft pretty wide open hole with a low ceiling off the tee I threw my fd3 on a forehand hyzer and threw it to 15 ft and made that putt whole nine is a 300 ft downhill Par 3 wide open until the very end where the basket is just into the forest I threw my pd2 on a forehand flat shot and threw it to 28 ft and made the putt through the woods for birdie whole 10 is a 550 ft par 4 that's wide open most of the way and then finishes where the basket is guarded by trees I threw my wraith on a backhand turnover and it hit a tree stopping at 80 ft short and then I laid up that putt to about 10 ft and tapped in for birdie then hole 11 is a 315-ft par 3 pretty wide open until the end where the basket is in a Grove of pine trees I threw my fd3 on a backhand hyzer out to the right side and low and it skipped up to 3 ft away from the basket and I tap that in for birdie whole 12 is a 200 ft wide open Par 3 I threw a forehand md5 to about 10 ft and tap that in for birdie whole 13 is a 800 ft par 5 very wide open with out of bounds on the left and right I threw my wraith on a backhand hyzer flip to about 315 ft away from the basket then I threw my buzz to 28 ft left of the basket and I miss that putt just low for Eagle so I tapped in for the birdie whole 14 is a 340 ft wide open Par 3 with some trees guarding the basket at the end I threw it a little bit short and left to 50 ft and laid that up to tap in for par whole 15 is a wide open Par 3 where you just have to get over a bunker in front of the basket I threw a forehand into a tree On the left and laid that up that ended up 50 ft away and laid that up to tap in for the par hole 16 starts wide open and then finishes into a Grove of trees with a big opening I threw my Razor cloth on a forehand and it ended up 25 ft short and right and I made that putt for birdie whole 17 is a wide open 700 ft power 4 I threw my wraith on a backhand hyzer flip and ended up in the Fairway and then I had 215 ft into the basket I threw a skip shot with my md5 on a backhand which rolled and ended up 35 ft away I missed that putt for birdie and had a 20 ft pop back for par I missed that putt for par and made it 20 ft pot for bogey on 18 it's a 400 ft Par 3 without a bounds on the left and right but wide open otherwise I threw my md1 on a backhand turnover and threw it to 40 ft left and short and laid up and tapped in for the three 
''';

const String elevenUnderWhitesDescriptionNoHoleDistance = '''
Hole one I threw my Destroyer on a big backhand line and it landed in the middle of the Fairway then I threw my md4 and parked it about 5 ft away and tapped it in for the birdie. Hole two I threw my fd3 to Circle one about 25 ft away missed the putt off the cage and then miss the par putt because it's bad back at me so I took a bogey there. Hole three pretty open I threw a power forehand but the right to left wind crushed it down 70 ft short then I tried to make the putt from 70 ft and it rolled to 15 ft and then I missed that 15-ft putt so I took a bogey. Hole four there's one tree you have to miss and get underneath and I threw a perfect shot with my md4 got underneath the tree and made it to 10 ft and tapped that in for birdie. Hole five I threw a high turnover backhand with my dd3 into the middle of the Fairway and then threw a good standstill backhand approach from 180 ft and made that 15 footer for birdie. Hole six is short but it has a specific Landing Zone. I threw my logic about 30 ft long and right and then I made that 35 ft come back putt for birdie. Hole seven with a double Mando that you have to hit I made it through the double Mando off the tee and I threw a great second shot to get myself parked for the birdie tapped that in for the birdie three. Hole eight I threw my forehand razor claw tactic to about 25 ft long and left made that birdie putt. Hole nine is downhill and wide open I threw my fd3 on a forehand and it landed 10 ft away from the basket. Hole ten is pretty wide open I threw my PD on a hyzer and parked out under the basket 3 ft away tapped that in for birdie. Hole eleven I threw my forehand fd3 a bit wide I ended up 35 ft short and left and made a great 35 ft putt for birdie. Hole twelve I threw my cloudbreaker off the tee landed a bit left side of the Fairway which is what I wanted and then threw my second shot which caught a tree and landed short so I laid up and tapped in my birdie for. Hole thirteen with out of bounds on the right side I threw a forehand and it was too right and nose up and it faded out out of bounds on the right so I threw my second shot from out of bounds and that missed so I had a bogey putt which I made from 25 ft. Hole fourteen I threw my Destroyer on a flexshot off the tee then I threw a different Destroyer on a Flex Shot around the right side and then I laid up with a hundred foot forehand approach to give myself a short birdie putt which I made for birdie. Hole fifteen is a low ceiling tight hole I threw a good shot down the middle low and left myself 25 ft left and short made that birdie putt. Hole sixteen has a gap of trees that you have to hit late in the Fairway and I perfectly threw my backhand through that Gap and I ended up 25 ft past the basket and made that putt for birdie. Hole seventeen with a double mandatory that you have to go through halfway up the Fairway I threw a backhand just short of that and then threw a backhand Md4 to 25 ft and then I missed that putt and then I made a 25-ft par putt. Hole eighteen where you have to hit a gap in the trees 200 ft off the tee I hit the Gap but threw it a little bit too high so I got dropped down short but had a wide open shot to throw my PD on a backhand and landed about 20 ft away and I made that birdie putt.
''';

const String flingsGivingRound2DescriptionNoHoleDistance = '''
Hole one is wide open and downhill at the start and then goes into the trees for the second part. I threw my halo Destroyer off the tee on a backhand just flat and it ended up just into the trees and 140 ft away and I threw a forehand upshot with my razor claw and that parked at 10 ft away so I birdied. Hole two is pretty wide open. I threw a forehand tactic out to the left side on hyzer and parked it two feet away. Hole three is wide open. I threw my PD on a backhand hyzer and ended up 25 ft left with a birdie putt. I missed that putt and then I missed the comeback putt from 25 ft so I tapped in for a bogey on that hole. Hole four is pretty wide open but the green is protected by some trees. I threw a backhand hyzer with a pd2 out to the right and then I ended up 25 ft long and out of bounds and I made my par putt from 25 ft. Hole five I threw a forehand off the tee and had another forehand approach from 140 ft into the green and made a 23 ft putt for birdie. Hole six is wide open. I threw a backhand hyzer with my md4 to 25 ft and made the putt. Hole seven goes through a bunch of trees, pretty tight. I hit the first tree with my cloud breaker on a backhand and then I threw my second shot with a backhand dd3 and hit another tree and ended up short. I threw a forehand pd2 through the trees to try to get a par but it ended up 45 ft away. I tried to make the 45-ft putt for par, I missed that and went out of bounds past the basket, and then I missed my 15-ft putt for double bogey and tapped in for a triple bogey. Hole eight is pretty wide open with a low ceiling off the tee. I threw my fd3 on a forehand hyzer and threw it to 15 ft and made that putt. Hole nine is downhill and wide open until the very end where the basket is just into the forest. I threw my pd2 on a forehand flat shot and threw it to 28 ft and made the putt through the woods for birdie. Hole ten is wide open most of the way and then finishes where the basket is guarded by trees. I threw my wraith on a backhand turnover and it hit a tree stopping at 80 ft short and then I laid up that putt to about 10 ft and tapped in for birdie. Hole eleven is pretty wide open until the end where the basket is in a grove of pine trees. I threw my fd3 on a backhand hyzer out to the right side and low and it skipped up to 3 ft away from the basket and I tapped that in for birdie. Hole twelve is wide open. I threw a forehand md5 to about 10 ft and tapped that in for birdie. Hole thirteen is very wide open with out of bounds on the left and right. I threw my wraith on a backhand hyzer flip and then I threw my buzz left of the basket and I missed that putt just low for eagle so I tapped in for the birdie. Hole fourteen is wide open with some trees guarding the basket at the end. I threw it a little bit short and left to 50 ft and laid that up to tap in for par. Hole fifteen is wide open where you just have to get over a bunker in front of the basket. I threw a forehand into a tree on the left and that ended up 50 ft away and I laid that up to tap in for the par. Hole sixteen starts wide open and then finishes into a grove of trees with a big opening. I threw my razor claw on a forehand and it ended up 25 ft short and right and I made that putt for birdie. Hole seventeen is wide open. I threw my wraith on a backhand hyzer flip and ended up in the fairway and then I had a shot into the basket. I threw a skip shot with my md5 on a backhand which rolled and ended up 35 ft away. I missed that putt for birdie and had a 20 ft putt back for par. I missed that putt for par and made a 20-ft putt for bogey. Hole eighteen has out of bounds on the left and right but is wide open otherwise. I threw my md1 on a backhand turnover and threw it to 40 ft left and short and laid up and tapped in for the three.
''';

const testRoundDescriptions = [
  testRoundDescription,
  testRoundDescription2,
  testRoundDescription3,
  testRoundDescription4,
  flingsGivingRound2Description,
  elevenUnderWhitesDescriptionNoHoleDistance,
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
  late final RoundParser _roundParser;
  late AnimationController _animationController;
  final TextEditingController _transcriptController = TextEditingController();
  final TextEditingController _courseNameController = TextEditingController();
  bool _testMode = true;
  bool _useSharedPreferences = false;
  String? _lastNavigatedRoundId;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceRecordingService();
    _bagService = locator.get<BagService>();
    _roundParser = locator.get<RoundParser>();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _initializeServices();

    // Listen to voice service changes
    _voiceService.addListener(_onVoiceServiceChange);
    _roundParser.addListener(_onParserChange);

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

  void _onParserChange() {
    // Only navigate if this is a newly parsed round (not loaded from history)
    if (_roundParser.parsedRound != null &&
        _roundParser.shouldNavigateToReview &&
        mounted) {
      final roundId = _roundParser.parsedRound!.id;

      // Only navigate if this is a new round (not already navigated to)
      if (roundId != _lastNavigatedRoundId) {
        _lastNavigatedRoundId = roundId;
        _roundParser.clearNavigationFlag(); // Clear the flag before navigating

        final round = _roundParser.parsedRound!;

        // Navigate to review screen with story shown on load
        Navigator.push(
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
                            } else {
                              _transcriptController.clear();
                              _voiceService.clearText();
                            }
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

                  const SizedBox(height: 16),

                  // Test Parse button
                  if (_testMode)
                    ElevatedButton.icon(
                      onPressed: _roundParser.isProcessing
                          ? null
                          : () async {
                              await _roundParser.parseVoiceTranscript(
                                getCorrectTestDescription,
                                courseName: testCourseName,
                                useSharedPreferences: _useSharedPreferences,
                              );

                              if (_roundParser.lastError.isNotEmpty &&
                                  context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_roundParser.lastError),
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
                              testVoiceDescription:
                                  flingsGivingRound2DescriptionNoHoleDistance,
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
