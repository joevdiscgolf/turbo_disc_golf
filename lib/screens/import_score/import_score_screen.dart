import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_review/round_review_screen.dart';
import 'package:turbo_disc_golf/services/scorecard_ocr_service.dart';

class ImportScoreScreen extends StatefulWidget {
  const ImportScoreScreen({super.key});

  @override
  State<ImportScoreScreen> createState() => _ImportScoreScreenState();
}

class _ImportScoreScreenState extends State<ImportScoreScreen> {
  final ImagePicker _picker = ImagePicker();
  final ScoreCardOCRService _ocrService = ScoreCardOCRService();
  final TextEditingController _courseNameController = TextEditingController();

  String? _selectedImagePath;
  bool _isProcessing = false;
  List<ScoreCardHoleData> _extractedData = [];
  String? _errorMessage;

  @override
  void dispose() {
    _ocrService.dispose();
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

  Future<void> _processImage(String imagePath) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final holes = await _ocrService.processScoreCard(imagePath);
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

  void _confirmAndCreateRound() {
    // Validate that we have valid data
    if (_extractedData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hole data to create round')),
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

    // Convert extracted data to DGHole objects
    final holes = <DGHole>[];
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

      // Create placeholder throws based on score
      // We don't have detailed throw data from the screenshot,
      // so we create simple throws
      final throws = <DiscThrow>[];
      for (int i = 0; i < holeData.score!; i++) {
        throws.add(
          DiscThrow(
            index: i,
            notes: 'Imported from screenshot',
            parseConfidence: holeData.confidence,
          ),
        );
      }

      holes.add(
        DGHole(
          number: holeData.holeNumber,
          par: holeData.par!,
          feet: holeData.distance,
          throws: throws,
        ),
      );
    }

    // Create the round
    final round = DGRound(
      id: const Uuid().v4(),
      courseName: _courseNameController.text.trim(),
      holes: holes,
    );

    // Navigate to round review screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            RoundReviewScreen(round: round, showStoryOnLoad: false),
      ),
    );
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Extracted Data (${_extractedData.length} holes)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: _confirmAndCreateRound,
                      child: const Text('Confirm'),
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
