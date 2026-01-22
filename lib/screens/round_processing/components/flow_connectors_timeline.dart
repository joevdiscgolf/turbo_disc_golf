// flow_connectors_timeline.dart
//
// "Flow Connectors" style timeline with curved bridges between cards.
// Result info (distance + landing spot) appears ON the connector,
// creating a visual "flight path" metaphor.
//
// Visual design:
// ┌───────────────────────────────────────────────────────────┐
// │  1  │ Tee shot              │ [BH] [Destroyer]     │  ✎ ≡ │
// └───────────────────────────────────────────────────────────┘
//        ╲
//         ╲─── 350 ft → Fairway
//          ╲
// ┌───────────────────────────────────────────────────────────┐
// │  2  │ Approach              │ [MD4]                │  ✎ ≡ │
// └───────────────────────────────────────────────────────────┘
//        ╲
//         ╲─── 45 ft → C1
//          ╲
// ┌───────────────────────────────────────────────────────────┐
// │  3  │ Putt                  │                      │  ✎ ≡ │
// └───────────────────────────────────────────────────────────┘
//        ╲
//         ╲─── 8 ft → Basket ✓

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/naming_constants.dart';

/// Flow connectors style timeline with curved bridges between cards.
class FlowConnectorsTimeline extends StatefulWidget {
  const FlowConnectorsTimeline({
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
  State<FlowConnectorsTimeline> createState() => _FlowConnectorsTimelineState();
}

class _FlowConnectorsTimelineState extends State<FlowConnectorsTimeline> {
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
  void didUpdateWidget(covariant FlowConnectorsTimeline oldWidget) {
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

                    return Container(
                      key: ValueKey('flow_throw_$index'),
                      margin: EdgeInsets.only(
                        bottom: widget.showAddButtons ? 56.0 : 6.0,
                      ),
                      child: _FlowThrowCard(
                        measurementKey: _itemKeys[index],
                        discThrow: discThrow,
                        throwIndex: index,
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

              // Flow connectors between cards
              if (_cardRects.length > 1)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _FlowConnectorPainter(
                        cardRects: _cardRects,
                        throws: widget.throws,
                        getPurposeColor: _getPurposeColorForThrow,
                      ),
                    ),
                  ),
                ),

              // Connector labels (distance → landing)
              if (_cardRects.length > 1)
                ..._buildConnectorLabels(context, constraints),

              // Add buttons on connectors
              if (widget.showAddButtons && _cardRects.length > 1)
                ..._buildAddButtons(constraints),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildConnectorLabels(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final List<Widget> labels = [];

    for (int i = 0; i < _cardRects.length - 1; i++) {
      final rect1 = _cardRects[i];
      final rect2 = _cardRects[i + 1];

      if (rect1 == Rect.zero || rect2 == Rect.zero) continue;

      final discThrow = widget.throws[i];
      final nextThrow = widget.throws[i + 1];
      final color = _getPurposeColorForThrow(discThrow);

      // Calculate connector midpoint
      final startY = rect1.bottom;
      final endY = rect2.top;
      final midY = (startY + endY) / 2;

      // Build label text
      String? distanceText;
      String? landingText;

      // Get distance (after this throw or before next throw)
      if (discThrow.distanceFeetAfterThrow != null) {
        distanceText = '${discThrow.distanceFeetAfterThrow} ft';
      } else if (nextThrow.distanceFeetBeforeThrow != null) {
        distanceText = '${nextThrow.distanceFeetBeforeThrow} ft';
      }

      // Get landing spot
      if (discThrow.landingSpot != null) {
        landingText = _abbreviateLocation(landingSpotToName[discThrow.landingSpot]!);
      }

      final bool isInBasket = discThrow.landingSpot == LandingSpot.inBasket;
      final bool isOB = discThrow.landingSpot == LandingSpot.outOfBounds ||
          discThrow.landingSpot == LandingSpot.hazard;

      labels.add(
        Positioned(
          left: 48,
          top: midY - 12,
          child: _FlowConnectorLabel(
            distanceText: distanceText,
            landingText: landingText,
            color: color,
            isInBasket: isInBasket,
            isOB: isOB,
            animationDelay: (i + 1) * 90 + 150,
          ),
        ),
      );
    }

    // Final connector to basket
    if (widget.throws.isNotEmpty &&
        widget.throws.last.landingSpot == LandingSpot.inBasket &&
        _cardRects.isNotEmpty) {
      final lastRect = _cardRects.last;
      if (lastRect != Rect.zero) {
        labels.add(
          Positioned(
            left: 48,
            top: lastRect.bottom + 12,
            child: _FlowConnectorLabel(
              landingText: 'Basket',
              color: Colors.green.shade600,
              isInBasket: true,
              isOB: false,
              animationDelay: widget.throws.length * 90 + 150,
            ),
          ),
        );
      }
    }

    return labels;
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
}

/// Custom painter for curved flow connectors.
class _FlowConnectorPainter extends CustomPainter {
  _FlowConnectorPainter({
    required this.cardRects,
    required this.throws,
    required this.getPurposeColor,
  });

  final List<Rect> cardRects;
  final List<DiscThrow> throws;
  final Color Function(DiscThrow) getPurposeColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (cardRects.length < 2) return;

    for (int i = 0; i < cardRects.length - 1; i++) {
      final rect1 = cardRects[i];
      final rect2 = cardRects[i + 1];

      if (rect1 == Rect.zero || rect2 == Rect.zero) continue;

      final color = getPurposeColor(throws[i]);
      final nextColor = getPurposeColor(throws[i + 1]);

      // Start and end points
      final startX = rect1.left + 32;
      final startY = rect1.bottom;
      final endX = rect2.left + 32;
      final endY = rect2.top;

      // Control points for bezier curve
      final midY = (startY + endY) / 2;
      final controlX = startX + 20;

      final path = Path()
        ..moveTo(startX, startY)
        ..quadraticBezierTo(
          controlX,
          midY,
          endX,
          endY,
        );

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.5),
            nextColor.withValues(alpha: 0.3),
          ],
        ).createShader(
          Rect.fromLTRB(startX, startY, endX, endY),
        )
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, paint);

      // Draw small arrow at end
      _drawArrow(canvas, Offset(endX, endY), nextColor.withValues(alpha: 0.4));
    }

    // Draw final connector to basket if applicable
    if (throws.isNotEmpty && throws.last.landingSpot == LandingSpot.inBasket) {
      final lastRect = cardRects.last;
      if (lastRect != Rect.zero) {
        final startX = lastRect.left + 32;
        final startY = lastRect.bottom;
        final endY = startY + 40;
        final color = Colors.green.shade600;

        final path = Path()
          ..moveTo(startX, startY)
          ..quadraticBezierTo(
            startX + 15,
            startY + 20,
            startX,
            endY,
          );

        final paint = Paint()
          ..color = color.withValues(alpha: 0.4)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawPath(path, paint);

        // Basket checkmark
        _drawBasketIcon(canvas, Offset(startX, endY), color);
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset point, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const size = 6.0;
    canvas.drawLine(
      point,
      Offset(point.dx - size, point.dy - size),
      paint,
    );
    canvas.drawLine(
      point,
      Offset(point.dx + size, point.dy - size),
      paint,
    );
  }

  void _drawBasketIcon(Canvas canvas, Offset center, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw a small circle with checkmark
    canvas.drawCircle(center, 8, paint);

    final checkPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw checkmark
    final checkPath = Path()
      ..moveTo(center.dx - 4, center.dy)
      ..lineTo(center.dx - 1, center.dy + 3)
      ..lineTo(center.dx + 4, center.dy - 3);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _FlowConnectorPainter oldDelegate) {
    return cardRects != oldDelegate.cardRects || throws != oldDelegate.throws;
  }
}

/// Label shown on flow connectors.
class _FlowConnectorLabel extends StatelessWidget {
  const _FlowConnectorLabel({
    this.distanceText,
    this.landingText,
    required this.color,
    required this.isInBasket,
    required this.isOB,
    required this.animationDelay,
  });

  final String? distanceText;
  final String? landingText;
  final Color color;
  final bool isInBasket;
  final bool isOB;
  final int animationDelay;

  @override
  Widget build(BuildContext context) {
    if (distanceText == null && landingText == null) {
      return const SizedBox.shrink();
    }

    Color labelColor = SenseiColors.gray[600]!;
    if (isOB) {
      labelColor = Colors.red.shade600;
    } else if (isInBasket) {
      labelColor = Colors.green.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (distanceText != null)
            Text(
              distanceText!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: SenseiColors.gray[600],
              ),
            ),
          if (distanceText != null && landingText != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.arrow_forward,
                size: 10,
                color: color.withValues(alpha: 0.5),
              ),
            ),
          if (landingText != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  landingText!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isInBasket ? FontWeight.w600 : FontWeight.w500,
                    color: labelColor,
                  ),
                ),
                if (isInBasket) ...[
                  const SizedBox(width: 2),
                  Icon(
                    Icons.check_circle,
                    size: 12,
                    color: Colors.green.shade600,
                  ),
                ],
              ],
            ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn(duration: 200.ms)
        .slideX(begin: -0.1, end: 0, duration: 200.ms, curve: Curves.easeOut);
  }
}

/// Simplified throw card for flow connectors layout.
class _FlowThrowCard extends StatefulWidget {
  const _FlowThrowCard({
    required this.measurementKey,
    required this.discThrow,
    required this.throwIndex,
    required this.animationDelay,
    required this.onEdit,
    required this.onDragStateChange,
    required this.showDragHandle,
    required this.accentColor,
  });

  final GlobalKey measurementKey;
  final DiscThrow discThrow;
  final int throwIndex;
  final int animationDelay;
  final VoidCallback onEdit;
  final void Function(bool isDragging) onDragStateChange;
  final bool showDragHandle;
  final Color accentColor;

  @override
  State<_FlowThrowCard> createState() => _FlowThrowCardState();
}

class _FlowThrowCardState extends State<_FlowThrowCard> {
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

    final Color badgeColor = isOutOfBounds
        ? Colors.red.withValues(alpha: 0.7)
        : widget.accentColor;

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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Number gutter
              Container(
                width: 36,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Text(
                    '${widget.throwIndex + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
              ),

              // Throw info
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: widget.accentColor.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
              ),

              // Icons column
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: widget.accentColor.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: SenseiColors.gray[600],
                    ),
                    if (widget.showDragHandle) ...[
                      const SizedBox(height: 4),
                      ReorderableDragStartListener(
                        index: widget.throwIndex,
                        child: Listener(
                          onPointerDown: (_) => _handleLocalDragState(true),
                          onPointerUp: (_) => _handleLocalDragState(false),
                          onPointerCancel: (_) => _handleLocalDragState(false),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(2),
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
              ),
            ],
          ),
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

/// Add button on connector.
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
