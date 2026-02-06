import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/liquid_glass_card.dart';

enum SlideDirection { left, right }

class LandingPreviewCard extends StatefulWidget {
  const LandingPreviewCard({
    super.key,
    required this.child,
    required this.accentColor,
    required this.slideDirection,
    required this.animationController,
    required this.slideInterval,
    required this.floatPhaseOffset,
  });

  final Widget child;
  final Color accentColor;
  final SlideDirection slideDirection;
  final AnimationController animationController;
  final Interval slideInterval;
  final double floatPhaseOffset;

  @override
  State<LandingPreviewCard> createState() => _LandingPreviewCardState();
}

class _LandingPreviewCardState extends State<LandingPreviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Float animation controller (continuous)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Slide animation from parent controller
    final double startX =
        widget.slideDirection == SlideDirection.left ? -1.0 : 1.0;

    _slideAnimation = Tween<double>(begin: startX, end: 0.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: widget.slideInterval,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: widget.slideInterval,
      ),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.animationController, _floatController]),
      builder: (context, child) {
        // Calculate float offset using sine wave with phase offset
        final double floatOffset =
            math.sin((_floatController.value + widget.floatPhaseOffset) * math.pi * 2) * 4;

        // Only apply float after slide is complete
        final bool slideComplete = _slideAnimation.value == 0.0;
        final double effectiveFloatOffset = slideComplete ? floatOffset : 0.0;

        return Transform.translate(
          offset: Offset(
            _slideAnimation.value * MediaQuery.of(context).size.width * 0.5,
            effectiveFloatOffset,
          ),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: LiquidGlassCard(
        opacity: 0.5,
        blurSigma: 16,
        borderRadius: 20,
        borderOpacity: 0.25,
        borderColor: widget.accentColor,
        accentColor: widget.accentColor,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        padding: const EdgeInsets.all(14),
        child: Center(
          child: widget.child,
        ),
      ),
    );
  }
}
