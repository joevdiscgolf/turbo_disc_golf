import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';
import 'package:flutter/services.dart';

class TestImageParsingScreen extends StatefulWidget {
  const TestImageParsingScreen({super.key});

  @override
  State<TestImageParsingScreen> createState() => _TestImageParsingScreenState();
}

class _TestImageParsingScreenState extends State<TestImageParsingScreen> {
  final AiParsingService _aiParsingService = locator.get<AiParsingService>();
  final String _testImagePath =
      'assets/test_scorecards/flingsgiving_round_2.jpeg';

  bool _isLoading = false;
  List<HoleMetadata>? _parsedHoles;
  String? _errorMessage;

  Future<void> _parseScorecard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _parsedHoles = null;
    });

    try {
      debugPrint('==========================================');
      debugPrint('🖼️  PARSING SCORECARD IMAGE');
      debugPrint('==========================================');
      debugPrint('Image path: $_testImagePath');

      final holes = await _aiParsingService.parseScorecard(
        imagePath: _testImagePath,
      );

      debugPrint('✅ Parsed ${holes.length} holes');
      for (final hole in holes) {
        debugPrint('  ${hole.toString()}');
      }
      debugPrint('==========================================');

      setState(() {
        _parsedHoles = holes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error parsing scorecard: $e');
      setState(() {
        _errorMessage = 'Error parsing scorecard: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Test Image Parsing',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Test image preview
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: Colors.grey[900],
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Test Scorecard',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Image.asset(_testImagePath, fit: BoxFit.contain),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Parse button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _parseScorecard,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image_search),
                label: Text(_isLoading ? 'Parsing...' : 'Parse Scorecard'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 16),

              // Error message
              if (_errorMessage != null)
                Card(
                  color: Colors.red.withValues(alpha: 0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Parsed holes section
              if (_parsedHoles != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Parsed Holes',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_parsedHoles!.length} holes',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_parsedHoles!.isEmpty)
                          const Text(
                            'No holes found in image',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          )
                        else
                          ..._parsedHoles!.map((hole) => _buildHoleCard(hole)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoleCard(HoleMetadata hole) {
    final relativeToPar = hole.score - hole.par;
    final relativeToParText = relativeToPar == 0
        ? 'E'
        : relativeToPar > 0
        ? '+$relativeToPar'
        : '$relativeToPar';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Hole number
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${hole.holeNumber}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Hole details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Par ${hole.par}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hole.distanceFeet != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${hole.distanceFeet}ft',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getScoreColor(relativeToPar),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '${hole.score}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    relativeToParText,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int relativeToPar) {
    if (relativeToPar <= -2) {
      return Colors.purple; // Eagle or better
    } else if (relativeToPar == -1) {
      return Colors.blue; // Birdie
    } else if (relativeToPar == 0) {
      return Colors.green; // Par
    } else if (relativeToPar == 1) {
      return Colors.orange; // Bogey
    } else {
      return Colors.red; // Double bogey or worse
    }
  }
}
