import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';

class ScoreAnalysisService {
  /// Get overall scoring statistics
  ScoringStats getScoringStats(DGRound round) {
    int birdies = 0;
    int pars = 0;
    int bogeys = 0;
    int doubleBogeyPlus = 0;

    for (var hole in round.holes) {
      final score = hole.relativeHoleScore;
      if (score < 0) {
        birdies++;
      } else if (score == 0) {
        pars++;
      } else if (score == 1) {
        bogeys++;
      } else {
        doubleBogeyPlus++;
      }
    }

    return ScoringStats(
      totalHoles: round.holes.length,
      birdies: birdies,
      pars: pars,
      bogeys: bogeys,
      doubleBogeyPlus: doubleBogeyPlus,
    );
  }
}
