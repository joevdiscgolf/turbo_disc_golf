import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pro_player_models.dart';
import 'package:turbo_disc_golf/services/form_analysis/pro_player_constants.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// A selector for switching between pro players in form analysis.
///
/// Displays a horizontal list of pro player names as selectable chips.
/// Only shown when multiple pro comparisons are available.
class ProPlayerSelector extends StatelessWidget {
  const ProPlayerSelector({
    super.key,
    required this.availablePros,
    required this.selectedProId,
    required this.onProSelected,
  });

  /// List of available pro players.
  final List<ProPlayerMetadata> availablePros;

  /// Currently selected pro player ID.
  final String selectedProId;

  /// Callback when a pro player is selected.
  final ValueChanged<String> onProSelected;

  @override
  Widget build(BuildContext context) {
    if (availablePros.length < 2) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compare with',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: SenseiColors.gray[500],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availablePros.map((pro) {
                final bool isSelected = pro.proPlayerId == selectedProId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildProChip(pro, isSelected),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProChip(ProPlayerMetadata pro, bool isSelected) {
    final String displayName = _getDisplayName(pro);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onProSelected(pro.proPlayerId);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: SenseiColors.gray[200]!, width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          displayName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : SenseiColors.gray[700],
          ),
        ),
      ),
    );
  }

  /// Gets the display name for a pro player.
  /// Uses the metadata displayName if available, falls back to constants.
  String _getDisplayName(ProPlayerMetadata pro) {
    if (pro.displayName.isNotEmpty) {
      return pro.displayName;
    }
    return ProPlayerConstants.getDisplayName(pro.proPlayerId);
  }
}
