import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

/// Analyzes hole description quality based on parsed throw data.
/// Checks for missing disc names and throw techniques.
class DescriptionQualityAnalyzer {
  /// Analyzes a round and returns a quality report.
  static DescriptionQualityReport analyzeRound(PotentialDGRound round) {
    final List<HoleQualityIssue> issues = [];
    final List<ThrowQualityIssue> allThrowIssues = [];
    int totalThrows = 0;
    int throwsMissingDisc = 0;
    int throwsMissingTechnique = 0;

    for (final hole in round.holes ?? []) {
      final List<String> holeMissingFields = [];
      final List<ThrowQualityIssue> holeThrowIssues = [];
      int holeThrowsMissingDisc = 0;
      int holeThrowsMissingTechnique = 0;
      int throwIndex = 0;

      for (final throw_ in hole.throws ?? []) {
        totalThrows++;
        throwIndex++;

        // Skip disc and technique checks for putts - they don't typically need these
        final bool isPutt = throw_.purpose == ThrowPurpose.putt;

        final bool missingDisc =
            !isPutt && throw_.discName == null && throw_.disc == null;
        final bool missingTechnique = !isPutt && throw_.technique == null;

        // Check for missing disc name
        if (missingDisc) {
          throwsMissingDisc++;
          holeThrowsMissingDisc++;
        }

        // Check for missing technique
        if (missingTechnique) {
          throwsMissingTechnique++;
          holeThrowsMissingTechnique++;
        }

        // Track individual throw issues
        if (missingDisc || missingTechnique) {
          final ThrowQualityIssue throwIssue = ThrowQualityIssue(
            holeNumber: hole.number ?? 0,
            throwNumber: throwIndex,
            missingDisc: missingDisc,
            missingTechnique: missingTechnique,
          );
          holeThrowIssues.add(throwIssue);
          allThrowIssues.add(throwIssue);
        }
      }

      // Add issue if this hole has any missing fields
      if (holeThrowsMissingDisc > 0) {
        holeMissingFields.add('disc');
      }
      if (holeThrowsMissingTechnique > 0) {
        holeMissingFields.add('technique');
      }

      if (holeMissingFields.isNotEmpty) {
        issues.add(HoleQualityIssue(
          holeNumber: hole.number ?? 0,
          missingFields: holeMissingFields,
          throwsMissingDisc: holeThrowsMissingDisc,
          throwsMissingTechnique: holeThrowsMissingTechnique,
          throwIssues: holeThrowIssues,
        ));
      }
    }

    return DescriptionQualityReport(
      totalThrows: totalThrows,
      throwsMissingDisc: throwsMissingDisc,
      throwsMissingTechnique: throwsMissingTechnique,
      holeIssues: issues,
      allThrowIssues: allThrowIssues,
    );
  }

  /// Analyzes a finalized DGRound and returns a quality report.
  static DescriptionQualityReport analyzeFinalizedRound(DGRound round) {
    final List<HoleQualityIssue> issues = [];
    final List<ThrowQualityIssue> allThrowIssues = [];
    int totalThrows = 0;
    int throwsMissingDisc = 0;
    int throwsMissingTechnique = 0;

    for (final hole in round.holes) {
      final List<String> holeMissingFields = [];
      final List<ThrowQualityIssue> holeThrowIssues = [];
      int holeThrowsMissingDisc = 0;
      int holeThrowsMissingTechnique = 0;
      int throwIndex = 0;

      for (final throw_ in hole.throws) {
        totalThrows++;
        throwIndex++;

        // Skip disc and technique checks for putts - they don't typically need these
        final bool isPutt = throw_.purpose == ThrowPurpose.putt;

        final bool missingDisc =
            !isPutt && throw_.discName == null && throw_.disc == null;
        final bool missingTechnique = !isPutt && throw_.technique == null;

        // Check for missing disc name
        if (missingDisc) {
          throwsMissingDisc++;
          holeThrowsMissingDisc++;
        }

        // Check for missing technique
        if (missingTechnique) {
          throwsMissingTechnique++;
          holeThrowsMissingTechnique++;
        }

        // Track individual throw issues
        if (missingDisc || missingTechnique) {
          final ThrowQualityIssue throwIssue = ThrowQualityIssue(
            holeNumber: hole.number,
            throwNumber: throwIndex,
            missingDisc: missingDisc,
            missingTechnique: missingTechnique,
          );
          holeThrowIssues.add(throwIssue);
          allThrowIssues.add(throwIssue);
        }
      }

      // Add issue if this hole has any missing fields
      if (holeThrowsMissingDisc > 0) {
        holeMissingFields.add('disc');
      }
      if (holeThrowsMissingTechnique > 0) {
        holeMissingFields.add('technique');
      }

      if (holeMissingFields.isNotEmpty) {
        issues.add(HoleQualityIssue(
          holeNumber: hole.number,
          missingFields: holeMissingFields,
          throwsMissingDisc: holeThrowsMissingDisc,
          throwsMissingTechnique: holeThrowsMissingTechnique,
          throwIssues: holeThrowIssues,
        ));
      }
    }

    return DescriptionQualityReport(
      totalThrows: totalThrows,
      throwsMissingDisc: throwsMissingDisc,
      throwsMissingTechnique: throwsMissingTechnique,
      holeIssues: issues,
      allThrowIssues: allThrowIssues,
    );
  }
}

/// Report containing quality analysis results for a round.
class DescriptionQualityReport {
  const DescriptionQualityReport({
    required this.totalThrows,
    required this.throwsMissingDisc,
    required this.throwsMissingTechnique,
    required this.holeIssues,
    required this.allThrowIssues,
  });

  final int totalThrows;
  final int throwsMissingDisc;
  final int throwsMissingTechnique;
  final List<HoleQualityIssue> holeIssues;
  final List<ThrowQualityIssue> allThrowIssues;

  /// Returns true if there are any quality issues.
  bool get hasIssues => holeIssues.isNotEmpty;

  /// Returns the total number of throws missing any info.
  int get totalThrowsMissingInfo {
    // Count unique throws - a throw might be missing both disc and technique
    // but we want to count it once for the summary
    int count = 0;
    for (final issue in holeIssues) {
      // Use the max of disc or technique missing per hole as an approximation
      count += issue.throwsMissingDisc > issue.throwsMissingTechnique
          ? issue.throwsMissingDisc
          : issue.throwsMissingTechnique;
    }
    return count;
  }

  /// Returns a summary text for display.
  String get summaryText {
    final List<String> parts = [];
    if (throwsMissingDisc > 0) {
      parts.add('$throwsMissingDisc ${throwsMissingDisc == 1 ? 'throw' : 'throws'} missing disc');
    }
    if (throwsMissingTechnique > 0) {
      parts.add('$throwsMissingTechnique ${throwsMissingTechnique == 1 ? 'throw' : 'throws'} missing technique');
    }
    return parts.join(' • ');
  }

  /// Returns a short summary for the collapsed card state.
  String get shortSummary {
    final int total = totalThrowsMissingInfo;
    if (total == 0) return '';
    return '$total ${total == 1 ? 'throw' : 'throws'} missing detail';
  }
}

/// Quality issue for a specific throw.
class ThrowQualityIssue {
  const ThrowQualityIssue({
    required this.holeNumber,
    required this.throwNumber,
    required this.missingDisc,
    required this.missingTechnique,
  });

  final int holeNumber;
  final int throwNumber; // 1-based
  final bool missingDisc;
  final bool missingTechnique;

  /// Returns what's missing for this throw.
  String get missingText {
    final List<String> parts = [];
    if (missingDisc) parts.add('disc');
    if (missingTechnique) parts.add('technique');
    return parts.join(', ');
  }
}

/// Quality issue for a specific hole.
class HoleQualityIssue {
  const HoleQualityIssue({
    required this.holeNumber,
    required this.missingFields,
    required this.throwsMissingDisc,
    required this.throwsMissingTechnique,
    required this.throwIssues,
  });

  final int holeNumber;
  final List<String> missingFields; // ['disc', 'technique']
  final int throwsMissingDisc;
  final int throwsMissingTechnique;
  final List<ThrowQualityIssue> throwIssues;

  /// Returns a display string for this hole's issues.
  String get displayText {
    final List<String> parts = [];
    if (missingFields.contains('disc')) {
      parts.add('disc');
    }
    if (missingFields.contains('technique')) {
      parts.add('technique');
    }
    return 'Hole $holeNumber: missing ${parts.join(', ')}';
  }
}
