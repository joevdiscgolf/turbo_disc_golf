import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/components/buttons/primary_button.dart';

class WelcomeEmptyState extends StatelessWidget {
  const WelcomeEmptyState({super.key, required this.onAddRound});

  final VoidCallback onAddRound;

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
                // Header with app icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 32,
                        height: 32,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'ScoreSensei',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your disc golf journey starts here',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                // Divider
                Divider(color: Colors.grey[300], height: 1),
                const SizedBox(height: 24),
                // Feature bullets
                _buildFeatureRow('🎤', 'Voice-record your rounds'),
                const SizedBox(height: 16),
                _buildFeatureRow('📊', 'Track stats & see trends'),
                const SizedBox(height: 16),
                _buildFeatureRow('🔥', 'Get roasted (or glazed!) by AI'),
                const SizedBox(height: 24),
                // Divider
                Divider(color: Colors.grey[300], height: 1),
                const SizedBox(height: 24),
                // CTA Button
                PrimaryButton(
                  width: double.infinity,
                  height: 52,
                  label: 'Add your first round',
                  gradientBackground: const [
                    Color(0xFF137e66),
                    Color(0xFF1a9f7f),
                  ],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  onPressed: onAddRound,
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
