// connected_arrows_timeline.dart
//
// "Connected Arrows" style timeline with left-side location badges
// connected by vertical arrows. Shows where each throw starts from.
//
// Visual design:
//     ┌──────┐
//     │ Tee  │     ┌──────────────────────────────────────────────┐
//     └──┬───┘     │  Tee shot                              ✎  ≡ │
//        │         │  [BH] [Destroyer]                           │
//        │         └──────────────────────────────────────────────┘
//        │
//        ▼
//   ┌────────┐
//   │Fairway │     ┌──────────────────────────────────────────────┐
//   └───┬────┘     │  Approach                              ✎  ≡ │
//       │          │  [MD4]                                       │
//       │          └──────────────────────────────────────────────┘
//       │
//       ▼
//    ┌────┐
//    │ C1 │        ┌──────────────────────────────────────────────┐
//    └─┬──┘        │  Putt                                  ✎  ≡ │
//      │           │                                              │
//      │           └──────────────────────────────────────────────┘
//      │
//      ▼
//  ┌────────┐
//  │Basket ✓│
//  └────────┘

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/naming_constants.dart';

/// Connected arrows style timeline with location badges on the left.
class ConnectedArrowsTimeline extends StatefulWidget {
  const ConnectedArrowsTimeline({
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
  State<ConnectedArrowsTimeline> createState() =>
      _ConnectedArrowsTimelineState();
}

class _ConnectedArrowsTimelineState extends State<ConnectedArrowsTimeline> {
  List<GlobalKey> _itemKeys = [];
  List<Rect> _cardRects = [];
  bool _isDragging = false;
  Timer? _recomputeTimer;

  @override
  void initState() {
    super.initState();
    _ensureKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recomputePositions());
  }

  @override
  void didUpdateWidget(covariant ConnectedArrowsTimeline oldWidget) {
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

      final List<Rect> rects = [];

      for (int i = 0; i < _itemKeys.length; i++) {
        final box =
            _itemKeys[i].currentContext?.findRenderObject() as RenderBox?;
        if (box == null) {
          rects.add(Rect.zero);
        } else {
          final globalTopLeft = box.localToGlobal(Offset.zero);
          final localTopLeft = listBox.globalToLocal(globalTopLeft);
          rects.add(Rect.fromLTWH(
            localTopLeft.dx,
            localTopLeft.dy,
            box.size.width,
            box.size.height,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _cardRects = rects;
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

  /// Get the starting location label for a throw (where the disc is thrown from)
  String _getStartingLocation(int throwIndex) {
    final discThrow = widget.throws[throwIndex];

    // First throw is always from the tee
    if (throwIndex == 0 || discThrow.purpose == ThrowPurpose.teeDrive) {
      return 'Tee';
    }

    // Get the previous throw's landing spot
    if (throwIndex > 0) {
      final prevThrow = widget.throws[throwIndex - 1];
      if (prevThrow.landingSpot != null) {
        return _abbreviateLocation(landingSpotToName[prevThrow.landingSpot]!);
      }
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
              // Reorderable list of throw cards with location badges
              Positioned.fill(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
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
                    final locationLabel = _getStartingLocation(index);
                    final isLast = index == widget.throws.length - 1;
                    final showBasket =
                        isLast && discThrow.landingSpot == LandingSpot.inBasket;

                    return Container(
                      key: ValueKey('connected_throw_$index'),
                      margin: EdgeInsets.only(
                        bottom: widget.showAddButtons ? 16.0 : 6.0,
                      ),
                      child: _ConnectedThrowRow(
                        measurementKey: _itemKeys[index],
                        discThrow: discThrow,
                        throwIndex: index,
                        locationLabel: locationLabel,
                        showConnector: !isLast || showBasket,
                        showBasket: showBasket,
                        animationDelay: index * 90,
                        onEdit: () => widget.onEditThrow(index),
                        onDragStateChange: _setDragging,
                        showDragHandle: widget.enableReorder,
                        accentColor: purposeColor,
                        nextThrowColor: index < widget.throws.length - 1
                            ? _getPurposeColorForThrow(
                                widget.throws[index + 1])
                            : Colors.green.shade600,
                      ),
                    );
                  },
                ),
              ),

              // Add buttons positioned between cards
              if (widget.showAddButtons && _cardRects.length > 1)
                ..._buildAddButtons(constraints),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildAddButtons(BoxConstraints constraints) {
    final List<Widget> buttons = [];

    for (int i = 0; i < _cardRects.length - 1; i++) {
      final rect1 = _cardRects[i];
      final rect2 = _cardRects[i + 1];

      if (rect1 == Rect.zero || rect2 == Rect.zero) continue;

      final startY = rect1.bottom;
      final endY = rect2.top;
      final midY = (startY + endY) / 2;
      final color = _getPurposeColorForThrow(widget.throws[i]);

      buttons.add(
        Positioned(
          right: 32,
          top: midY - 16,
          child: GestureDetector(
            onTap: () => widget.onAddThrowAt(i),
            child: _AddButton(color: color),
          ),
        ),
      );
    }

    return buttons;
  }
}

/// A row containing location badge + connector + throw card.
class _ConnectedThrowRow extends StatelessWidget {
  const _ConnectedThrowRow({
    required this.measurementKey,
    required this.discThrow,
    required this.throwIndex,
    required this.locationLabel,
    required this.showConnector,
    required this.showBasket,
    required this.animationDelay,
    required this.onEdit,
    required this.onDragStateChange,
    required this.showDragHandle,
    required this.accentColor,
    required this.nextThrowColor,
  });

  final GlobalKey measurementKey;
  final DiscThrow discThrow;
  final int throwIndex;
  final String locationLabel;
  final bool showConnector;
  final bool showBasket;
  final int animationDelay;
  final VoidCallback onEdit;
  final void Function(bool isDragging) onDragStateChange;
  final bool showDragHandle;
  final Color accentColor;
  final Color nextThrowColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: measurementKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main row: badge + card
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location badge column
            SizedBox(
              width: 64,
              child: Column(
                children: [
                  _LocationBadge(
                    label: locationLabel,
                    color: accentColor,
                    animationDelay: animationDelay,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Throw card
            Expanded(
              child: _ConnectedThrowCard(
                discThrow: discThrow,
                throwIndex: throwIndex,
                animationDelay: animationDelay,
                onEdit: onEdit,
                onDragStateChange: onDragStateChange,
                showDragHandle: showDragHandle,
                accentColor: accentColor,
              ),
            ),
          ],
        ),

        // Connector + optional basket
        if (showConnector)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connector line
              SizedBox(
                width: 64,
                child: _VerticalConnector(
                  fromColor: accentColor,
                  toColor: nextThrowColor,
                  showArrow: true,
                  height: showBasket ? 48.0 : 32.0,
                  animationDelay: animationDelay + 100,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),

        // Basket badge at the end
        if (showBasket)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                child: _LocationBadge(
                  label: 'Basket',
                  color: Colors.green.shade600,
                  isBasket: true,
                  animationDelay: animationDelay + 200,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
      ],
    );
  }
}

/// Pill-shaped badge showing location (Tee, Fairway, C1, Basket, etc).
class _LocationBadge extends StatelessWidget {
  const _LocationBadge({
    required this.label,
    required this.color,
    this.isBasket = false,
    required this.animationDelay,
  });

  final String label;
  final Color color;
  final bool isBasket;
  final int animationDelay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isBasket) ...[
            Icon(
              Icons.check_circle,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn(duration: 200.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 200.ms,
          curve: Curves.easeOut,
        );
  }
}

/// Vertical connector line with gradient and arrow.
class _VerticalConnector extends StatelessWidget {
  const _VerticalConnector({
    required this.fromColor,
    required this.toColor,
    required this.showArrow,
    required this.height,
    required this.animationDelay,
  });

  final Color fromColor;
  final Color toColor;
  final bool showArrow;
  final double height;
  final int animationDelay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          children: [
            // Gradient line
            Expanded(
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      fromColor.withValues(alpha: 0.5),
                      toColor.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
            // Arrow head
            if (showArrow)
              CustomPaint(
                size: const Size(10, 6),
                painter: _ArrowPainter(color: toColor.withValues(alpha: 0.5)),
              ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn(duration: 200.ms);
  }
}

/// Custom painter for arrow head.
class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

/// Simplified throw card for connected arrows layout (no arrow column).
class _ConnectedThrowCard extends StatefulWidget {
  const _ConnectedThrowCard({
    required this.discThrow,
    required this.throwIndex,
    required this.animationDelay,
    required this.onEdit,
    required this.onDragStateChange,
    required this.showDragHandle,
    required this.accentColor,
  });

  final DiscThrow discThrow;
  final int throwIndex;
  final int animationDelay;
  final VoidCallback onEdit;
  final void Function(bool isDragging) onDragStateChange;
  final bool showDragHandle;
  final Color accentColor;

  @override
  State<_ConnectedThrowCard> createState() => _ConnectedThrowCardState();
}

class _ConnectedThrowCardState extends State<_ConnectedThrowCard> {
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
