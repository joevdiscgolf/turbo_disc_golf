import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/utils/constants/hole_description_examples.dart';

/// Screen showing side-by-side bad vs good hole description examples.
/// Can be shown as a modal bottom sheet or full screen.
class HoleDescriptionExamplesScreen extends StatelessWidget {
  const HoleDescriptionExamplesScreen({
    super.key,
    this.bottomViewPadding = 0,
  });

  final double bottomViewPadding;

  /// Shows this screen as a modal bottom sheet.
  static Future<void> show(BuildContext context) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HoleDescriptionExamplesScreen(
        bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PanelHeader(title: 'How to describe your holes'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Side-by-side comparison cards
                  ...examplePairs.map(
                    (pair) => _ComparisonCard(pair: pair),
                  ),
                  const SizedBox(height: 16),
                  // Key points section
                  _buildSectionHeader(
                    context,
                    'Key points',
                    const Color(0xFF7E57C2),
                  ),
                  const SizedBox(height: 8),
                  _buildKeyPointsCard(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildBottomButton(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 20,
            ),
      ),
    );
  }

  Widget _buildKeyPointsCard(BuildContext context) {
    final List<String> points = whatMakesGoodDescription
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFCE93D8).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: points.map((point) {
          final bool isHeader = !point.startsWith('•') &&
              !point.startsWith('Disc') &&
              !point.startsWith('Shot') &&
              !point.startsWith('Landing') &&
              !point.startsWith('Must');
          if (isHeader) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                point,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + bottomViewPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: PrimaryButton(
        label: 'Got it!',
        width: double.infinity,
        height: 56,
        backgroundColor: const Color(0xFF7E57C2),
        labelColor: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// Card showing side-by-side bad vs good example comparison.
class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.pair});

  final ExamplePair pair;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with outcome type
          _buildHeader(),
          // Two columns: bad on left, good on right
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bad example column
                Expanded(child: _buildBadColumn()),
                // Divider
                Container(width: 1, color: Colors.grey.shade300),
                // Good example column
                Expanded(child: _buildGoodColumn()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the semantic color for the outcome type.
  Color _getOutcomeColor() {
    final String outcome = pair.outcome.toLowerCase();
    if (outcome.contains('birdie')) {
      return const Color(0xFF4CAF50); // Green for birdie
    } else if (outcome.contains('par')) {
      return const Color(0xFF757575); // Gray for par
    } else if (outcome.contains('bogey')) {
      return const Color(0xFFE53935); // Red for bogey
    }
    return Colors.grey; // Fallback
  }

  Widget _buildHeader() {
    final Color outcomeColor = _getOutcomeColor();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: outcomeColor.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(11),
          topRight: Radius.circular(11),
        ),
      ),
      child: Text(
        pair.outcome.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: outcomeColor.withValues(alpha: 0.9),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBadColumn() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFF7A7A).withValues(alpha: 0.08),
            const Color(0xFFFF7A7A).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(11),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.cancel, size: 20, color: Color(0xFFE53935)),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Text(
                '"${pair.bad}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pair.missingNote,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoodColumn() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF4CAF50).withValues(alpha: 0.08),
            const Color(0xFF4CAF50).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(11),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Icon(Icons.check_circle, size: 20, color: Color(0xFF4CAF50)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              '"${pair.good}"',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
