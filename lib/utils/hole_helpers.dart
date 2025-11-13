import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/screens/round_history/components/record_round_sheet.dart';
import 'package:turbo_disc_golf/utils/panel_helpers.dart';

void getIndividualHoleFromVoice(
  BuildContext context, {
  required Function({PotentialDGHole parsedPotentialHole}) onParseHoleFromVoice,
}) {
  displayBottomSheet(
    context,
    RecordRoundSheet(
      onContinuePressed:
          (
            BuildContext context, {
            required String transcript,
            String? courseName,
          }) {},
      onTestPressed:
          (
            BuildContext context, {
            required String testTranscript,
            String? courseName,
          }) {},
    ),
  );
}
