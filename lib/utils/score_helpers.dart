import 'package:turbo_disc_golf/models/data/throw_data.dart';

int getScoreFromThrows(List<DiscThrow> throws) {
  return throws.fold(0, (prev, current) => prev + current.totalStrokes).toInt();
}

/// Formats a relative score as a string.
/// Returns 'E' for even par, '+X' for over par, and '-X' for under par.
String getRelativeScoreString(int relativeScore) {
  if (relativeScore == 0) {
    return 'E';
  } else if (relativeScore < 0) {
    return relativeScore.toString();
  } else {
    return '+$relativeScore';
  }
}
