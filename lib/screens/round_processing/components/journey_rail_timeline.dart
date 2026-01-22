// journey_rail_timeline.dart
//
// "Journey Rail" style timeline showing a visual progression on the left.
// Each throw shows WHERE you are at each step with location badges
// connected by a rail with distance labels between nodes.
//
// Visual design:
//     ┌─ Tee ─┐
//     │   ○───┼───────────────────────────────────────┐
//     │   │   │  Tee shot                        ✎ ≡ │
//     │ 350ft │  [BH] [Destroyer]                     │
//     │   │   └───────────────────────────────────────┘
//     │   ▼
//   ┌─ Fairway ─┤─────────────────────────────────────┐
//     │   ○───│  Approach                        ✎ ≡ │
//     │  45ft │  [MD4]                                │
//     │   │   └───────────────────────────────────────┘
//     │   ▼
//   [Basket ✓]

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/naming_constants.dart';

/// Journey rail style timeline with location badges on the left.
class JourneyRailTimeline extends StatefulWidget {
  const JourneyRailTimeline({
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
  State<JourneyRailTimeline> createState() => _JourneyRailTimelineState();
}

class _JourneyRailTimelineState extends State<JourneyRailTimeline> {
  List<GlobalKey> _itemKeys = [];
  List<double> _nodePositions = [];
  List<double> _addButtonY = [];
  bool _isDragging = false;
  Timer? _recomputeTimer;

  @override
  void initState() {
    super.initState();
    _ensureKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recomputePositions());
  }

  @override
  void didUpdateWidget(covariant JourneyRailTimeline oldWidget) {
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

      final List<double> nodePositions = [];
      final List<double> addCenters = [];

      // Compute node center positions for each card
      for (int i = 0; i < _itemKeys.length; i++) {
        final box =
            _itemKeys[i].currentContext?.findRenderObject() as RenderBox?;
        if (box == null) {
          nodePositions.add(0.0);
        } else {
          final globalTopLeft = box.localToGlobal(Offset.zero);
          // Node is centered vertically on the card
          final cardCenterGlobalY = globalTopLeft.dy + box.size.height / 2;
          final cardCenterLocalY =
              listBox.globalToLocal(Offset(0, cardCenterGlobalY)).dy;
          nodePositions.add(cardCenterLocalY);
        }
      }

      // Compute add button positions (center between consecutive cards)
      for (int i = 0; i < _itemKeys.length - 1; i++) {
        final box1 =
            _itemKeys[i].currentContext?.findRenderObject() as RenderBox?;
        final box2 =
            _itemKeys[i + 1].currentContext?.findRenderObject() as RenderBox?;

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
          _nodePositions = nodePositions;
          _addButtonY = addCenters;
        });
      }
    });
  }

  void _setDragging(bool dragging) {
    if (_isDragging == dragging) return;
    setState(() => _isDragging = dragging);

    if (!dragging) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _recomputePositions(),
      );
    }
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (widget.onReorder != null) {
      widget.onReorder!(oldIndex, newIndex);
    }
    _setDragging(false);
  }

  Color _getPurposeColorForThrow(DiscThrow discThrow) {
    switch (discThrow.purpose) {
      case ThrowPurpose.teeDrive:
      case ThrowPurpose.fairwayDrive:
        return const Color(0xFF5C6BC0); // Indigo
      case ThrowPurpose.approach:
        return const Color(0xFF2196F3); // Blue
      case ThrowPurpose.putt:
        return const Color(0xFF66BB6A); // Green
      case ThrowPurpose.scramble:
      case ThrowPurpose.other:
      default:
        return const Color(0xFF78909C); // Slate
    }
  }

  String _getLocationLabel(DiscThrow? prevThrow, DiscThrow currentThrow) {
    if (currentThrow.purpose == ThrowPurpose.teeDrive) {
      return 'Tee';
    }
    if (prevThrow?.landingSpot != null) {
      return _abbreviateLocation(landingSpotToName[prevThrow!.landingSpot]!);
    }
    if (prevThrow?.distanceFeetAfterThrow != null) {
      return '${prevThrow!.distanceFeetAfterThrow} ft';
    }
    return '?';
  }

  String _abbreviateLocation(String location) {
    switch (location) {
      case 'Circle 1':
        return 'C1';
      case 'Circle 2':
        return 'C2';
      case 'Out of bounds':
        return 'OB';
      case 'Hazard':
        return 'HZ';
      case 'In basket':
        return 'Basket';
      default:
        return location;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Journey rail on the left (connectors + distance labels)
              if (_nodePositions.length > 1)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  width: 60,
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _JourneyRailPainter(
                        nodePositions: _nodePositions,
                        throws: widget.throws,
                        getPurposeColor: _getPurposeColorForThrow,
                      ),
                    ),
                  ),
                ),

              // Reorderable list of throw cards
              Positioned.fill(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.only(
                    left: 80,
                    right: 16,
                    top: 12,
                    bottom: 12,
                  ),
                  buildDefaultDragHandles: false,
                  itemCount: widget.throws.length,
                  proxyDecorator: (child, index, animation) {
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
                    final purposeColor = _getPurposeColorForThrow(discThrow);
                    final prevThrow = index > 0 ? widget.throws[index - 1] : null;
                    final locationLabel =
                        _getLocationLabel(prevThrow, discThrow);

                    return Container(
                      key: ValueKey('journey_throw_$index'),
                      margin: EdgeInsets.only(
                        bottom: widget.showAddButtons ? 48.0 : 6.0,
                      ),
                      child: _JourneyThrowCard(
                        measurementKey: _itemKeys[index],
                        discThrow: discThrow,
                        throwIndex: index,
                        locationLabel: locationLabel,
                        animationDelay: index * 90,
                        onEdit: () => widget.onEditThrow(index),
                        onDragStateChange: _setDragging,
                        showDragHandle: widget.enableReorder,
                        accentColor: purposeColor,
                      ),
                    );
                  },
                ),
              ),

              // Location badges on the rail (overlaid)
              if (_nodePositions.isNotEmpty)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  width: 60,
                  child: IgnorePointer(
                    child: Stack(
                      children: [
                        for (int i = 0; i < _nodePositions.length; i++)
                          Positioned(
                            left: 0,
                            top: _nodePositions[i] - 12,
                            child: _JourneyNode(
                              label: _getLocationLabel(
                                i > 0 ? widget.throws[i - 1] : null,
                                widget.throws[i],
                              ),
                              color: _getPurposeColorForThrow(widget.throws[i]),
                              isLast: i == widget.throws.length - 1,
                            ),
                          ),
                        // Basket node at the end
                        if (widget.throws.isNotEmpty &&
                            widget.throws.last.landingSpot ==
                                LandingSpot.inBasket)
                          Positioned(
                            left: 0,
                            top: _nodePositions.last + 36,
                            child: _JourneyNode(
                              label: 'Basket',
                              color: Colors.green.shade600,
                              isBasket: true,
                              isLast: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // Add buttons positioned between cards
              if (widget.showAddButtons && _addButtonY.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: false,
                    child: Stack(
                      children: [
                        for (int i = 0; i < _addButtonY.length; i++)
                          Positioned(
                            left: (constraints.maxWidth / 2) - 16 + 32,
                            top: _addButtonY[i] - 16,
                            child: GestureDetector(
                              onTap: () => widget.onAddThrowAt(i),
                              child: _AddButton(
                                color: _getPurposeColorForThrow(
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
          ),
        );
      },
    );
  }
}

/// Custom painter for the journey rail connecting lines.
class _JourneyRailPainter extends CustomPainter {
  _JourneyRailPainter({
    required this.nodePositions,
    required this.throws,
    required this.getPurposeColor,
  });

  final List<double> nodePositions;
  final List<DiscThrow> throws;
  final Color Function(DiscThrow) getPurposeColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length < 2) return;

    const double railX = 30.0;

    for (int i = 0; i < nodePositions.length - 1; i++) {
      final startY = nodePositions[i] + 12;
      final endY = nodePositions[i + 1] - 12;
      final color = getPurposeColor(throws[i]);

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.6),
            getPurposeColor(throws[i + 1]).withValues(alpha: 0.3),
          ],
        ).createShader(
          Rect.fromLTRB(railX - 1, startY, railX + 1, endY),
        )
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(railX, startY),
        Offset(railX, endY),
        paint,
      );

      // Distance label in the middle
      final discThrow = throws[i];
      String? distanceLabel;
      if (discThrow.distanceFeetAfterThrow != null) {
        distanceLabel = '${discThrow.distanceFeetAfterThrow} ft';
      } else if (i + 1 < throws.length &&
          throws[i + 1].distanceFeetBeforeThrow != null) {
        final nextDist = throws[i + 1].distanceFeetBeforeThrow;
        if (discThrow.distanceFeetBeforeThrow != null && nextDist != null) {
          final traveled =
              discThrow.distanceFeetBeforeThrow! - nextDist;
          if (traveled > 0) {
            distanceLabel = '$traveled ft';
          }
        }
      }

      if (distanceLabel != null) {
        final midY = (startY + endY) / 2;
        final textPainter = TextPainter(
          text: TextSpan(
            text: distanceLabel,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: SenseiColors.gray[500],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(railX + 6, midY - textPainter.height / 2),
        );
      }
    }

    // Draw connector to basket if last throw was in basket
    if (throws.isNotEmpty && throws.last.landingSpot == LandingSpot.inBasket) {
      final lastY = nodePositions.last + 12;
      final basketY = lastY + 48;
      final color = Colors.green.shade600;

      final paint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(railX, lastY),
        Offset(railX, basketY - 12),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _JourneyRailPainter oldDelegate) {
    return nodePositions != oldDelegate.nodePositions ||
        throws != oldDelegate.throws;
  }
}

/// A single node badge on the journey rail.
class _JourneyNode extends StatelessWidget {
  const _JourneyNode({
    required this.label,
    required this.color,
    this.isBasket = false,
    this.isLast = false,
  });

  final String label;
  final Color color;
  final bool isBasket;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBasket) ...[
            Icon(
              Icons.check_circle,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 200.ms,
          curve: Curves.easeOut,
        );
  }
}

/// Simplified throw card for journey rail layout (no arrow column).
class _JourneyThrowCard extends StatefulWidget {
  const _JourneyThrowCard({
    required this.measurementKey,
    required this.discThrow,
    required this.throwIndex,
    required this.locationLabel,
    required this.animationDelay,
    required this.onEdit,
    required this.onDragStateChange,
    required this.showDragHandle,
    required this.accentColor,
  });

  final GlobalKey measurementKey;
  final DiscThrow discThrow;
  final int throwIndex;
  final String locationLabel;
  final int animationDelay;
  final VoidCallback onEdit;
  final void Function(bool isDragging) onDragStateChange;
  final bool showDragHandle;
  final Color accentColor;

  @override
  State<_JourneyThrowCard> createState() => _JourneyThrowCardState();
}

class _JourneyThrowCardState extends State<_JourneyThrowCard> {
  bool _isDraggingLocal = false;

  void _handleLocalDragState(bool dragging) {
    if (_isDraggingLocal == dragging) return;
    setState(() => _isDraggingLocal = dragging);
    widget.onDragStateChange(dragging);
    HapticFeedback.lightImpact();
  }

  String _getThrowTitle() {
    if (widget.discThrow.purpose != null) {
      return throwPurposeToName[widget.discThrow.purpose] ??
          'Throw ${widget.throwIndex + 1}';
    }
    return 'Throw ${widget.throwIndex + 1}';
  }

  String _abbreviateTechnique(String technique) {
    const Map<String, String> abbreviations = {
      'Backhand': 'BH',
      'Forehand': 'FH',
      'Tomahawk': 'TOM',
      'Thumber': 'THU',
      'Overhand': 'OH',
      'Backhand roller': 'BH ROLL',
      'Forehand roller': 'FH ROLL',
      'Grenade': 'GREN',
      'Other': 'OTHER',
    };
    return abbreviations[technique] ?? technique.toUpperCase();
  }

  String _truncateDisc(String name) {
    if (name.length <= 12) return name;
    final List<String> parts = name.split(' ');
    if (parts.length > 1) {
      return parts.last;
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final bool isOutOfBounds =
        widget.discThrow.landingSpot == LandingSpot.outOfBounds ||
            widget.discThrow.landingSpot == LandingSpot.hazard;

    final Color borderColor = isOutOfBounds
        ? Colors.red.withValues(alpha: 0.6)
        : widget.accentColor.withValues(alpha: 0.28);

    return GestureDetector(
      key: widget.measurementKey,
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onEdit();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isOutOfBounds ? 1.5 : 1,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Throw info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getThrowTitle(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: HSLColor.fromColor(widget.accentColor)
                              .withLightness(
                                (HSLColor.fromColor(widget.accentColor)
                                            .lightness -
                                        0.15)
                                    .clamp(0.0, 0.5),
                              )
                              .toColor(),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (widget.discThrow.technique != null)
                        _MiniChip(
                          label: _abbreviateTechnique(
                            throwTechniqueToName[widget.discThrow.technique]!,
                          ),
                          accentColor: widget.accentColor,
                        ),
                      if (widget.discThrow.shotShape != null)
                        _MiniChip(
                          label: shotShapeToName[widget.discThrow.shotShape]!,
                          accentColor: widget.accentColor,
                        ),
                      if (widget.discThrow.disc?.name != null ||
                          widget.discThrow.discName != null)
                        _MiniChip(
                          label: _truncateDisc(
                            widget.discThrow.disc?.name ??
                                widget.discThrow.discName!,
                          ),
                          accentColor: widget.accentColor,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Icons
            Icon(
              Icons.edit_outlined,
              size: 16,
              color: SenseiColors.gray[600],
            ),
            if (widget.showDragHandle) ...[
              const SizedBox(width: 4),
              ReorderableDragStartListener(
                index: widget.throwIndex,
                child: Listener(
                  onPointerDown: (_) => _handleLocalDragState(true),
                  onPointerUp: (_) => _handleLocalDragState(false),
                  onPointerCancel: (_) => _handleLocalDragState(false),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.drag_handle,
                      size: 18,
                      color: SenseiColors.gray[600],
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
          .slideY(
            begin: 0.08,
            end: 0.0,
            duration: 280.ms,
            curve: Curves.easeOut,
          ),
    );
  }
}

/// Mini chip for tag display.
class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.accentColor,
  });

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: SenseiColors.gray[600],
        ),
      ),
    );
  }
}

/// Add button between cards.
class _AddButton extends StatelessWidget {
  const _AddButton({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? SenseiColors.blue;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: const Center(
        child: Icon(Icons.add, size: 18, color: Colors.white),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}
