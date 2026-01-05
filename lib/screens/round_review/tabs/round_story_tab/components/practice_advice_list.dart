import 'package:flutter/material.dart';

/// Bulleted list of actionable practice advice
///
/// Displays concrete, time-bounded, disc-golf realistic advice
/// without stats. Each item uses a themed icon and clear typography.
///
/// Examples:
/// - "Work on driving accuracy from 300-350 feet"
/// - "Practice lag putting from 40-50 feet to reduce three-putts"
class PracticeAdviceList extends StatelessWidget {
  const PracticeAdviceList({
    super.key,
    required this.advice,
  });

  final List<String> advice;

  @override
  Widget build(BuildContext context) {
    if (advice.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: advice.asMap().entries.map((entry) {
            return _buildAdviceItem(entry.value, entry.key);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAdviceItem(String adviceText, int index) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: index < advice.length - 1 ? 12 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              size: 16,
              color: const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              adviceText,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
