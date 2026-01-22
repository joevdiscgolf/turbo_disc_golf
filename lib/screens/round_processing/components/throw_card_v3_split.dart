// throw_card_v3_split.dart
//
// V3 split throw card with left-right layout.
// Design:
// ┌──────────────────────────────────────────────────────────────┐
// │     │ Tee shot                    │                   │  ✎  │
// │  1  │ [Flex shot] [Destroyer]     │  Tee ───▶ Fairway │  ≡  │
// └──────────────────────────────────────────────────────────────┘

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// V3 split throw card with left-right layout.
class ThrowCardV3Split extends StatefulWidget {
  const ThrowCardV3Split({
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

  /// The throw number (1-indexed) to display in the gutter
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
  State<ThrowCardV3Split> createState() => _ThrowCardV3SplitState();
}

class _ThrowCardV3SplitState extends State<ThrowCardV3Split> {
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
    final Color badgeColor = widget.isOutOfBounds
        ? Colors.red.withValues(alpha: 0.7)
        : widget.accentColor;

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
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left gutter with number
              Container(
                width: 32,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Text(
                    '${widget.throwNumber}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
              ),

              // Throw info column: title + chips
              Expanded(
                flex: 50,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
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
                  child: _buildThrowInfoColumn(context),
                ),
              ),

              // Arrow result column
              if (_hasResult)
                Expanded(
                  flex: 35,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
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
                    child: Align(
                      alignment: Alignment.center,
                      child: _CompactArrowResult(
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
                  ),
                ),

              // Icons column (stacked vertically)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: widget.accentColor.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                ),
                child: _buildIconsColumn(context),
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

  Widget _buildThrowInfoColumn(BuildContext context) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(widget.title, style: titleStyle),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
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
      ],
    );
  }

  Widget _buildIconsColumn(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Edit icon (smaller)
        Icon(
          Icons.edit_outlined,
          size: 16,
          color: SenseiColors.gray[600],
        ),

        // Drag handle below edit
        if (widget.showDragHandle) ...[
          const SizedBox(height: 4),
          ReorderableDragStartListener(
            index: widget.visualIndex,
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

/// Compact arrow result for the split layout right column.
class _CompactArrowResult extends StatelessWidget {
  const _CompactArrowResult({
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
              fontSize: 11,
            );

    // Determine right label color
    Color rightLabelColor = SenseiColors.gray[600]!;
    if (isOutOfBounds) {
      rightLabelColor = Colors.red.withValues(alpha: 0.7);
    } else if (isInBasket) {
      rightLabelColor = Colors.green.shade600;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leftLabel != null)
          Flexible(
            child: Text(
              leftLabel,
              style: labelStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Icon(
            Icons.arrow_forward,
            size: 10,
            color: accentColor.withValues(alpha: 0.6),
          ),
        ),

        if (rightLabel != null)
          Flexible(
            child: Text(
              rightLabel,
              style: labelStyle.copyWith(
                color: rightLabelColor,
                fontWeight: isInBasket ? FontWeight.w600 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
