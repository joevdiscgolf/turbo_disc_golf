import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:turbo_disc_golf/components/welcome_card.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class FormAnalysisWelcomeEmptyState extends StatelessWidget {
  const FormAnalysisWelcomeEmptyState({
    super.key,
    required this.onStartAnalysis,
    required this.logger,
  });

  final VoidCallback onStartAnalysis;
  final LoggingServiceBase logger;

  @override
  Widget build(BuildContext context) {
    return WelcomeCard(
      headerWidget: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/icon/app_icon.png',
              width: 40,
              height: 40,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Form coach',
            style: GoogleFonts.exo2(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.5,
              color: SenseiColors.gray[700],
            ),
          ),
        ],
      ),
      subtitle: 'Get pro-level analysis & feedback',
      features: const [
        WelcomeFeatureItem(emoji: '🎥', text: 'Record or upload your throw'),
        WelcomeFeatureItem(emoji: '⚖️', text: 'Compare form to top pros'),
        WelcomeFeatureItem(emoji: '💪', text: 'Get personalized coaching tips'),
        WelcomeFeatureItem(emoji: '📊', text: 'Track progress over time'),
      ],
      buttonLabel: 'Analyze your first video',
      onButtonPressed: onStartAnalysis,
      logger: logger,
      analyticsEventName: 'Analyze First Video Button Tapped',
    );
  }
}
