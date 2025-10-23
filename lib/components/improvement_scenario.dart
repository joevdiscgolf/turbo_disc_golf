import 'package:turbo_disc_golf/models/data/hole_data.dart';

class ImprovementScenario {
  final String title;
  final String description;
  final int strokesSaved;
  final String category;
  final String emoji;
  final List<DGHole> affectedHoles;
  final String Function(DGHole) getImprovementLabel;

  const ImprovementScenario({
    required this.title,
    required this.description,
    required this.strokesSaved,
    required this.category,
    required this.emoji,
    required this.affectedHoles,
    required this.getImprovementLabel,
  });

  int get targetScore => strokesSaved;
}
