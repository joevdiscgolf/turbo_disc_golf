// throw_card_v3_inline.dart
//
// V3 inline throw card with full-width layout and inline number badge.
// Design:
// ┌──────────────────────────────────────────────────────────┐
// │ ①  Tee shot   [Flex shot] [Destroyer]          ✎    ≡  │
// │     Tee ──────────────────────────────────▶ Fairway     │
// └──────────────────────────────────────────────────────────┘

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// V3 inline throw card with full-width layout and inline number badge.
class ThrowCardV3Inline extends StatefulWidget {
  const ThrowCardV3Inline({
    super.key,
    required this.throwNumber,
    required this.title,
    required this.accentColor,
    this.technique,
    this.shotShape,
    this.discName,
    this.distance,
    this.distanceAfter,
    this.landingSpot,
    this.previousLandingSpot,
    required this.isInBasket,
    this.isOutOfBounds = false,
    required this.isTeeShot,
    required this.animationDelay,
    required this.onEdit,
    required this.onDragStateChange,
    required this.showDragHandle,
    required this.visualIndex,
  });

  /// The throw number (1-indexed) to display in the badge
  final int throwNumber;

  /// Title like "Tee shot", "Approach", "Putt"
  final String title;

  /// Purpose-based accent color
  final Color accentColor;

  /// Technique like "Backhand", "Forehand" (nullable)
  final String? technique;

  /// Shot shape like "Hyzer", "Anhyzer" (nullable)
  final String? shotShape;

  /// Disc name like "Star Destroyer" (nullable)
  final String? discName;

  /// Distance before throw like "350 ft" (nullable)
  final String? distance;

  /// Distance after throw like "25 ft" (nullable) - shown on right side
  final String? distanceAfter;

  /// Landing spot like "Fairway", "Circle 1", "Basket" (nullable)
  final String? landingSpot;

  /// Previous throw's landing spot (used as starting location for non-tee shots)
  final String? previousLandingSpot;

  /// Whether the throw landed in the basket (shows checkmark)
  final bool isInBasket;

  /// Whether the throw went out of bounds (shows red border)
  final bool isOutOfBounds;

  /// Whether this is a tee shot (shows "Tee" on left of arrow)
  final bool isTeeShot;

  /// Animation delay in milliseconds
  final int animationDelay;

  /// Called when card is tapped for editing
  final VoidCallback onEdit;

  /// Called when drag state changes
  final void Function(bool isDragging) onDragStateChange;

  /// Whether to show the drag handle
  final bool showDragHandle;

  /// The index for reorderable list
  final int visualIndex;

  @override
  State<ThrowCardV3Inline> createState() => _ThrowCardV3InlineState();
}

class _ThrowCardV3InlineState extends State<ThrowCardV3Inline> {
  bool _isDraggingLocal = false;

  void _handleLocalDragState(bool dragging) {
    if (_isDraggingLocal == dragging) return;
    setState(() => _isDraggingLocal = dragging);
    widget.onDragStateChange(dragging);
    HapticFeedback.lightImpact();
  }

  bool get _hasResult =>
      widget.distance != null ||
      widget.landingSpot != null ||
      widget.previousLandingSpot != null ||
      widget.isTeeShot;

  /// Abbreviate technique to all-caps short form
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

  /// Truncate long disc names to just the model name
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
            color: widget.isOutOfBounds
                ? Colors.red.withValues(alpha: 0.6)
                : widget.accentColor.withValues(alpha: 0.28),
            width: widget.isOutOfBounds ? 1.5 : 1,
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
        padding: const EdgeInsets.only(left: 10, right: 12, top: 8, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Number badge + Title + chips + icons
            _buildTitleRow(context),

            // Row 2: Arrow result (always on separate line)
            if (_hasResult) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: _ArrowResultRow(
                  distance: widget.distance,
                  distanceAfter: widget.distanceAfter,
                  landingSpot: widget.landingSpot,
                  previousLandingSpot: widget.previousLandingSpot,
                  isInBasket: widget.isInBasket,
                  isOutOfBounds: widget.isOutOfBounds,
                  isTeeShot: widget.isTeeShot,
                  accentColor: widget.accentColor,
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

  Widget _buildTitleRow(BuildContext context) {
    final Color badgeColor = widget.isOutOfBounds
        ? Colors.red.withValues(alpha: 0.7)
        : widget.accentColor;

    final TextStyle titleStyle =
        Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w600,
              color: HSLColor.fromColor(widget.accentColor)
                  .withLightness(
                    (HSLColor.fromColor(widget.accentColor).lightness - 0.15)
                        .clamp(0.0, 0.5),
                  )
                  .toColor(),
            );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Number badge (20x20)
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: badgeColor, width: 1.5),
          ),
          child: Center(
            child: Text(
              '${widget.throwNumber}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Title + chips (inline, wrap if needed)
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(widget.title, style: titleStyle),
              if (widget.technique != null)
                _MiniChip(
                  label: _abbreviateTechnique(widget.technique!),
                  accentColor: widget.accentColor,
                ),
              if (widget.shotShape != null)
                _MiniChip(
                  label: widget.shotShape!,
                  accentColor: widget.accentColor,
                ),
              if (widget.discName != null)
                _MiniChip(
                  label: _truncateDisc(widget.discName!),
                  accentColor: widget.accentColor,
                ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Edit icon
        Icon(
          Icons.edit_outlined,
          size: 18,
          color: SenseiColors.gray[600],
        ),

        // Drag handle (if enabled)
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
                  color: SenseiColors.gray[600],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A compact mini-chip for inline display.
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

/// Arrow row showing: [starting location] ───────────► landing spot [✓]
class _ArrowResultRow extends StatelessWidget {
  const _ArrowResultRow({
    this.distance,
    this.distanceAfter,
    this.landingSpot,
    this.previousLandingSpot,
    required this.isInBasket,
    this.isOutOfBounds = false,
    required this.isTeeShot,
    required this.accentColor,
  });

  final String? distance;
  final String? distanceAfter;
  final String? landingSpot;
  final String? previousLandingSpot;
  final bool isInBasket;
  final bool isOutOfBounds;
  final bool isTeeShot;
  final Color accentColor;

  /// Abbreviate location names for compact display
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
      default:
        return location;
    }
  }

  @override
  Widget build(BuildContext context) {
    String? leftLabel;
    if (isTeeShot) {
      leftLabel = 'Tee';
    } else if (previousLandingSpot != null && distance != null) {
      leftLabel = '${_abbreviateLocation(previousLandingSpot!)} · $distance';
    } else if (previousLandingSpot != null) {
      leftLabel = _abbreviateLocation(previousLandingSpot!);
    } else if (distance != null) {
      leftLabel = distance;
    }

    String? rightLabel;
    if (isOutOfBounds && landingSpot != null) {
      rightLabel = landingSpot == 'Hazard' ? 'HZ' : 'OB';
    } else if (isInBasket && landingSpot != null) {
      rightLabel = _abbreviateLocation(landingSpot!);
    } else if (distanceAfter != null) {
      rightLabel = distanceAfter;
    } else if (landingSpot != null) {
      rightLabel = _abbreviateLocation(landingSpot!);
    }

    final TextStyle labelStyle =
        Theme.of(context).textTheme.bodySmall!.copyWith(
              color: SenseiColors.gray[600],
              fontWeight: FontWeight.w500,
            );

    return Row(
      children: [
        if (leftLabel != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(leftLabel, style: labelStyle),
          ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CustomPaint(
              size: const Size(double.infinity, 12),
              painter: _ArrowLinePainter(color: accentColor),
            ),
          ),
        ),

        const SizedBox(width: 8),

        if (rightLabel != null)
          Text(
            rightLabel,
            style: labelStyle.copyWith(
              color: isOutOfBounds
                  ? Colors.red.withValues(alpha: 0.7)
                  : SenseiColors.gray[600],
            ),
          ),

        if (isInBasket) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.green.shade600,
          ),
        ],
      ],
    );
  }
}

/// Custom painter for drawing a line with an arrowhead at the end.
class _ArrowLinePainter extends CustomPainter {
  const _ArrowLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double centerY = size.height / 2;
    const double arrowSize = 5.0;

    final Path linePath = Path()
      ..moveTo(0, centerY)
      ..lineTo(size.width - arrowSize, centerY);
    canvas.drawPath(linePath, paint);

    final Paint arrowPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final Path arrowPath = Path()
      ..moveTo(size.width - arrowSize - 4, centerY - 4)
      ..lineTo(size.width, centerY)
      ..lineTo(size.width - arrowSize - 4, centerY + 4)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _ArrowLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
