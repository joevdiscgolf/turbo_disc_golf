// Constants for hole description education content.
// Edit these to update the examples shown to users.

/// A paired example showing a bad description and its good counterpart.
class ExamplePair {
  const ExamplePair({
    required this.outcome,
    required this.bad,
    required this.good,
    required this.missingNote,
  });

  /// The outcome type (e.g. "Par hole", "Bogey hole", "Birdie hole")
  final String outcome;

  /// The bad example description
  final String bad;

  /// The good example description
  final String good;

  /// Note explaining what's missing in the bad example
  final String missingNote;
}

/// Paired examples for side-by-side comparison.
const List<ExamplePair> examplePairs = [
  ExamplePair(
    outcome: 'Birdie hole',
    bad: 'Good drive down the middle, made the putt for birdie',
    good:
        'Threw my wraith on a hyzer flip backhand 450 ft and landed on the left side of the fairway, then threw a 350 ft straight backhand with my buzzz and landed 20 ft left then made the putt for birdie.',
    missingNote: 'Missing: disc name, shot type, distances',
  ),
  ExamplePair(
    outcome: 'Par hole',
    bad: 'Drive went straight, missed the birdie putt, tapped in',
    good:
        'Threw a backhand turnover with my destroyer to 35 ft short, then missed the birdie putt and tapped in for par.',
    missingNote: 'Missing: disc name, shot shape, distance',
  ),
  ExamplePair(
    outcome: 'Bogey hole',
    bad: 'Went OB off the tee, laid up to 20 ft, two-putted',
    good:
        'Threw my destroyer OB right on a forehand, then threw a tactic forehand from 150 ft out to 15 ft and made the bogey putt.',
    missingNote: 'Missing: disc names, shot types',
  ),
];

/// Key points that make a good hole description.
const String whatMakesGoodDescription = '''
A good hole description includes:

Disc name (e.g. "my Wraith", "a Buzzz")

Shot type (e.g. "backhand", "forehand")

Shot shape if applicable (e.g. "hyzer flip", "turnover")

Landing spot (e.g. "450 ft short", "left of fairway")

Must end with the disc going in the basket (e.g. "tapped in for par", "made the putt for bogey", "made the birdie from 20 ft")''';
