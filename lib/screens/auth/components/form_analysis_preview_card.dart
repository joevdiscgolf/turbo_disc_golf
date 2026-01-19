import 'package:flutter/material.dart';

class FormAnalysisPreviewCard extends StatelessWidget {
  const FormAnalysisPreviewCard({super.key});

  static const Color accentColor = Color(0xFF2ECC71);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.videocam,
                color: accentColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Form Analysis',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Compare your form to the pros',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        _buildComparisonIndicator(),
      ],
    );
  }

  Widget _buildComparisonIndicator() {
    return Row(
      children: [
        _buildFormBox('You', false),
        const SizedBox(width: 10),
        Icon(
          Icons.compare_arrows,
          color: accentColor,
          size: 20,
        ),
        const SizedBox(width: 10),
        _buildFormBox('Pro', true),
      ],
    );
  }

  Widget _buildFormBox(String label, bool isPro) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isPro
              ? accentColor.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPro
                ? accentColor.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isPro ? Icons.star : Icons.person,
              color: isPro
                  ? accentColor
                  : Colors.white.withValues(alpha: 0.6),
              size: 18,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
