// editable_throw_timeline.dart
// Editable timeline where only throw cards are reorderable.
// Drag handle is inside the card on the right side. Add-buttons are shown
// below each throw card but live inside the same reorderable item so they're
// not individually draggable.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/naming_constants.dart';

/// Timeline of throws with add/edit buttons and connector line adjustments.
class EditableThrowTimeline extends StatelessWidget {
  const EditableThrowTimeline({
    super.key,
    required this.throws,
    required this.onEditThrow,
    required this.onAddThrowAt,
    this.showAddButtons = false,
    required this.enableReorder,
    required this.onReorder,
  });

  final List<DiscThrow> throws;
  final void Function(int throwIndex) onEditThrow;
  final void Function(int addThrowAtIndex) onAddThrowAt;
  final bool showAddButtons;
  final bool enableReorder;
  final void Function(int oldIndex, int newIndex) onReorder;

  // Color _getTechniqueColorForThrow(DiscThrow discThrow) {
  //   switch (discThrow.technique) {
  //     case ThrowTechnique.backhand:
  //     case ThrowTechnique.backhandRoller:
  //       return const Color(0xFF4A90E2); // Blue
  //     case ThrowTechnique.forehand:
  //     case ThrowTechnique.forehandRoller:
  //       return const Color(0xFF50C878); // Green
  //     case ThrowTechnique.tomahawk:
  //     case ThrowTechnique.thumber:
  //     case ThrowTechnique.overhand:
  //     case ThrowTechnique.grenade:
  //     case ThrowTechnique.other:
  //     default:
  //       // Fall back to purpose-based color for putts
  //       if (discThrow.purpose == ThrowPurpose.putt) {
  //         return const Color(0xFFFDB927); // Yellow/Gold
  //       }
  //       return const Color(0xFF9E9E9E); // Grey for unknown
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    if (throws.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ElevatedButton.icon(
            onPressed: () => onAddThrowAt(0),
            icon: const Icon(Icons.add),
            label: const Text('Add first throw'),
          ),
        ),
      );
    }

    // If reordering enabled and callback supplied, show ReorderableListView
    if (enableReorder && onReorder != null) {
      return ReorderableListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        buildDefaultDragHandles: false,
        onReorder: (int oldIndex, int newIndex) {
          // Handle Flutter behaviour: when moving down the incoming newIndex
          // is one greater than expected, normalize it.
          if (newIndex > oldIndex) newIndex -= 1;
          onReorder!(oldIndex, newIndex);
        },
        children: [
          for (int i = 0; i < throws.length; i++)
            _ThrowListItemColumn(
              key: ValueKey('throw_$i'),
              throwIndex: i,
              discThrow: throws[i],
              isLast: i == throws.length - 1,
              animationDelay: i * 100,
              onEdit: () => onEditThrow(i),
              onAddAfter: () => onAddThrowAt(i),
              showAddButton: showAddButtons,
            ),
        ],
      );
    }

    // Non-reorderable ListView
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: throws.length,
      itemBuilder: (context, i) {
        final discThrow = throws[i];
        return _ThrowListItemColumn(
          key: ValueKey('throw_$i'),
          throwIndex: i,
          discThrow: discThrow,
          isLast: i == throws.length - 1,
          animationDelay: i * 100,
          onEdit: () => onEditThrow(i),
          onAddAfter: () => onAddThrowAt(i),
          showAddButton: showAddButtons,
        );
      },
    );
  }
}

/// Each Reorderable child is a Column that contains the throw row + the add button
class _ThrowListItemColumn extends StatelessWidget {
  const _ThrowListItemColumn({
    required Key key,
    required this.throwIndex,
    required this.discThrow,
    required this.isLast,
    required this.animationDelay,
    required this.onEdit,
    required this.onAddAfter,
    required this.showAddButton,
  }) : super(key: key);

  final int throwIndex;
  final DiscThrow discThrow;
  final bool isLast;
  final int animationDelay;
  final VoidCallback onEdit;
  final VoidCallback onAddAfter;
  final bool showAddButton;

  @override
  Widget build(BuildContext context) {
    final Color techniqueColor = _getTechniqueColorForThrow(discThrow);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditableThrowTimelineItem(
          key: ValueKey('item_card_$throwIndex'),
          discThrow: discThrow,
          throwIndex: throwIndex,
          isLast: isLast && !showAddButton,
          animationDelay: animationDelay,
          onEdit: onEdit,
          showDragHandle: true,
        ),
        if (showAddButton)
          Padding(
            padding: const EdgeInsets.only(left: 44.0),
            child: _AddThrowButton(
              key: ValueKey('add_after_$throwIndex'),
              onAdd: onAddAfter,
              connectorColor: techniqueColor,
              showConnector: !isLast,
            ),
          ),
        if (!showAddButton && !isLast) const SizedBox(height: 8),
      ],
    );
  }

  Color _getTechniqueColorForThrow(DiscThrow discThrow) {
    switch (discThrow.technique) {
      case ThrowTechnique.backhand:
      case ThrowTechnique.backhandRoller:
        return const Color(0xFF4A90E2); // Blue
      case ThrowTechnique.forehand:
      case ThrowTechnique.forehandRoller:
        return const Color(0xFF50C878); // Green
      case ThrowTechnique.tomahawk:
      case ThrowTechnique.thumber:
      case ThrowTechnique.overhand:
      case ThrowTechnique.grenade:
      case ThrowTechnique.other:
      default:
        if (discThrow.purpose == ThrowPurpose.putt) {
          return const Color(0xFFFDB927);
        }
        return const Color(0xFF9E9E9E);
    }
  }
}

/// Small circular + button between throw items with connector line.
class _AddThrowButton extends StatelessWidget {
  const _AddThrowButton({
    super.key,
    required this.onAdd,
    required this.connectorColor,
    required this.showConnector,
  });

  final VoidCallback onAdd;
  final Color connectorColor;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32, // 4px top + 24px button + 4px bottom
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showConnector)
            Positioned(
              left: 15,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      connectorColor.withValues(alpha: 0.2),
                      connectorColor.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
          Bounceable(
            onTap: () {
              onAdd();
            },
            child:
                Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: TurbColors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.15),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.add,
                          color: Theme.of(context).colorScheme.primary,
                          size: 16,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 250.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 250.ms,
                      curve: Curves.easeOutBack,
                    ),
          ),
        ],
      ),
    );
  }
}

class EditableThrowTimelineItem extends StatelessWidget {
  const EditableThrowTimelineItem({
    super.key,
    required this.discThrow,
    required this.throwIndex,
    required this.isLast,
    required this.animationDelay,
    required this.onEdit,
    this.showDragHandle = false,
  });

  final DiscThrow discThrow;
  final int throwIndex;
  final bool isLast;
  final int animationDelay;
  final VoidCallback onEdit;
  final bool showDragHandle;

  Color _getTechniqueColor() {
    switch (discThrow.technique) {
      case ThrowTechnique.backhand:
      case ThrowTechnique.backhandRoller:
        return const Color(0xFF4A90E2); // Blue
      case ThrowTechnique.forehand:
      case ThrowTechnique.forehandRoller:
        return const Color(0xFF50C878); // Green
      case ThrowTechnique.tomahawk:
      case ThrowTechnique.thumber:
      case ThrowTechnique.overhand:
      case ThrowTechnique.grenade:
      case ThrowTechnique.other:
      default:
        // Fall back to purpose-based color for putts
        if (discThrow.purpose == ThrowPurpose.putt) {
          return const Color(0xFFFDB927); // Yellow/Gold
        }
        return const Color(0xFF9E9E9E); // Grey for unknown
    }
  }

  IconData _getTechniqueIcon() {
    switch (discThrow.technique) {
      case ThrowTechnique.backhand:
      case ThrowTechnique.backhandRoller:
        return FlutterRemix.disc_line;
      case ThrowTechnique.forehand:
      case ThrowTechnique.forehandRoller:
        return Icons.south_west;
      case ThrowTechnique.tomahawk:
      case ThrowTechnique.thumber:
      case ThrowTechnique.overhand:
        return Icons.arrow_downward;
      case ThrowTechnique.grenade:
        return FlutterRemix.arrow_down_circle_line;
      case ThrowTechnique.other:
      default:
        if (discThrow.purpose == ThrowPurpose.putt) {
          return FlutterRemix.flag_line;
        }
        return Icons.sports_golf;
    }
  }

  String _getThrowTitle() {
    final String throwNumber = 'Throw ${throwIndex + 1}';
    if (discThrow.technique != null) {
      return '$throwNumber: ${throwTechniqueToName[discThrow.technique]}';
    }
    return throwNumber;
  }

  List<String> _getThrowDetails() {
    final List<String> details = [];

    if (discThrow.distanceFeetBeforeThrow != null) {
      details.add('${discThrow.distanceFeetBeforeThrow} ft');
    }

    if (discThrow.disc != null) {
      details.add(discThrow.disc!.name);
    }

    if (discThrow.landingSpot != null) {
      details.add(landingSpotToName[discThrow.landingSpot] ?? '');
    }

    return details;
  }

  @override
  Widget build(BuildContext context) {
    final Color techniqueColor = _getTechniqueColor();
    final IconData techniqueIcon = _getTechniqueIcon();
    final List<String> details = _getThrowDetails();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Icon and connecting line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Icon
                Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: techniqueColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: techniqueColor, width: 2),
                      ),
                      child: Icon(
                        techniqueIcon,
                        size: 16,
                        color: techniqueColor,
                      ),
                    )
                    .animate(delay: Duration(milliseconds: animationDelay))
                    .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 300.ms,
                      curve: Curves.easeOutBack,
                    ),

                // Connecting line that fills the throw card height
                if (!isLast)
                  Expanded(
                    child: _TimelineConnector(
                      color: techniqueColor,
                      animationDelay: animationDelay + 200,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right side: Throw details card with edit button
          Expanded(
            child: _EditableThrowDetailCard(
              title: _getThrowTitle(),
              details: details,
              accentColor: techniqueColor,
              animationDelay: animationDelay,
              onEdit: onEdit,
              showDragHandle: showDragHandle,
              visualIndex: throwIndex,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({required this.color, required this.animationDelay});

  final Color color;
  final int animationDelay;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.5),
                color.withValues(alpha: 0.2),
              ],
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: animationDelay))
        .scaleY(
          begin: 0.0,
          end: 1.0,
          duration: 300.ms,
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
        )
        .fadeIn(duration: 300.ms);
  }
}

class _EditableThrowDetailCard extends StatelessWidget {
  const _EditableThrowDetailCard({
    required this.title,
    required this.details,
    required this.accentColor,
    required this.animationDelay,
    required this.onEdit,
    this.showDragHandle = false,
    required this.visualIndex,
  });

  final String title;
  final List<String> details;
  final Color accentColor;
  final int animationDelay;
  final VoidCallback onEdit;
  final bool showDragHandle;
  final int visualIndex;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(10),
      child:
          Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: accentColor,
                                ),
                          ),
                          if (details.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              details.join(' • '),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.edit_outlined, size: 18, color: accentColor),
                    // Drag handle (on the right side inside the card)
                    if (showDragHandle) ...[
                      ReorderableDragStartListener(
                        index: visualIndex,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.drag_handle,
                            size: 20,
                            color: accentColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
              .animate(delay: Duration(milliseconds: animationDelay))
              .fadeIn(duration: 300.ms, curve: Curves.easeOut)
              .slideY(
                begin: 0.3,
                end: 0.0,
                duration: 300.ms,
                curve: Curves.easeOut,
              ),
    );
  }
}
