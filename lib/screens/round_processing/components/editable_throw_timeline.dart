// editable_throw_timeline.dart
//
// Editable timeline where only throw cards are reorderable.
// Add buttons are visually centered between cards (Option A), anchored
// while dragging, and the throw cards move around them.
// Drag handle is inside the card (right side). Card keeps rounded corners
// while dragging but removes shadow while in drag state.
// Uses flutter_animate for subtle entry animations and uses purpose colors.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/throw_card_v2.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/throw_card_v3_inline.dart';
import 'package:turbo_disc_golf/screens/round_processing/components/throw_card_v3_split.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
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

  /// Get the current throw card layout style from feature flags
  String get _layoutStyle =>
      locator.get<FeatureFlagService>().throwCardLayoutStyle;

  /// Whether we're using a V3 layout (no external timeline)
  bool get _isV3Layout =>
      _layoutStyle == 'inline' || _layoutStyle == 'split';

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
        final box =
            _itemKeys[i].currentContext?.findRenderObject() as RenderBox?;
        if (box == null) {
          iconCenters.add(0.0);
        } else {
          final globalTopLeft = box.localToGlobal(Offset.zero);
          // Icon is positioned at top of row with some padding
          // Icon center is approximately at top + 16px (icon radius)
          final iconCenterGlobalY = globalTopLeft.dy + 16.0;
          final iconCenterLocalY = listBox
              .globalToLocal(Offset(0, iconCenterGlobalY))
              .dy;
          iconCenters.add(iconCenterLocalY);
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
                    final purposeColor = _getPurposeColorForThrow(discThrow);

                    // Get previous throw's landing spot for the starting location
                    String? previousLandingSpot;
                    if (index > 0) {
                      final prevThrow = widget.throws[index - 1];
                      if (prevThrow.landingSpot != null) {
                        previousLandingSpot =
                            landingSpotToName[prevThrow.landingSpot];
                      }
                    }

                    // Infer distance after: if the NEXT throw has distanceBefore,
                    // that's where THIS throw ended up
                    int? inferredDistanceAfter = discThrow.distanceFeetAfterThrow;
                    if (inferredDistanceAfter == null &&
                        index < widget.throws.length - 1) {
                      final nextThrow = widget.throws[index + 1];
                      inferredDistanceAfter = nextThrow.distanceFeetBeforeThrow;
                    }

                    // Infer distance before: PREVIOUS throw's distanceAfter is
                    // the authority (where we landed = where next throw starts)
                    int? inferredDistanceBefore = discThrow.distanceFeetBeforeThrow;
                    if (index > 0) {
                      final prevThrow = widget.throws[index - 1];
                      // Previous throw's distanceAfter takes precedence
                      if (prevThrow.distanceFeetAfterThrow != null) {
                        inferredDistanceBefore = prevThrow.distanceFeetAfterThrow;
                      }
                    }

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
                        accentColor: purposeColor,
                        previousLandingSpot: previousLandingSpot,
                        inferredDistanceBefore: inferredDistanceBefore,
                        inferredDistanceAfter: inferredDistanceAfter,
                        isOutOfBounds: discThrow.landingSpot == LandingSpot.outOfBounds ||
                            discThrow.landingSpot == LandingSpot.hazard,
                        layoutStyle: _layoutStyle,
                      ),
                    );
                  },
                ),
              ),

              // Overlay connectors between icons (only for non-V3 layouts)
              if (!_isV3Layout && _iconCenterY.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      children: [
                        for (int i = 0; i < _iconCenterY.length - 1; i++)
                          Builder(
                            builder: (ctx) {
                              const double iconRadius =
                                  16.0; // Icon is 32px diameter
                              // Start at bottom of top icon, end at top of bottom icon
                              final startY = _iconCenterY[i] + iconRadius;
                              final endY = _iconCenterY[i + 1] - iconRadius;
                              final height = (endY - startY).clamp(
                                0.0,
                                double.infinity,
                              );
                              final discThrow = widget.throws[i];
                              final color = _getPurposeColorForThrow(discThrow);

                              return Positioned(
                                left:
                                    37, // Center line on icon (16px padding + 22px to icon center - 1px for 2px line width)
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
                            left:
                                (constraints.maxWidth / 2) -
                                16, // Center horizontally (32px button / 2)
                            top:
                                _addButtonY[i] -
                                16, // Center vertically (32px button / 2)
                            child: GestureDetector(
                              onTap: () => widget.onAddThrowAt(i),
                              child: _AnchoredAddButton(
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

  Color _getPurposeColorForThrow(DiscThrow discThrow) {
    switch (discThrow.purpose) {
      case ThrowPurpose.teeDrive:
      case ThrowPurpose.fairwayDrive:
        return const Color(0xFF5C6BC0); // Indigo - confident start
      case ThrowPurpose.approach:
        return const Color(0xFF2196F3); // Blue - transitional
      case ThrowPurpose.putt:
        return const Color(0xFF66BB6A); // Soft green - finishing
      case ThrowPurpose.scramble:
      case ThrowPurpose.other:
      default:
        return const Color(0xFF78909C); // Slate - neutral
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
    this.previousLandingSpot,
    this.inferredDistanceBefore,
    this.inferredDistanceAfter,
    this.isOutOfBounds = false,
    this.layoutStyle = '',
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
  final String? previousLandingSpot;
  final int? inferredDistanceBefore;
  final int? inferredDistanceAfter;
  final bool isOutOfBounds;

  /// Layout style: 'inline', 'split', or empty for default
  final String layoutStyle;

  String _getThrowTitle() {
    if (discThrow.purpose != null) {
      return throwPurposeToName[discThrow.purpose] ?? 'Throw ${throwIndex + 1}';
    }
    return 'Throw ${throwIndex + 1}';
  }

  List<String> _getThrowDetails() {
    final List<String> details = [];
    // Add technique (if available)
    if (discThrow.technique != null) {
      details.add(throwTechniqueToName[discThrow.technique] ?? '');
    }
    // Add shot shape after technique (related "how" info)
    if (discThrow.shotShape != null) {
      details.add(shotShapeToName[discThrow.shotShape] ?? '');
    }
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
    // V3 layouts: no external number circle, card is full-width
    if (layoutStyle == 'inline') {
      return _buildV3InlineCard(context);
    }
    if (layoutStyle == 'split') {
      return _buildV3SplitCard(context);
    }

    // Legacy layouts with external number circle
    final bool useV2 = locator.get<FeatureFlagService>().useThrowCardV2;
    if (useV2) {
      return _buildV2Card(context);
    }
    return _buildV1Card(context);
  }

  Widget _buildV1Card(BuildContext context) {
    final purposeColor = accentColor;
    final details = _getThrowDetails();

    return Container(
      key: measurementKey,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNumberCircle(),
            const SizedBox(width: 12),
            Expanded(
              child: _ThrowCard(
                title: _getThrowTitle(),
                details: details,
                accentColor: purposeColor,
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

  Widget _buildV2Card(BuildContext context) {
    return Container(
      key: measurementKey,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNumberCircle(),
            const SizedBox(width: 12),
            Expanded(
              child: ThrowCardV2(
                title: _getThrowTitle(),
                accentColor: accentColor,
                technique: discThrow.technique != null
                    ? throwTechniqueToName[discThrow.technique]
                    : null,
                shotShape: discThrow.shotShape != null
                    ? shotShapeToName[discThrow.shotShape]
                    : null,
                discName: discThrow.disc?.name ?? discThrow.discName,
                distance: inferredDistanceBefore != null
                    ? '$inferredDistanceBefore ft'
                    : null,
                distanceAfter: inferredDistanceAfter != null
                    ? '$inferredDistanceAfter ft'
                    : null,
                landingSpot: discThrow.landingSpot != null
                    ? landingSpotToName[discThrow.landingSpot]
                    : null,
                // Only show previous landing spot if exact distance before isn't available
                previousLandingSpot: inferredDistanceBefore == null
                    ? previousLandingSpot
                    : null,
                isInBasket: discThrow.landingSpot == LandingSpot.inBasket,
                isOutOfBounds: isOutOfBounds,
                isTeeShot: discThrow.purpose == ThrowPurpose.teeDrive,
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

  /// V3 inline layout - full-width card with inline number badge
  Widget _buildV3InlineCard(BuildContext context) {
    return Container(
      key: measurementKey,
      child: ThrowCardV3Inline(
        throwNumber: throwIndex + 1,
        title: _getThrowTitle(),
        accentColor: accentColor,
        technique: discThrow.technique != null
            ? throwTechniqueToName[discThrow.technique]
            : null,
        shotShape: discThrow.shotShape != null
            ? shotShapeToName[discThrow.shotShape]
            : null,
        discName: discThrow.disc?.name ?? discThrow.discName,
        distance: inferredDistanceBefore != null
            ? '$inferredDistanceBefore ft'
            : null,
        distanceAfter: inferredDistanceAfter != null
            ? '$inferredDistanceAfter ft'
            : null,
        landingSpot: discThrow.landingSpot != null
            ? landingSpotToName[discThrow.landingSpot]
            : null,
        previousLandingSpot: inferredDistanceBefore == null
            ? previousLandingSpot
            : null,
        isInBasket: discThrow.landingSpot == LandingSpot.inBasket,
        isOutOfBounds: isOutOfBounds,
        isTeeShot: discThrow.purpose == ThrowPurpose.teeDrive,
        animationDelay: animationDelay,
        onEdit: onEdit,
        onDragStateChange: onDragStateChange,
        showDragHandle: showDragHandle,
        visualIndex: throwIndex,
      ),
    );
  }

  /// V3 split layout - left-right split with number in gutter
  Widget _buildV3SplitCard(BuildContext context) {
    return Container(
      key: measurementKey,
      child: ThrowCardV3Split(
        throwNumber: throwIndex + 1,
        title: _getThrowTitle(),
        accentColor: accentColor,
        technique: discThrow.technique != null
            ? throwTechniqueToName[discThrow.technique]
            : null,
        shotShape: discThrow.shotShape != null
            ? shotShapeToName[discThrow.shotShape]
            : null,
        discName: discThrow.disc?.name ?? discThrow.discName,
        distance: inferredDistanceBefore != null
            ? '$inferredDistanceBefore ft'
            : null,
        distanceAfter: inferredDistanceAfter != null
            ? '$inferredDistanceAfter ft'
            : null,
        landingSpot: discThrow.landingSpot != null
            ? landingSpotToName[discThrow.landingSpot]
            : null,
        previousLandingSpot: inferredDistanceBefore == null
            ? previousLandingSpot
            : null,
        isInBasket: discThrow.landingSpot == LandingSpot.inBasket,
        isOutOfBounds: isOutOfBounds,
        isTeeShot: discThrow.purpose == ThrowPurpose.teeDrive,
        animationDelay: animationDelay,
        onEdit: onEdit,
        onDragStateChange: onDragStateChange,
        showDragHandle: showDragHandle,
        visualIndex: throwIndex,
      ),
    );
  }

  Widget _buildNumberCircle() {
    final Color circleColor = isOutOfBounds
        ? Colors.red.withValues(alpha: 0.7)
        : accentColor;
    return SizedBox(
      width: 44,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: circleColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: circleColor, width: 2),
            ),
            child: Center(
              child: Text(
                '${throwIndex + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: circleColor,
                ),
              ),
            ),
          ),
          // Spacer to create space for the overlay connector
          if (!isLast) Expanded(child: Container()),
        ],
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
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onEdit();
      },
      child:
          Container(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
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
                              // Darken accent color for better contrast against white
                              color: HSLColor.fromColor(widget.accentColor)
                                  .withLightness(
                                    (HSLColor.fromColor(
                                              widget.accentColor,
                                            ).lightness -
                                            0.15)
                                        .clamp(0.0, 0.5),
                                  )
                                  .toColor(),
                            ),
                          ),
                          if (widget.details.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.details.join(' • '),
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

                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: SenseiColors.gray[600],
                    ),

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

/// Anchored add button UI (32x32 circular) — colorable if you want.
class _AnchoredAddButton extends StatelessWidget {
  const _AnchoredAddButton({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? SenseiColors.blue;
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
