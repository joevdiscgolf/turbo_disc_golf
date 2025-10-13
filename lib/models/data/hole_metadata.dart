/// Represents pre-parsed hole metadata extracted from a scorecard image.
/// Used for Image-First parsing mode where scorecard provides hole info
/// and voice transcript provides throw details.
class HoleMetadata {
  final int holeNumber;
  final int par;
  final int? distanceFeet;
  final int score;

  HoleMetadata({
    required this.holeNumber,
    required this.par,
    this.distanceFeet,
    required this.score,
  });

  Map<String, dynamic> toJson() {
    return {
      'holeNumber': holeNumber,
      'par': par,
      'distanceFeet': distanceFeet,
      'score': score,
    };
  }

  factory HoleMetadata.fromJson(Map<String, dynamic> json) {
    return HoleMetadata(
      holeNumber: json['holeNumber'] as int,
      par: json['par'] as int,
      distanceFeet: json['distanceFeet'] as int?,
      score: json['score'] as int,
    );
  }

  HoleMetadata copyWith({
    int? holeNumber,
    int? par,
    int? distanceFeet,
    int? score,
  }) {
    return HoleMetadata(
      holeNumber: holeNumber ?? this.holeNumber,
      par: par ?? this.par,
      distanceFeet: distanceFeet ?? this.distanceFeet,
      score: score ?? this.score,
    );
  }

  @override
  String toString() {
    return 'HoleMetadata(hole: $holeNumber, par: $par, distance: ${distanceFeet ?? "N/A"}ft, score: $score)';
  }
}
