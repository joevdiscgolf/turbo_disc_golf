// throw_card_v2.dart
//
// V2 throw card with compact 2-row layout.
// Row 1: Title + inline mini-chips (technique, shape, disc) + icons
// Row 2: Arrow result (distance → landing spot)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// V2 throw card with inline mini-chips and arrow result row.
class ThrowCardV2 extends StatefulWidget {
  const ThrowCardV2({
    super.key,
    required this.title,
    required this.accentColor,
    this.technique,
    this.shotShape,
    this.discName,
    this.distance,
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

  /// Distance like "350 ft" (nullable)
  final String? distance;

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
  State<ThrowCardV2> createState() => _ThrowCardV2State();
}

class _ThrowCardV2State extends State<ThrowCardV2> {
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
    // If short enough, keep full name
    if (name.length <= 12) return name;
    // Otherwise take the last word (usually the disc model)
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
        padding: const EdgeInsets.only(left: 8, right: 12, top: 4, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Title + inline mini-chips + icons
            _buildTitleRow(context),

            // Row 2: Arrow result (only if distance or landing exists)
            if (_hasResult) ...[
              const SizedBox(height: 6),
              _ArrowResultRow(
                distance: widget.distance,
                landingSpot: widget.landingSpot,
                previousLandingSpot: widget.previousLandingSpot,
                isInBasket: widget.isInBasket,
                isOutOfBounds: widget.isOutOfBounds,
                isTeeShot: widget.isTeeShot,
                accentColor: widget.accentColor,
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
    return Row(
      children: [
        // Title
        Text(
          widget.title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: HSLColor.fromColor(widget.accentColor)
                    .withLightness(
                      (HSLColor.fromColor(widget.accentColor).lightness - 0.15)
                          .clamp(0.0, 0.5),
                    )
                    .toColor(),
              ),
        ),

        // Inline mini-chips (after title, before icons)
        if (widget.technique != null) ...[
          const SizedBox(width: 6),
          _MiniChip(
            label: _abbreviateTechnique(widget.technique!),
            accentColor: widget.accentColor,
          ),
        ],
        if (widget.shotShape != null) ...[
          const SizedBox(width: 4),
          _MiniChip(
            label: widget.shotShape!,
            accentColor: widget.accentColor,
          ),
        ],
        if (widget.discName != null) ...[
          const SizedBox(width: 4),
          _MiniChip(
            label: _truncateDisc(widget.discName!),
            accentColor: widget.accentColor,
          ),
        ],

        const Spacer(),

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

/// A compact mini-chip for inline display in the title row.
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
    this.landingSpot,
    this.previousLandingSpot,
    required this.isInBasket,
    this.isOutOfBounds = false,
    required this.isTeeShot,
    required this.accentColor,
  });

  final String? distance;
  final String? landingSpot;
  final String? previousLandingSpot;
  final bool isInBasket;
  final bool isOutOfBounds;
  final bool isTeeShot;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    // Build the left side label based on available data:
    // 1. Tee shots: "Tee"
    // 2. Other throws: previous landing spot + distance if available
    String? leftLabel;
    if (isTeeShot) {
      leftLabel = 'Tee';
    } else if (previousLandingSpot != null && distance != null) {
      // Show both: "Fairway · 150 ft"
      leftLabel = '$previousLandingSpot · $distance';
    } else if (previousLandingSpot != null) {
      leftLabel = previousLandingSpot;
    } else if (distance != null) {
      leftLabel = distance;
    }

    return Row(
      children: [
        // Left side label (Tee or distance)
        if (leftLabel != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              leftLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SenseiColors.gray[600],
                    fontWeight: isTeeShot ? FontWeight.w500 : FontWeight.w400,
                  ),
            ),
          ),

        // Arrow line (flexible middle)
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.15),
                  accentColor.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),

        // Arrow head
        Icon(
          Icons.arrow_forward,
          size: 14,
          color: accentColor,
        ),

        const SizedBox(width: 8),

        // Landing spot text (right side)
        if (landingSpot != null)
          Text(
            isOutOfBounds
                ? (landingSpot == 'Hazard' ? 'HZ' : 'OB')
                : landingSpot!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isOutOfBounds
                      ? Colors.red.withValues(alpha: 0.7)
                      : SenseiColors.gray[700],
                  fontWeight: FontWeight.w600,
                ),
          ),

        // Basket checkmark
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
