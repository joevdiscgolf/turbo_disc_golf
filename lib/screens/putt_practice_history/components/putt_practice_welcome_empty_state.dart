import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';

class PuttPracticeWelcomeEmptyState extends StatelessWidget {
  const PuttPracticeWelcomeEmptyState({
    super.key,
    required this.onStartPractice,
    required this.logger,
  });

  final VoidCallback onStartPractice;
  final LoggingServiceBase logger;

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                const Text(
                  'Putt practice',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your putting and find patterns',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                // Divider
                Divider(color: Colors.grey[300], height: 1),
                const SizedBox(height: 24),
                // Feature bullets
                _buildFeatureRow('🎯', 'Track makes & misses'),
                const SizedBox(height: 16),
                _buildFeatureRow('📈', 'See your putting percentage'),
                const SizedBox(height: 16),
                _buildFeatureRow('🔥', 'Find your miss patterns'),
                const SizedBox(height: 24),
                // Divider
                Divider(color: Colors.grey[300], height: 1),
                const SizedBox(height: 24),
                // CTA Button
                PrimaryButton(
                  width: double.infinity,
                  height: 52,
                  label: 'Start a session',
                  gradientBackground: const [
                    Color(0xFF10B981),
                    Color(0xFF059669),
                  ],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  onPressed: () {
                    logger.track(
                      'Start First Practice Session Button Tapped',
                      properties: {'button_location': 'Empty State'},
                    );

                    onStartPractice();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
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
