import 'package:flutter/material.dart';

/// Emphasized card for "Biggest Opportunity to Improve" section
///
/// Visually distinctive with shadow, border, and emphasis badge
/// to draw attention to the single highest-impact area for improvement.
class OpportunityHighlight extends StatelessWidget {
  const OpportunityHighlight({
    super.key,
    required this.statWidget,
    required this.explanation,
    this.onTap,
  });

  final Widget statWidget;
  final String explanation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFA726).withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA726).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFocusBadge(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                statWidget,
                const SizedBox(height: 12),
                _buildExplanation(),
                if (onTap != null) ...[
                  const SizedBox(height: 12),
                  _buildViewDetailsButton(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFA726),
            const Color(0xFFFFA726).withValues(alpha: 0.7),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            'FOCUS HERE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanation() {
    return Text(
      explanation,
      style: const TextStyle(
        fontSize: 16,
        height: 1.6,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildViewDetailsButton() {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'View in Stats',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFFA726),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_forward,
            size: 16,
            color: const Color(0xFFFFA726),
          ),
        ],
      ),
    );
  }
}
