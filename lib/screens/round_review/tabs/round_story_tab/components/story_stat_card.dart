import 'package:flutter/material.dart';

/// Wrapper for stat widgets in story tab with explanation text
///
/// Displays a stat widget (like DrivingStatsCard or CircularStatIndicator)
/// followed by disc golf coaching explanation text.
///
/// Tappable to navigate to Stats tab for more details.
class StoryStatCard extends StatelessWidget {
  const StoryStatCard({
    super.key,
    required this.statWidget,
    this.explanation,
    this.onTap,
  });

  final Widget statWidget;
  final String? explanation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              statWidget,
              if (explanation != null && explanation!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildExplanation(context),
              ],
              if (onTap != null) ...[
                const SizedBox(height: 12),
                _buildViewDetailsButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplanation(BuildContext context) {
    return Text(
      explanation!,
      style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
    );
  }

  Widget _buildViewDetailsButton() {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'View in Stats',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF137e66),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward, size: 16, color: const Color(0xFF137e66)),
        ],
      ),
    );
  }
}
