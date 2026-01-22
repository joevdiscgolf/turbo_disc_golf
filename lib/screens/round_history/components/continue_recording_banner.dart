import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/animations/page_transitions.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/screens/record_round/record_round_screen.dart';
import 'package:turbo_disc_golf/screens/round_processing/round_processing_loading_screen.dart';
import 'package:turbo_disc_golf/state/record_round_state.dart';
import 'package:turbo_disc_golf/state/round_confirmation_cubit.dart';
import 'package:turbo_disc_golf/state/round_confirmation_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class ContinueRecordingBanner extends StatelessWidget {
  const ContinueRecordingBanner({
    super.key,
    required this.state,
    required this.topViewPadding,
    required this.bottomViewPadding,
  });

  final RecordRoundActive state;
  final double topViewPadding;
  final double bottomViewPadding;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoundConfirmationCubit, RoundConfirmationState>(
      builder: (context, confirmationState) {
        // If in confirming state, show "Finalize round" banner
        if (confirmationState is ConfirmingRoundActive) {
          return _buildFinalizeBanner(context, confirmationState);
        }

        // Otherwise, show continue recording banner
        final int holesRecorded = state.holeDescriptions.values
            .where((description) => description.isNotEmpty)
            .length;
        final Course? course = state.selectedCourse;
        final bool hasCourse = course != null && course.name.isNotEmpty;

        // Build subtitle text
        final String subtitle = hasCourse
            ? '${course.name} • $holesRecorded/${state.numHoles} holes'
            : '$holesRecorded/${state.numHoles} holes';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                flattenedOverWhite(SenseiColors.blueSecondary, 0.25),
                flattenedOverWhite(SenseiColors.blueSecondary, 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              top: BorderSide(color: SenseiColors.gray.shade200, width: 1),
              right: BorderSide(color: SenseiColors.gray.shade200, width: 1),
              bottom: BorderSide(color: SenseiColors.gray.shade200, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                BannerExpandPageRoute(
                  builder: (context) => RecordRoundScreen(
                    topViewPadding: topViewPadding,
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
                            Text(
                              'Continue recording',
                              style: TextStyle(
                                color: SenseiColors.gray.shade800,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: SenseiColors.gray.shade500,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: SenseiColors.gray.shade400,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinalizeBanner(
    BuildContext context,
    ConfirmingRoundActive confirmationState,
  ) {
    final potentialRound = confirmationState.potentialRound;
    final courseName = potentialRound.courseName ?? 'Unknown Course';
    final layoutName =
        potentialRound.course
            ?.getLayoutById(potentialRound.layoutId ?? '')
            ?.name ??
        'Unknown Layout';
    final String subtitle = '$courseName • $layoutName';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            flattenedOverWhite(SenseiColors.blue, 0.15),
            flattenedOverWhite(SenseiColors.blue, 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          top: BorderSide(color: SenseiColors.gray.shade200, width: 1),
          right: BorderSide(color: SenseiColors.gray.shade200, width: 1),
          bottom: BorderSide(color: SenseiColors.gray.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) =>
                  const RoundProcessingLoadingScreen(fromFinalizeBanner: true),
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
                        Text(
                          'Finalize round',
                          style: TextStyle(
                            color: SenseiColors.gray.shade800,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: SenseiColors.gray.shade500,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: SenseiColors.gray.shade400,
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
