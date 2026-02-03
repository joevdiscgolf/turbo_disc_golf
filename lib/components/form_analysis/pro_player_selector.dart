import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';

import 'package:turbo_disc_golf/components/panels/generic_selector_panel.dart';
import 'package:turbo_disc_golf/models/data/form_analysis/pro_player_models.dart';
import 'package:turbo_disc_golf/services/form_analysis/pro_player_constants.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Default pro player ID when none is selected.
const String kDefaultProPlayerId = 'paul_mcbeth';

/// A selector button for switching between pro players in form analysis.
///
/// Displays the currently selected pro as a button that opens a selection panel.
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

    final ProPlayerMetadata? selectedPro = availablePros
        .where((pro) => pro.proPlayerId == selectedProId)
        .firstOrNull;
    final String displayName = selectedPro != null
        ? _getDisplayName(selectedPro)
        : 'Select pro';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GestureDetector(
        onTap: () => _showSelectionPanel(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: defaultCardBoxShadow(),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comparing with',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: SenseiColors.gray[400],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: SenseiColors.gray[800],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                FlutterRemix.arrow_right_s_line,
                color: SenseiColors.gray[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelectionPanel(BuildContext context) {
    HapticFeedback.selectionClick();

    showModalBottomSheet<ProPlayerMetadata>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final ProPlayerMetadata? currentSelection = availablePros
            .where((pro) => pro.proPlayerId == selectedProId)
            .firstOrNull;

        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.3,
          maxChildSize: 0.6,
          expand: false,
          builder: (context, scrollController) {
            return GenericSelectorPanel<ProPlayerMetadata>(
              items: availablePros,
              selectedItem: currentSelection,
              getDisplayName: _getDisplayName,
              getId: (pro) => pro.proPlayerId,
              title: 'Select pro player',
              enableSearch: false,
            );
          },
        );
      },
    ).then((selected) {
      if (selected != null) {
        onProSelected(selected.proPlayerId);
      }
    });
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
