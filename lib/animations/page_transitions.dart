import 'package:flutter/material.dart';

/// Custom page route that expands from a banner at the bottom and shrinks back.
///
/// When opening: The page expands from the bottom banner position to fill the screen.
/// When closing: The page shrinks back down to the banner position.
/// Works seamlessly with Hero animations.
class BannerExpandPageRoute<T> extends PageRoute<T> {
  BannerExpandPageRoute({
    required this.builder,
    super.settings,
    this.transitionDuration = const Duration(milliseconds: 450),
    this.reverseTransitionDuration = const Duration(milliseconds: 400),
  });

  final WidgetBuilder builder;

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;

  @override
  Color? get barrierColor => Colors.black26;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Different curves for opening (forward) and closing (reverse)
    final Animation<double> curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    // Scale animation - expands from banner size to full screen
    // Using 0.92 instead of 0.0 for smoother animation that works with Hero
    final Animation<double> scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(curvedAnimation);

    // Vertical slide animation - starts from bottom
    final Animation<Offset> slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(curvedAnimation);

    // Fade animation for smooth appearance/disappearance
    final Animation<double> fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
        reverseCurve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ),
    );
  }
}
