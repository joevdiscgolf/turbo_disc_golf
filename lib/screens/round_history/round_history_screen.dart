import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_history/components/record_round_panel.dart';
import 'package:turbo_disc_golf/screens/round_history/components/round_history_row.dart';
import 'package:turbo_disc_golf/services/firestore/firestore_round_service.dart';

class RoundHistoryScreen extends StatefulWidget {
  const RoundHistoryScreen({super.key});

  @override
  State<RoundHistoryScreen> createState() => _RoundHistoryScreenState();
}

class _RoundHistoryScreenState extends State<RoundHistoryScreen> {
  List<DGRound>? _rounds;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRounds();
  }

  Future<void> _loadRounds() async {
    // Only show full-screen loading spinner on initial load
    // During refresh, keep showing existing data with pull-to-refresh indicator
    if (_rounds == null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final List<DGRound> rounds = await locator
          .get<FirestoreRoundService>()
          .getRounds();
      if (mounted) {
        setState(() {
          _rounds = rounds;
          _isLoading = false;
          _error = null; // Clear any previous error on successful load
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshRounds() async {
    await _loadRounds();
  }

  List<DGRound> get _sortedRounds {
    if (_rounds == null) return [];
    final List<DGRound> sorted = List<DGRound>.from(_rounds!);
    sorted.sort((a, b) {
      final String aDate = a.playedRoundAt;
      final String bDate = b.playedRoundAt;
      return bDate.compareTo(aDate);
    });
    return sorted;
  }

  Future<void> _showRecordRoundSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RecordRoundPanel(),
    );

    // Refresh rounds after closing the modal (in case a new round was added)
    _loadRounds();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: _refreshRounds),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(child: _buildErrorState())
            else if (_rounds == null || _rounds!.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final DGRound round = _sortedRounds[index];
                    return RoundHistoryRow(round: round);
                  }, childCount: _sortedRounds.length),
                ),
              ),
          ],
        ),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.golf_course,
            size: 80,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading rounds',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Positioned(
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
              onTap: _showRecordRoundSheet,
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
    );
  }
}
