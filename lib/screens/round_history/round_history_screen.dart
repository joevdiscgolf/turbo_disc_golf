import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_history/components/record_round_sheet.dart';
import 'package:turbo_disc_golf/screens/round_history/components/round_history_row.dart';
import 'package:turbo_disc_golf/screens/round_processing/round_processing_loading_screen.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_round_service.dart';
import 'package:turbo_disc_golf/utils/panel_helpers.dart';

class RoundHistoryScreen extends StatelessWidget {
  const RoundHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<List<DGRound>>(
          future: locator.get<FirestoreRoundService>().getRounds(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading rounds',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final List<DGRound> rounds = snapshot.data ?? [];

            // Sort rounds by date (most recent first)
            // Priority: playedRoundAt > createdAt > id
            rounds.sort((a, b) {
              final String? aDate = a.playedRoundAt ?? a.createdAt;
              final String? bDate = b.playedRoundAt ?? b.createdAt;

              if (aDate != null && bDate != null) {
                // Both have dates, compare them (most recent first)
                return bDate.compareTo(aDate);
              } else if (aDate != null) {
                // a has a date, b doesn't - a comes first
                return -1;
              } else if (bDate != null) {
                // b has a date, a doesn't - b comes first
                return 1;
              } else {
                // Neither has a date, fall back to ID comparison
                return b.id.compareTo(a.id);
              }
            });

            if (rounds.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.golf_course,
                      size: 80,
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No rounds yet',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first round to get started!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rounds.length,
              itemBuilder: (context, index) {
                final DGRound round = rounds[index];
                return RoundHistoryRow(round: round);
              },
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFBA68C8), Color(0xFF9C27B0)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    displayBottomSheet(
                      context,
                      RecordRoundSheet(
                        onContinuePressed: _onContinuePressed,
                        onTestPressed: _onTestPressed,
                      ),
                    );
                  },
                  customBorder: const CircleBorder(),
                  child: const Center(
                    child: Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onContinuePressed(
    BuildContext context, {
    required String transcript,
    String? courseName,
  }) {
    // Replace the bottom sheet with the loading screen
    _pushProcessingScreenWithTranscript(
      context,
      transcript,
      null,
      useSharedPreferences: false,
    );
  }

  void _onTestPressed(
    BuildContext context, {
    required String testTranscript,
    String? courseName,
  }) {
    // final RoundStorageService storageService = locator
    //     .get<RoundStorageService>();

    // Check if there's a cached round available
    final bool useCached = false;
    // await storageService
    // .hasCachedRound();
    debugPrint('Test Parse Constant: Using cached round: $useCached');

    if (context.mounted) {
      _pushProcessingScreenWithTranscript(
        context,
        testTranscript,
        'Foxwood Reds',
        useSharedPreferences: useCached,
      );
    }
  }

  void _pushProcessingScreenWithTranscript(
    BuildContext context,
    String transcript,
    String? courseName, {
    required bool useSharedPreferences,
  }) {
    // Replace the bottom sheet with the loading screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RoundProcessingLoadingScreen(
          transcript: transcript,
          courseName: courseName,
          useSharedPreferences: useSharedPreferences,
        ),
      ),
    );
  }
}
