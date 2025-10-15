import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turbo_disc_golf/services/scorecard_ocr_service.dart';
import 'package:turbo_disc_golf/models/data/hole_metadata.dart';
import 'package:turbo_disc_golf/screens/voice_detail_input_screen.dart';
import 'package:turbo_disc_golf/services/ai_parsing_service.dart';
import 'package:turbo_disc_golf/locator.dart';

class ImportScoreScreen extends StatefulWidget {
  final bool testMode;
  final String? testVoiceDescription;

  const ImportScoreScreen({
    super.key,
    this.testMode = false,
    this.testVoiceDescription,
  });

  @override
  State<ImportScoreScreen> createState() => _ImportScoreScreenState();
}

class _ImportScoreScreenState extends State<ImportScoreScreen> {
  static const String _cacheKey = 'cached_hole_metadata';

  final ImagePicker _picker = ImagePicker();
  late final AiParsingService _aiParsingService;
  final TextEditingController _courseNameController = TextEditingController();

  String? _selectedImagePath;
  bool _isProcessing = false;
  List<ScoreCardHoleData> _extractedData = [];
  String? _errorMessage;
  bool _useCachedData = false;

  @override
  void initState() {
    super.initState();
    _aiParsingService = locator.get<AiParsingService>();

    // Auto-load test data if in test mode
    if (widget.testMode) {
      _loadTestData();
    }
  }

  Future<void> _loadTestData() async {
    try {
      // Load list of test images from assets
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = Map<String, dynamic>.from(
        const JsonDecoder().convert(manifestContent) as Map,
      );

      final testImages = manifestMap.keys
          .where((key) => key.startsWith('assets/test_scorecards/'))
          .where((key) => !key.endsWith('/') && !key.endsWith('.gitkeep'))
          .toList();

      if (testImages.isEmpty) {
        setState(() {
          _errorMessage = 'No test images found in assets/test_scorecards/';
          _courseNameController.text = 'Flings Giving Test Course';
        });
        return;
      }

      // Use the first test image
      final selectedImage = testImages.first;
      debugPrint('🧪 Test mode: Loading image $selectedImage');

      // Copy asset to temporary file for processing
      final byteData = await rootBundle.load(selectedImage);
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/temp_scorecard_test_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      setState(() {
        _selectedImagePath = tempFile.path;
        _courseNameController.text = 'Flings Giving Test Course';
      });

      // Process the image with Gemini
      await _processImage(tempFile.path);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load test image: $e';
        _courseNameController.text = 'Flings Giving Test Course';
      });
      debugPrint('❌ Error loading test data: $e');
    }
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
          _extractedData = [];
          _errorMessage = null;
        });
        await _processImage(image.path);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _pickTestImage() async {
    try {
      // Load list of test images from assets
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = Map<String, dynamic>.from(
        const JsonDecoder().convert(manifestContent) as Map,
      );

      final testImages = manifestMap.keys
          .where((key) => key.startsWith('assets/test_scorecards/'))
          .where((key) => !key.endsWith('/') && !key.endsWith('.gitkeep'))
          .toList();

      if (testImages.isEmpty) {
        setState(() {
          _errorMessage = 'No test images found in assets/test_scorecards/';
        });
        return;
      }

      // Show dialog to select test image
      if (!mounted) return;
      final selectedImage = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Test Image'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: testImages.length,
              itemBuilder: (context, index) {
                final imagePath = testImages[index];
                final imageName = imagePath.split('/').last;
                return ListTile(
                  title: Text(imageName),
                  onTap: () => Navigator.of(context).pop(imagePath),
                );
              },
            ),
          ),
        ),
      );

      if (selectedImage != null) {
        // Copy asset to temporary file for processing
        final byteData = await rootBundle.load(selectedImage);
        final tempDir = Directory.systemTemp;
        final tempFile = File(
          '${tempDir.path}/temp_scorecard_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await tempFile.writeAsBytes(byteData.buffer.asUint8List());

        setState(() {
          _selectedImagePath = tempFile.path;
          _extractedData = [];
          _errorMessage = null;
        });
        await _processImage(tempFile.path);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load test image: $e';
      });
    }
  }

  Future<void> _saveCachedHoleData(List<ScoreCardHoleData> holes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final holesJson = holes.map((hole) {
        return {
          'holeNumber': hole.holeNumber,
          'par': hole.par,
          'distance': hole.distance,
          'score': hole.score,
          'confidence': hole.confidence,
        };
      }).toList();
      await prefs.setString(_cacheKey, jsonEncode(holesJson));
      debugPrint('💾 Cached ${holes.length} holes to shared preferences');
    } catch (e) {
      debugPrint('❌ Failed to cache hole data: $e');
    }
  }

  Future<List<ScoreCardHoleData>?> _loadCachedHoleData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson == null) {
        debugPrint('📭 No cached hole data found');
        return null;
      }

      final List<dynamic> holesJson = jsonDecode(cachedJson);
      final holes = holesJson.map((json) {
        return ScoreCardHoleData(
          holeNumber: json['holeNumber'] as int,
          par: json['par'] as int?,
          distance: json['distance'] as int?,
          score: json['score'] as int?,
          confidence: (json['confidence'] as num).toDouble(),
        );
      }).toList();

      debugPrint('📦 Loaded ${holes.length} holes from cache');
      return holes;
    } catch (e) {
      debugPrint('❌ Failed to load cached hole data: $e');
      return null;
    }
  }

  List<ScoreCardHoleData> _convertToScoreCardHoleData(
    List<HoleMetadata> holeMetadata,
  ) {
    return holeMetadata.map((metadata) {
      return ScoreCardHoleData(
        holeNumber: metadata.holeNumber,
        par: metadata.par,
        distance: metadata.distanceFeet,
        score: metadata.score,
        confidence: 0.9, // Gemini typically has high confidence
      );
    }).toList();
  }

  Future<void> _processImage(String imagePath) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      List<ScoreCardHoleData> holes;

      // Check if we should use cached data
      if (_useCachedData) {
        debugPrint('🔄 Using cached hole data...');
        final cachedHoles = await _loadCachedHoleData();
        if (cachedHoles != null && cachedHoles.isNotEmpty) {
          holes = cachedHoles;
          debugPrint('✅ Using ${holes.length} cached holes');
        } else {
          debugPrint('⚠️ No cached data available, calling Gemini...');
          // Fall back to Gemini if no cache available
          final holeMetadata = await _aiParsingService.parseScorecard(
            imagePath: imagePath,
          );
          holes = _convertToScoreCardHoleData(holeMetadata);
          // Save to cache for next time
          await _saveCachedHoleData(holes);
        }
      } else {
        debugPrint('🖼️ Processing scorecard image with Gemini...');

        // Use Gemini to parse the scorecard image
        final holeMetadata = await _aiParsingService.parseScorecard(
          imagePath: imagePath,
        );

        // Log the parsed hole metadata
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint(
          '📊 GEMINI PARSED HOLE METADATA (${holeMetadata.length} holes)',
        );
        debugPrint('═══════════════════════════════════════════════════════');
        for (final hole in holeMetadata) {
          debugPrint(hole.toString());
        }
        debugPrint('═══════════════════════════════════════════════════════');

        holes = _convertToScoreCardHoleData(holeMetadata);

        // Save to cache
        await _saveCachedHoleData(holes);
      }

      setState(() {
        _extractedData = holes;
        _isProcessing = false;
        if (holes.isEmpty) {
          _errorMessage =
              'No scorecard data detected. Please try another image.';
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to process image: $e';
      });
      debugPrint('❌ Error processing scorecard image: $e');
    }
  }

  void _updateHoleData(int index, String field, String value) {
    final hole = _extractedData[index];
    final intValue = int.tryParse(value);

    setState(() {
      _extractedData[index] = ScoreCardHoleData(
        holeNumber: hole.holeNumber,
        par: field == 'par' ? intValue : hole.par,
        distance: field == 'distance' ? intValue : hole.distance,
        score: field == 'score' ? intValue : hole.score,
        confidence: hole.confidence,
      );
    });
  }

  void _continueToVoiceInput() {
    // Validate that we have valid data
    if (_extractedData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hole data from scorecard')),
      );
      return;
    }

    // Validate course name
    if (_courseNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a course name')),
      );
      return;
    }

    // Validate that all holes have required data
    for (final holeData in _extractedData) {
      if (holeData.par == null || holeData.score == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hole ${holeData.holeNumber} is missing par or score data',
            ),
          ),
        );
        return;
      }
    }

    // Convert ScoreCardHoleData to HoleMetadata
    final holeMetadata = _extractedData.map((hole) {
      return HoleMetadata(
        holeNumber: hole.holeNumber,
        par: hole.par!,
        distanceFeet: hole.distance,
        score: hole.score!,
      );
    }).toList();

    // Navigate to voice detail input screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VoiceDetailInputScreen(
          holeMetadata: holeMetadata,
          courseName: _courseNameController.text.trim(),
          testVoiceDescription: widget.testVoiceDescription,
        ),
      ),
    );
  }

  Widget _buildScoreSummaryCard() {
    // Calculate totals and scoring breakdown
    int totalPar = 0;
    int totalScore = 0;
    int eagles = 0;
    int birdies = 0;
    int pars = 0;
    int bogeys = 0;
    int doubleBogeyPlus = 0;

    for (final hole in _extractedData) {
      if (hole.par != null && hole.score != null) {
        totalPar += hole.par!;
        totalScore += hole.score!;
        final relativeToPar = hole.score! - hole.par!;

        if (relativeToPar <= -2) {
          eagles++;
        } else if (relativeToPar == -1) {
          birdies++;
        } else if (relativeToPar == 0) {
          pars++;
        } else if (relativeToPar == 1) {
          bogeys++;
        } else {
          doubleBogeyPlus++;
        }
      }
    }

    final scoreToPar = totalScore - totalPar;
    final scoreToParText = scoreToPar == 0
        ? 'E'
        : scoreToPar > 0
        ? '+$scoreToPar'
        : '$scoreToPar';

    return Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Total score display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      scoreToParText,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getScoreColorForRelativeToPar(scoreToPar),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalScore strokes',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFB0B0B0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF334155)),
            const SizedBox(height: 16),
            // Scoring breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (eagles > 0)
                  _buildScoreChip('Eagles', eagles, Colors.purple),
                if (birdies > 0)
                  _buildScoreChip('Birdies', birdies, Colors.blue),
                if (pars > 0) _buildScoreChip('Pars', pars, Colors.green),
                if (bogeys > 0)
                  _buildScoreChip('Bogeys', bogeys, Colors.orange),
                if (doubleBogeyPlus > 0)
                  _buildScoreChip('2B+', doubleBogeyPlus, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChip(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFFB0B0B0)),
        ),
      ],
    );
  }

  Color _getScoreColorForRelativeToPar(int scoreToPar) {
    if (scoreToPar <= -5) {
      return Colors.purple;
    } else if (scoreToPar < 0) {
      return Colors.blue;
    } else if (scoreToPar == 0) {
      return Colors.green;
    } else if (scoreToPar <= 5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Scorecard')),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Course name field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _courseNameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name *',
                  border: OutlineInputBorder(),
                  hintText: 'Enter course name',
                ),
              ),
            ),

            // Image selection buttons
            Padding(
              padding: const EdgeInsets.all(16).copyWith(top: 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickTestImage,
                    icon: const Icon(Icons.science),
                    label: const Text('Use Test Image'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Cache toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cached, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Use Cached Hole Data',
                        style: TextStyle(fontSize: 14),
                      ),
                      Switch(
                        value: _useCachedData,
                        onChanged: (value) {
                          setState(() {
                            _useCachedData = value;
                          });
                        },
                      ),
                      const SizedBox(width: 4),
                      const Tooltip(
                        message:
                            'Load from cache instead of calling Gemini (faster)',
                        child: Icon(Icons.info_outline, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Selected image preview
            if (_selectedImagePath != null)
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_selectedImagePath!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

            // Processing indicator
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Processing image...'),
                  ],
                ),
              ),

            // Error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),

            // Extracted data
            if (_extractedData.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Extracted Data (${_extractedData.length} holes)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildScoreSummaryCard(),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _continueToVoiceInput,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continue with Voice'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00F5D4),
                        foregroundColor: const Color(0xFF0A0E17),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 100,
                ),
                itemCount: _extractedData.length,
                itemBuilder: (context, index) {
                  final hole = _extractedData[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Hole ${hole.holeNumber}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: hole.confidence > 0.7
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : hole.confidence > 0.4
                                      ? Colors.orange.withValues(alpha: 0.2)
                                      : Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${(hole.confidence * 100).toStringAsFixed(0)}% confidence',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Par',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  keyboardType: TextInputType.number,
                                  controller: TextEditingController(
                                    text: hole.par?.toString() ?? '',
                                  ),
                                  onChanged: (value) =>
                                      _updateHoleData(index, 'par', value),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Distance (ft)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  keyboardType: TextInputType.number,
                                  controller: TextEditingController(
                                    text: hole.distance?.toString() ?? '',
                                  ),
                                  onChanged: (value) =>
                                      _updateHoleData(index, 'distance', value),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Score',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  keyboardType: TextInputType.number,
                                  controller: TextEditingController(
                                    text: hole.score?.toString() ?? '',
                                  ),
                                  onChanged: (value) =>
                                      _updateHoleData(index, 'score', value),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
