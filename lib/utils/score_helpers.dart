import 'package:turbo_disc_golf/models/data/throw_data.dart';

int getScoreFromThrows(List<DiscThrow> throws) {
  return throws
      .fold(0, (prev, current) => prev + 1 + (current.penaltyStrokes ?? 0))
      .toInt();
}
