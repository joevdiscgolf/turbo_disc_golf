import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/potential_round_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/hole_basic_info_dialog.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/hole_re_record_dialog.dart';
import 'package:turbo_disc_golf/services/round_parser.dart';

/// Reusable component for displaying and fixing an incomplete hole.
/// Used by both EditableHoleDetailSheet and IncompleteHoleWalkthroughSheet.
class IncompleteHoleDetailContent extends StatelessWidget {
  const IncompleteHoleDetailContent({
    super.key,
    required this.potentialHole,
    required this.holeIndex,
    required this.roundParser,
    this.onHoleFixed,
  });

  final PotentialDGHole potentialHole;
  final int holeIndex;
  final RoundParser roundParser;
  final VoidCallback? onHoleFixed; // Called when hole becomes valid

  Color _getSeverityColor(bool hasRequiredFields) {
    return hasRequiredFields
        ? const Color(0xFFFFA726) // Amber for optional missing
        : const Color(0xFFD32F2F); // Red for required missing
  }

  Color _getSeverityBackgroundColor(bool hasRequiredFields) {
    return hasRequiredFields
        ? const Color(0xFFFFF3CD) // Light amber
        : const Color(0xFFFFEBEE); // Light red
  }

  void _handleManualEdit(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => HoleBasicInfoDialog(
        holeNumber: potentialHole.number,
        par: potentialHole.par,
        feet: potentialHole.feet,
        onSave: ({required int holeNumber, required int par, int? feet}) {
          roundParser.updatePotentialHoleMetadata(
            holeIndex,
            number: holeNumber,
            par: par,
            feet: feet,
          );

          // Check if hole is now complete
          _checkAndNotifyIfComplete();
        },
      ),
    );
  }

  void _handleVoiceReRecord(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => HoleReRecordDialog(
        holeNumber: potentialHole.number ?? holeIndex + 1,
        holePar: potentialHole.par,
        holeFeet: potentialHole.feet,
        holeIndex: holeIndex,
        onReProcessed: () {
          // Check if hole is now complete after re-processing
          _checkAndNotifyIfComplete();
        },
      ),
    );
  }

  void _checkAndNotifyIfComplete() {
    // After a brief delay to allow state to update, check if hole is now valid
    Future.delayed(const Duration(milliseconds: 100), () {
      if (roundParser.potentialRound != null &&
          holeIndex < (roundParser.potentialRound!.holes?.length ?? 0)) {
        final updatedHole = roundParser.potentialRound!.holes![holeIndex];
        if (updatedHole.hasRequiredFields) {
          onHoleFixed?.call();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasRequiredFields = potentialHole.hasRequiredFields;
    final List<String> missingFields = potentialHole.getMissingFields();

    // Check if the hole just needs throws recorded
    final bool needsThrows = (potentialHole.throws == null ||
                              potentialHole.throws!.isEmpty) &&
                             missingFields.isEmpty;

    final Color severityColor = _getSeverityColor(hasRequiredFields && !needsThrows);
    final Color backgroundColor = _getSeverityBackgroundColor(hasRequiredFields && !needsThrows);

    // Use darker text colors for better contrast
    final Color textColor = hasRequiredFields && !needsThrows
        ? const Color(0xFF7A5A00) // Darker amber text
        : const Color(0xFF8B1C1C); // Darker red text

    // Build the missing items message
    String missingMessage;
    if (needsThrows) {
      missingMessage = 'This hole needs throws recorded';
    } else if (missingFields.isNotEmpty) {
      missingMessage = 'This hole is missing: ${missingFields.join(', ')}';
    } else {
      missingMessage = 'This hole needs additional information';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Warning Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: severityColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasRequiredFields && !needsThrows
                        ? Icons.warning_amber_rounded
                        : Icons.error_outline,
                    color: severityColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasRequiredFields && !needsThrows
                          ? 'Missing Optional Info'
                          : 'Missing Required Info',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: severityColor,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                missingMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Text(
                'Choose how to fix:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleManualEdit(context),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit', maxLines: 1),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF137e66),
                        side: const BorderSide(color: Color(0xFF137e66)),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleVoiceReRecord(context),
                      icon: const Icon(Icons.mic, size: 16),
                      label: const Text('Re-record', maxLines: 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9D4EDD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Hole Info Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.golf_course,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hole ${potentialHole.number ?? '?'}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  if (potentialHole.hasRequiredFields)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '?',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoItem(
                    context,
                    Icons.flag_outlined,
                    'Par',
                    potentialHole.par?.toString() ?? '—',
                  ),
                  const SizedBox(width: 16),
                  _buildInfoItem(
                    context,
                    Icons.straighten,
                    'Distance',
                    potentialHole.feet != null ? '${potentialHole.feet} ft' : '—',
                  ),
                  const SizedBox(width: 16),
                  _buildInfoItem(
                    context,
                    Icons.sports_golf,
                    'Throws',
                    '${potentialHole.throws?.length ?? 0}',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Throws Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Throws',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (potentialHole.throws == null || potentialHole.throws!.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No throws recorded',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                )
              else
                Column(
                  children: potentialHole.throws!.map((throwData) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A90E2).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.sports_golf,
                                  size: 16,
                                  color: Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Throw ${(throwData.index ?? 0) + 1}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  if (throwData.discName != null)
                                    Text(
                                      throwData.discName!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
