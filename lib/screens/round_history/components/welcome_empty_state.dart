import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:turbo_disc_golf/components/welcome_card.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class WelcomeEmptyState extends StatelessWidget {
  const WelcomeEmptyState({
    super.key,
    required this.onAddRound,
    required this.logger,
  });

  final VoidCallback onAddRound;
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
            'Get started',
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
      subtitle: 'Your personal coach for every round',
      features: const [
        WelcomeFeatureItem(emoji: '🎤', text: 'Voice record your rounds'),
        WelcomeFeatureItem(emoji: '📊', text: 'See unique stats & trends'),
        WelcomeFeatureItem(emoji: '📖', text: 'Personalized story each round'),
        WelcomeFeatureItem(emoji: '👨‍⚖️', text: 'Get judged (if you dare)'),
      ],
      buttonLabel: 'Add your first round',
      onButtonPressed: onAddRound,
      logger: logger,
      analyticsEventName: 'Add First Round Button Tapped',
    );
  }
}
