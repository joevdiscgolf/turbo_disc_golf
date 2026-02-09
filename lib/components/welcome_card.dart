import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';

/// A feature item displayed in the welcome card
class WelcomeFeatureItem {
  const WelcomeFeatureItem({
    required this.emoji,
    required this.text,
  });

  final String emoji;
  final String text;
}

/// Generic welcome card component for empty states
/// Used across different screens with customizable content
class WelcomeCard extends StatelessWidget {
  const WelcomeCard({
    super.key,
    required this.headerWidget,
    required this.features,
    required this.buttonLabel,
    required this.onButtonPressed,
    required this.logger,
    required this.analyticsEventName,
    this.subtitle,
    this.analyticsProperties = const {},
  });

  /// Widget displayed in the header (icon + title)
  final Widget headerWidget;

  /// Optional subtitle below the header
  final String? subtitle;

  /// List of feature items to display
  final List<WelcomeFeatureItem> features;

  /// Label for the CTA button
  final String buttonLabel;

  /// Callback when button is pressed
  final VoidCallback onButtonPressed;

  /// Logger for analytics
  final LoggingServiceBase logger;

  /// Analytics event name for button tap
  final String analyticsEventName;

  /// Additional analytics properties
  final Map<String, dynamic> analyticsProperties;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                headerWidget,
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 16),
                Divider(color: Colors.grey[300], height: 1),
                const SizedBox(height: 24),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildFeatureRow(feature.emoji, feature.text),
                    )),
                const SizedBox(height: 8),
                Divider(color: Colors.grey[300], height: 1),
                const SizedBox(height: 24),
                PrimaryButton(
                  width: double.infinity,
                  height: 52,
                  label: buttonLabel,
                  gradientBackground: const [
                    Color(0xFF137e66),
                    Color(0xFF1a9f7f),
                  ],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  onPressed: () {
                    logger.track(
                      analyticsEventName,
                      properties: {
                        'button_location': 'empty_state',
                        ...analyticsProperties,
                      },
                    );
                    onButtonPressed();
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
