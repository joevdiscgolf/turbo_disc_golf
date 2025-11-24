// editable_throw_timeline.dart
//
// Editable timeline where only throw cards are reorderable.
// Add buttons are visually centered between cards (Option A), anchored
// while dragging, and the throw cards move around them.
// Drag handle is inside the card (right side). Card keeps rounded corners
// while dragging but removes shadow while in drag state.
// Uses flutter_animate for subtle entry animations and uses technique colors.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/naming_constants.dart';

class EditableThrowTimeline extends StatefulWidget {
  const EditableThrowTimeline({
    super.key,
    required this.throws,
    required this.onEditThrow,
    required this.onAddThrowAt,
    this.showAddButtons = true,
    this.enableReorder = true,
    this.onReorder,
  });

  final List<DiscThrow> throws;
  final void Function(int throwIndex) onEditThrow;
  final void Function(int addThrowAtIndex) onAddThrowAt;
  final bool showAddButtons;
  final bool enableReorder;
  final void Function(int oldIndex, int newIndex)? onReorder;

  @override
  State<EditableThrowTimeline> createState() => _EditableThrowTimelineState();
}

class _EditableThrowTimelineState extends State<EditableThrowTimeline> {
  List<GlobalKey> _itemKeys = [];
  List<double> _addButtonY = [];
  List<double> _iconCenterY = [];
  bool _isDragging = false;
  Timer? _recomputeTimer;

  @override
  void initState() {
    super.initState();
    _ensureKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recomputePositions());
  }

  @override
  void didUpdateWidget(covariant EditableThrowTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.throws.length != widget.throws.length) {
      _ensureKeys();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _recomputePositions());
  }

  @override
  void dispose() {
    _recomputeTimer?.cancel();
    super.dispose();
  }

  void _ensureKeys() {
    final List<GlobalKey> old = _itemKeys;
    _itemKeys = List<GlobalKey>.generate(
      widget.throws.length,
      (i) => (i < old.length) ? old[i] : GlobalKey(),
      growable: false,
    );
  }

  void _recomputePositions() {
    if (_isDragging) return;

    _recomputeTimer?.cancel();
    _recomputeTimer = Timer(const Duration(milliseconds: 40), () {
      final RenderBox? listBox = context.findRenderObject() as RenderBox?;
      if (listBox == null || !mounted) return;

      final List<double> iconCenters = [];
      final List<double> addCenters = [];

      // Compute icon center positions for each card
      for (int i = 0; i < _itemKeys.length; i++) {
        final box = _itemKeys[i].currentContext?.findRenderObject() as RenderBox?;
        if (box == null) {
          iconCenters.add(0.0);
        } else {
          final globalTopLeft = box.localToGlobal(Offset.zero);
          // Icon is positioned at top of row with some padding
          // Icon center is approximately at top + 16px (icon radius)
          final iconCenterGlobalY = globalTopLeft.dy + 16.0;
          final iconCenterLocalY = listBox.globalToLocal(Offset(0, iconCenterGlobalY)).dy;
          iconCenters.add(iconCenterLocalY);
        }
      }

      // Compute add button positions (center between consecutive cards)
      for (int i = 0; i < _itemKeys.length - 1; i++) {
        final box1 = _itemKeys[i].currentContext?.findRenderObject() as RenderBox?;
        final box2 = _itemKeys[i + 1].currentContext?.findRenderObject() as RenderBox?;

        if (box1 != null && box2 != null) {
          final pos1 = box1.localToGlobal(Offset.zero);
          final pos2 = box2.localToGlobal(Offset.zero);

          final local1 = listBox.globalToLocal(pos1);
          final local2 = listBox.globalToLocal(pos2);

          final bottom1 = local1.dy + box1.size.height;
          final top2 = local2.dy;
          final centerY = (bottom1 + top2) / 2.0;

          addCenters.add(centerY);
        }
      }

      if (mounted) {
        setState(() {
          _iconCenterY = iconCenters;
          _addButtonY = addCenters;
        });
      }
    });
  }

  void _setDragging(bool dragging) {
    if (_isDragging == dragging) return;
    setState(() => _isDragging = dragging);

    if (!dragging) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recomputePositions());
    }
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (widget.onReorder != null) {
      widget.onReorder!(oldIndex, newIndex);
    }
    _setDragging(false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Reorderable list of throw cards
            Positioned.fill(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                buildDefaultDragHandles: false,
                itemCount: widget.throws.length,
                proxyDecorator: (child, index, animation) {
                  // Customize the appearance of the dragged item
                  return Material(
                    elevation: 0,
                    color: Colors.transparent,
                    child: child,
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex -= 1;
                  _handleReorder(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final discThrow = widget.throws[index];
                  final techniqueColor = _getTechniqueColorForThrow(discThrow);

                  return Container(
                    key: ValueKey('throw_$index'),
                    margin: EdgeInsets.only(
                      bottom: widget.showAddButtons ? 48.0 : 6.0,
                    ),
                    child: _MeasuredThrowRow(
                      measurementKey: _itemKeys[index],
                      discThrow: discThrow,
                      throwIndex: index,
                      isLast: index == widget.throws.length - 1,
                      animationDelay: index * 90,
                      onEdit: () => widget.onEditThrow(index),
                      onDragStateChange: _setDragging,
                      showDragHandle: widget.enableReorder,
                      accentColor: techniqueColor,
                    ),
                  );
                },
              ),
            ),

            // Overlay connectors between icons
            if (_iconCenterY.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    children: [
                      for (int i = 0; i < _iconCenterY.length - 1; i++)
                        Builder(
                          builder: (ctx) {
                            const double iconRadius = 16.0; // Icon is 32px diameter
                            // Start at bottom of top icon, end at top of bottom icon
                            final startY = _iconCenterY[i] + iconRadius;
                            final endY = _iconCenterY[i + 1] - iconRadius;
                            final height = (endY - startY).clamp(0.0, double.infinity);
                            final discThrow = widget.throws[i];
                            final color = _getTechniqueColorForThrow(discThrow);

                            return Positioned(
                              left: 37, // Center line on icon (16px padding + 22px to icon center - 1px for 2px line width)
                              top: startY,
                              child: Container(
                                width: 2,
                                height: height,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      color.withValues(alpha: 0.5),
                                      color.withValues(alpha: 0.18),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

            // Add buttons positioned between cards using measured positions
            if (widget.showAddButtons && _addButtonY.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: Stack(
                    children: [
                      for (int i = 0; i < _addButtonY.length; i++)
                        Positioned(
                          left: (constraints.maxWidth / 2) - 16, // Center horizontally (32px button / 2)
                          top: _addButtonY[i] - 16, // Center vertically (32px button / 2)
                          child: GestureDetector(
                            onTap: () => widget.onAddThrowAt(i),
                            child: _AnchoredAddButton(
                              color: _getTechniqueColorForThrow(
                                widget.throws[i],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Color _getTechniqueColorForThrow(DiscThrow discThrow) {
    switch (discThrow.technique) {
      case ThrowTechnique.backhand:
      case ThrowTechnique.backhandRoller:
        return const Color(0xFF4A90E2);
      case ThrowTechnique.forehand:
      case ThrowTechnique.forehandRoller:
        return const Color(0xFF50C878);
      default:
        if (discThrow.purpose == ThrowPurpose.putt) {
          return const Color(0xFFFDB927);
        }
        return const Color(0xFF9E9E9E);
    }
  }
}

/// A single measured row that reports a key and contains the throw icon (left),
/// the card (right) and exposes the drag-handle listener for drag-state.
class _MeasuredThrowRow extends StatelessWidget {
  const _MeasuredThrowRow({
    required this.measurementKey,
    required this.discThrow,
    required this.throwIndex,
    required this.isLast,
    required this.animationDelay,
    required this.onEdit,
    required this.onDragStateChange,
    required this.showDragHandle,
    required this.accentColor,
  });

  final GlobalKey measurementKey;
  final DiscThrow discThrow;
  final int throwIndex;
  final bool isLast;
  final int animationDelay;
  final VoidCallback onEdit;
  final void Function(bool isDragging) onDragStateChange;
  final bool showDragHandle;
  final Color accentColor;

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
    final techniqueColor = accentColor;
    final techniqueIcon = _getTechniqueIcon();
    final details = _getThrowDetails();

    return Container(
      key: measurementKey,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: icon; connector no longer rendered here (overlay handles it)
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: techniqueColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: techniqueColor, width: 2),
                    ),
                    child: Icon(techniqueIcon, size: 16, color: techniqueColor),
                  ),
                  // Spacer to create space for the overlay connector
                  if (!isLast) Expanded(child: Container()),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Card
            Expanded(
              child: _ThrowCard(
                title: _getThrowTitle(),
                details: details,
                accentColor: techniqueColor,
                animationDelay: animationDelay,
                onEdit: onEdit,
                onDragStateChange: onDragStateChange,
                showDragHandle: showDragHandle,
                visualIndex: throwIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stateful throw card that removes shadow while being dragged (but keeps rounded corners).
class _ThrowCard extends StatefulWidget {
  const _ThrowCard({
    required this.title,
    required this.details,
    required this.accentColor,
    required this.animationDelay,
    required this.onEdit,
    required this.onDragStateChange,
    required this.showDragHandle,
    required this.visualIndex,
  });

  final String title;
  final List<String> details;
  final Color accentColor;
  final int animationDelay;
  final VoidCallback onEdit;
  final void Function(bool) onDragStateChange;
  final bool showDragHandle;
  final int visualIndex;

  @override
  State<_ThrowCard> createState() => _ThrowCardState();
}

class _ThrowCardState extends State<_ThrowCard> {
  bool _isDraggingLocal = false;

  void _handleLocalDragState(bool dragging) {
    if (_isDraggingLocal == dragging) return;
    setState(() => _isDraggingLocal = dragging);
    widget.onDragStateChange(dragging);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onEdit,
      child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.accentColor.withValues(alpha: 0.28),
                width: 1,
              ),
              boxShadow: _isDraggingLocal
                  ? null
                  : [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Title + details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.accentColor,
                        ),
                      ),
                      if (widget.details.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.details.join(' • '),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Icon(Icons.edit_outlined, size: 18, color: widget.accentColor),

                if (widget.showDragHandle) ...[
                  const SizedBox(width: 6),
                  ReorderableDragStartListener(
                    index: widget.visualIndex,
                    child: Listener(
                      onPointerDown: (_) => _handleLocalDragState(true),
                      onPointerUp: (_) => _handleLocalDragState(false),
                      onPointerCancel: (_) => _handleLocalDragState(false),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Icon(
                          Icons.drag_handle,
                          size: 20,
                          color: widget.accentColor.withValues(alpha: 0.84),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
          .animate(delay: Duration(milliseconds: widget.animationDelay))
          .fadeIn(duration: 280.ms, curve: Curves.easeOut)
          .slideY(begin: 0.08, end: 0.0, duration: 280.ms, curve: Curves.easeOut),
    );
  }
}

/// Anchored add button UI (32x32 circular) — colorable if you want.
class _AnchoredAddButton extends StatelessWidget {
  const _AnchoredAddButton({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? TurbColors.blue;
    return Bounceable(
      onTap: () {
        // parent GestureDetector handles actual add callback
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: const Center(
          child: Icon(Icons.add, size: 18, color: Colors.white),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}
