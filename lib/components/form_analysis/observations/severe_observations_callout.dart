import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/form_analysis/observations/observation_card.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/form_observation.dart';

/// Red-tinted callout displaying severe observations at the top
class SevereObservationsCallout extends StatelessWidget {
  const SevereObservationsCallout({
    super.key,
    required this.observations,
    required this.onObservationTap,
    this.activeObservationId,
  });

  final List<FormObservation> observations;
  final void Function(FormObservation) onObservationTap;
  final String? activeObservationId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF44336).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF44336).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: observations.map((observation) {
          final int index = observations.indexOf(observation);
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < observations.length - 1 ? 8 : 0,
            ),
            child: ObservationCard(
              observation: observation,
              onTap: () => onObservationTap(observation),
              isActive: observation.observationId == activeObservationId,
              compact: true,
            ),
          );
        }).toList(),
      ),
    );
  }
}
