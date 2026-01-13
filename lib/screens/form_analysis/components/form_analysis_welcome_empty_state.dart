import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/components/buttons/primary_button.dart';

class FormAnalysisWelcomeEmptyState extends StatelessWidget {
  const FormAnalysisWelcomeEmptyState({
    super.key,
    required this.onStartAnalysis,
  });

  final VoidCallback onStartAnalysis;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Card(
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 8),
                  Text(
                    'Improve your throw with AI-powered analysis',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey[300], height: 1),
                  const SizedBox(height: 24),
                  _buildFeatureRow('🎥', 'Record or upload your throw'),
                  const SizedBox(height: 16),
                  _buildFeatureRow('🤖', 'AI-powered form analysis'),
                  const SizedBox(height: 16),
                  _buildFeatureRow('💪', 'Get personalized coaching tips'),
                  const SizedBox(height: 16),
                  _buildFeatureRow('📊', 'Track progress over time'),
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey[300], height: 1),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    width: double.infinity,
                    height: 52,
                    label: 'Analyze Your First Video',
                    gradientBackground: const [
                      Color(0xFF137e66),
                      Color(0xFF1a9f7f),
                    ],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    onPressed: onStartAnalysis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.slow_motion_video,
            color: Color(0xFF1565C0),
            size: 24,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Form Coach',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
