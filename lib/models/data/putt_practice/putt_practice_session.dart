import 'package:json_annotation/json_annotation.dart';

import 'package:turbo_disc_golf/models/data/putt_practice/basket_calibration.dart';
import 'package:turbo_disc_golf/models/data/putt_practice/detected_putt_attempt.dart';
import 'package:turbo_disc_golf/models/data/putt_practice/miss_direction.dart';
import 'package:turbo_disc_golf/utils/constants/putting_constants.dart';

part 'putt_practice_session.g.dart';

/// Status of a putt practice session
enum PuttPracticeSessionStatus {
  /// Session is being set up (calibrating basket)
  calibrating,

  /// Session is active and tracking putts
  active,

  /// Session is paused
  paused,

  /// Session has been completed
  completed,
}

/// A complete putt practice session with all tracked attempts
@JsonSerializable(anyMap: true, explicitToJson: true)
class PuttPracticeSession {
  /// Unique identifier for this session
  final String id;

  /// User ID who owns this session
  final String uid;

  /// Session creation timestamp
  final DateTime createdAt;

  /// Session end timestamp (null if still active)
  final DateTime? endedAt;

  /// Current session status
  final PuttPracticeSessionStatus status;

  /// Basket calibration data
  final BasketCalibration? calibration;

  /// List of all detected putt attempts
  final List<DetectedPuttAttempt> attempts;

  /// Estimated distance range being practiced (e.g., "C1", "C1X", "C2")
  final String? distanceRange;

  /// Optional notes about the session
  final String? notes;

  PuttPracticeSession({
    required this.id,
    required this.uid,
    required this.createdAt,
    this.endedAt,
    required this.status,
    this.calibration,
    required this.attempts,
    this.distanceRange,
    this.notes,
  });

  /// Total number of putt attempts
  int get totalAttempts => attempts.length;

  /// Number of made putts
  int get makes => attempts.where((a) => a.made).length;

  /// Number of missed putts
  int get misses => attempts.where((a) => !a.made).length;

  /// Make percentage (0-100)
  double get makePercentage =>
      totalAttempts > 0 ? (makes / totalAttempts) * 100 : 0.0;

  /// Session duration
  Duration get duration {
    final DateTime end = endedAt ?? DateTime.now();
    return end.difference(createdAt);
  }

  /// Count of misses by direction
  Map<MissDirection, int> get missesByDirection {
    final Map<MissDirection, int> counts = {};
    for (final MissDirection dir in MissDirection.values) {
      counts[dir] = 0;
    }
    for (final DetectedPuttAttempt attempt in attempts) {
      if (!attempt.made && attempt.missDirection != null) {
        counts[attempt.missDirection!] = (counts[attempt.missDirection!] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Most common miss direction
  MissDirection? get mostCommonMissDirection {
    final Map<MissDirection, int> counts = missesByDirection;
    MissDirection? mostCommon;
    int maxCount = 0;
    for (final MapEntry<MissDirection, int> entry in counts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommon = entry.key;
      }
    }
    return mostCommon;
  }

  /// C1 stats (0-33 feet)
  (int makes, int attempts) get c1Stats {
    final List<DetectedPuttAttempt> c1Attempts = attempts.where((a) {
      final double? dist = a.estimatedDistanceFeet;
      return dist != null && dist >= c1MinDistance && dist < c1MaxDistance;
    }).toList();
    return (
      c1Attempts.where((a) => a.made).length,
      c1Attempts.length,
    );
  }

  /// C1X stats (11-33 feet)
  (int makes, int attempts) get c1xStats {
    final List<DetectedPuttAttempt> c1xAttempts = attempts.where((a) {
      final double? dist = a.estimatedDistanceFeet;
      return dist != null && dist >= c1xMinDistance && dist < c1xMaxDistance;
    }).toList();
    return (
      c1xAttempts.where((a) => a.made).length,
      c1xAttempts.length,
    );
  }

  /// C2 stats (33-66 feet)
  (int makes, int attempts) get c2Stats {
    final List<DetectedPuttAttempt> c2Attempts = attempts.where((a) {
      final double? dist = a.estimatedDistanceFeet;
      return dist != null && dist >= c2MinDistance && dist < c2MaxDistance;
    }).toList();
    return (
      c2Attempts.where((a) => a.made).length,
      c2Attempts.length,
    );
  }

  /// Average confidence of detections
  double get averageConfidence {
    if (attempts.isEmpty) return 0.0;
    return attempts.map((a) => a.confidence).reduce((a, b) => a + b) /
        attempts.length;
  }

  /// Create a copy with updated fields
  PuttPracticeSession copyWith({
    String? id,
    String? uid,
    DateTime? createdAt,
    DateTime? endedAt,
    PuttPracticeSessionStatus? status,
    BasketCalibration? calibration,
    List<DetectedPuttAttempt>? attempts,
    String? distanceRange,
    String? notes,
  }) {
    return PuttPracticeSession(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      calibration: calibration ?? this.calibration,
      attempts: attempts ?? this.attempts,
      distanceRange: distanceRange ?? this.distanceRange,
      notes: notes ?? this.notes,
    );
  }

  /// Add a new putt attempt
  PuttPracticeSession addAttempt(DetectedPuttAttempt attempt) {
    return copyWith(attempts: [...attempts, attempt]);
  }

  /// End the session
  PuttPracticeSession end() {
    return copyWith(
      status: PuttPracticeSessionStatus.completed,
      endedAt: DateTime.now(),
    );
  }

  factory PuttPracticeSession.fromJson(Map<String, dynamic> json) =>
      _$PuttPracticeSessionFromJson(json);

  Map<String, dynamic> toJson() => _$PuttPracticeSessionToJson(this);
}
