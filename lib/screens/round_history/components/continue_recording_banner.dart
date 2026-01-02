import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/animations/page_transitions.dart';
import 'package:turbo_disc_golf/screens/round_history/components/record_round_steps_screen.dart';
import 'package:turbo_disc_golf/state/record_round_state.dart';

class ContinueRecordingBanner extends StatelessWidget {
  const ContinueRecordingBanner({
    super.key,
    required this.state,
    required this.bottomViewPadding,
  });

  final RecordRoundActive state;
  final double bottomViewPadding;

  @override
  Widget build(BuildContext context) {
    final int holesRecorded = state.holeDescriptions.values
        .where((description) => description.isNotEmpty)
        .length;
    final String? courseName = state.selectedCourse;
    final bool hasCourse = courseName != null && courseName.isNotEmpty;

    // Build subtitle text
    final String subtitle = hasCourse
        ? '$courseName • $holesRecorded/${state.numHoles} holes'
        : '$holesRecorded/${state.numHoles} holes';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewPadding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
        ),
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            BannerExpandPageRoute(
              builder: (context) => RecordRoundStepsScreen(
                bottomViewPadding: bottomViewPadding,
                skipIntroAnimations: true,
              ),
            ),
          );
        },
        child: Hero(
          tag: 'record_round_header',
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Continue Recording',
                          style: TextStyle(
                            color: Color(0xFF1565C0),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: const Color(0xFF1565C0).withValues(alpha: 0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF1565C0),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
