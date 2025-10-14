import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScoreCardHoleData {
  final int holeNumber;
  final int? par;
  final int? distance;
  final int? score;
  final double confidence; // 0.0 to 1.0

  ScoreCardHoleData({
    required this.holeNumber,
    this.par,
    this.distance,
    this.score,
    this.confidence = 0.5,
  });

  Map<String, dynamic> toJson() {
    return {
      'holeNumber': holeNumber,
      'par': par,
      'distance': distance,
      'score': score,
      'confidence': confidence,
    };
  }
}

class ScoreCardOCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Process an image and extract scorecard data
  Future<List<ScoreCardHoleData>> processScoreCard(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Extract all text from the image
      final extractedText = recognizedText.text;

      // Debug: Print raw OCR text
      debugPrint('\n========== RAW OCR TEXT ==========');
      debugPrint(extractedText);
      debugPrint('==================================\n');

      // Try to parse as UDisc format first, then PDGA format
      List<ScoreCardHoleData> holes = _parseUDiscFormat(extractedText);
      if (holes.isEmpty) {
        holes = _parsePDGAFormat(extractedText);
      }

      // Debug: Print extracted data in formatted table
      debugPrint('\n========== OCR EXTRACTION RESULTS ==========');
      debugPrint('Total holes extracted: ${holes.length}\n');
      debugPrint('┌──────┬─────┬──────────┬───────┬────────────┐');
      debugPrint('│ Hole │ Par │ Distance │ Score │ Confidence │');
      debugPrint('├──────┼─────┼──────────┼───────┼────────────┤');
      for (final hole in holes) {
        final holeStr = hole.holeNumber.toString().padLeft(4);
        final parStr = (hole.par?.toString() ?? 'N/A').padLeft(3);
        final distStr = (hole.distance?.toString() ?? 'N/A').padLeft(8);
        final scoreStr = (hole.score?.toString() ?? 'N/A').padLeft(5);
        final confStr = '${(hole.confidence * 100).toStringAsFixed(0)}%'.padLeft(10);
        debugPrint('│ $holeStr │ $parStr │ $distStr │ $scoreStr │ $confStr │');
      }
      debugPrint('└──────┴─────┴──────────┴───────┴────────────┘');
      debugPrint('==========================================\n');

      return holes;
    } catch (e) {
      debugPrint('Error processing scorecard: $e');
      return [];
    }
  }

  /// Parse UDisc scorecard format
  List<ScoreCardHoleData> _parseUDiscFormat(String text) {
    final holes = <ScoreCardHoleData>[];
    final lines = text.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    // Strategy 1: Try to parse as sequential groups of 4 numbers
    // Format: hole, distance, par, score
    final numbers = <int>[];
    for (final line in lines) {
      // Clean up the line (remove parentheses, etc.)
      final cleanLine = line.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanLine.isNotEmpty) {
        final num = int.tryParse(cleanLine);
        if (num != null) {
          numbers.add(num);
        }
      }
    }

    // Debug: Print extracted numbers
    debugPrint('Extracted numbers: $numbers');
    debugPrint('Total numbers: ${numbers.length}');

    // Try to parse in groups of 4 with LENIENT validation
    if (numbers.length >= 4) {
      int i = 0;
      final parsedHoles = <int, ScoreCardHoleData>{};

      while (i + 3 < numbers.length) {
        final holeNum = numbers[i];
        final distance = numbers[i + 1];
        final par = numbers[i + 2];
        final score = numbers[i + 3];

        debugPrint('Trying position $i: hole=$holeNum, dist=$distance, par=$par, score=$score');

        // More lenient validation
        final isValidHole = holeNum >= 1 && holeNum <= 18;
        final isValidPar = par >= 3 && par <= 5;
        final isValidDistance = distance >= 50 && distance <= 1500; // More lenient range
        final isValidScore = score >= 1 && score <= 15; // Reasonable score range

        // Count how many validations passed
        int validCount = 0;
        if (isValidHole) validCount++;
        if (isValidPar) validCount++;
        if (isValidDistance) validCount++;
        if (isValidScore) validCount++;

        debugPrint('  Valid: hole=$isValidHole, par=$isValidPar, dist=$isValidDistance, score=$isValidScore ($validCount/4)');

        // Accept if at least 3 out of 4 validations pass (and hole number is valid)
        if (isValidHole && validCount >= 3) {
          debugPrint('  ✓ ACCEPTED! Adding hole $holeNum');
          parsedHoles[holeNum] = ScoreCardHoleData(
            holeNumber: holeNum,
            par: isValidPar ? par : null,
            distance: isValidDistance ? distance : null,
            score: isValidScore ? score : null,
            confidence: validCount / 4.0,
          );
          i += 4; // Move to next group
        } else {
          debugPrint('  ✗ Rejected (validCount=$validCount or invalid hole)');
          i++; // Try next position if pattern doesn't match
        }
      }

      // Convert to sorted list
      if (parsedHoles.isNotEmpty) {
        debugPrint('Successfully parsed ${parsedHoles.length} holes: ${parsedHoles.keys.toList()..sort()}');
        final sortedHoles = parsedHoles.keys.toList()..sort();
        for (final holeNum in sortedHoles) {
          holes.add(parsedHoles[holeNum]!);
        }
      }
    }

    // Strategy 2: If we're still missing holes, try to find them by hole number
    if (holes.length < 18) {
      debugPrint('Only found ${holes.length} holes, trying fallback strategy...');
      final foundHoles = holes.map((h) => h.holeNumber).toSet();

      // Look for missing hole numbers in the raw numbers
      for (int missingHole = 1; missingHole <= 18; missingHole++) {
        if (foundHoles.contains(missingHole)) continue;

        // Find this hole number in the numbers array
        for (int i = 0; i < numbers.length - 1; i++) {
          if (numbers[i] == missingHole) {
            debugPrint('Found missing hole $missingHole at position $i');

            // Try to extract data around this hole number
            int? distance;
            int? par;
            int? score;

            // Look ahead for likely distance (large number)
            if (i + 1 < numbers.length && numbers[i + 1] >= 50 && numbers[i + 1] <= 1500) {
              distance = numbers[i + 1];
            }

            // Look ahead for likely par (3-5)
            if (i + 2 < numbers.length && numbers[i + 2] >= 3 && numbers[i + 2] <= 5) {
              par = numbers[i + 2];
            }

            // Look ahead for likely score (1-15)
            if (i + 3 < numbers.length && numbers[i + 3] >= 1 && numbers[i + 3] <= 15) {
              score = numbers[i + 3];
            }

            // Add hole even with partial data
            if (distance != null || par != null || score != null) {
              debugPrint('  Adding hole $missingHole with partial data: dist=$distance, par=$par, score=$score');
              holes.add(ScoreCardHoleData(
                holeNumber: missingHole,
                par: par,
                distance: distance,
                score: score,
                confidence: 0.6,
              ));
            }
            break;
          }
        }
      }

      // Re-sort holes
      holes.sort((a, b) => a.holeNumber.compareTo(b.holeNumber));
    }

    return holes;
  }

  /// Parse PDGA.com scorecard format
  List<ScoreCardHoleData> _parsePDGAFormat(String text) {
    final holes = <ScoreCardHoleData>[];
    final lines = text.split('\n');

    // PDGA format often has tables with columns
    // Try to find header row and data rows

    // Look for table-like structure
    for (int holeNum = 1; holeNum <= 18; holeNum++) {
      int? par;
      int? distance;
      int? score;
      double confidence = 0.0;

      // Search for hole number and extract row data
      for (final line in lines) {
        // Check if this line contains the hole number
        if (RegExp(r'\b$holeNum\b').hasMatch(line)) {
          // Extract all numbers from this line
          final numbers = RegExp(r'\b\d+\b')
              .allMatches(line)
              .map((m) => int.tryParse(m.group(0)!))
              .where((n) => n != null)
              .cast<int>()
              .toList();

          if (numbers.isNotEmpty) {
            // First number should be hole number
            if (numbers[0] == holeNum) {
              confidence += 0.3;

              // Try to identify par (3-5)
              for (final num in numbers.skip(1)) {
                if (num >= 3 && num <= 5 && par == null) {
                  par = num;
                  confidence += 0.3;
                  break;
                }
              }

              // Try to identify distance (200-800)
              for (final num in numbers.skip(1)) {
                if (num >= 200 && num <= 1000 && distance == null) {
                  distance = num;
                  confidence += 0.3;
                  break;
                }
              }

              // Score is usually the last number
              if (numbers.length > 1) {
                final potentialScore = numbers.last;
                if (potentialScore != holeNum &&
                    potentialScore != par &&
                    potentialScore != distance) {
                  score = potentialScore;
                  confidence += 0.4;
                }
              }

              break;
            }
          }
        }
      }

      // Add hole if we found at least some data
      if (par != null || distance != null || score != null) {
        holes.add(
          ScoreCardHoleData(
            holeNumber: holeNum,
            par: par,
            distance: distance,
            score: score,
            confidence: confidence,
          ),
        );
      }
    }

    return holes;
  }

  /// Clean up resources
  void dispose() {
    _textRecognizer.close();
  }
}
