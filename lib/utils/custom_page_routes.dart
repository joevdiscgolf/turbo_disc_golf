import 'package:flutter/material.dart';

/// Custom page route with a smooth zoom-in transition.
///
/// The new page scales up from 0.8 to 1.0 while fading in, and the old page
/// fades out. This creates a satisfying "blooming" effect where the round
/// review appears to emerge and grow from the loading screen.
class ZoomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  ZoomPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 600),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Curved animation for smooth easing
            final CurvedAnimation curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
              reverseCurve: Curves.easeInOutCubic,
            );

            // Scale animation: zooms from 0.85 to 1.0
            final Animation<double> scaleAnimation = Tween<double>(
              begin: 0.85,
              end: 1.0,
            ).animate(curvedAnimation);

            // Fade animation: fades in from 0 to 1
            final Animation<double> fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curvedAnimation);

            // Secondary page (old page) fade out
            final Animation<double> secondaryFadeAnimation = Tween<double>(
              begin: 1.0,
              end: 0.0,
            ).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeOut,
              ),
            );

            return Stack(
              children: [
                // Old page fading out
                if (secondaryAnimation.value > 0)
                  FadeTransition(
                    opacity: secondaryFadeAnimation,
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),

                // New page zooming in and fading in
                FadeTransition(
                  opacity: fadeAnimation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    child: child,
                  ),
                ),
              ],
            );
          },
        );
}

/// Custom page route that expands from a banner at the bottom and shrinks back.
///
/// The new page expands from the bottom banner position and fills the screen,
/// and when dismissed, shrinks back down to the banner. Works with Hero animation.
class ShrinkToBottomPageRoute<T> extends PageRoute<T> {
  ShrinkToBottomPageRoute({
    required this.builder,
    super.settings,
    this.transitionDuration = const Duration(milliseconds: 400),
    this.reverseTransitionDuration = const Duration(milliseconds: 350),
  });

  final WidgetBuilder builder;

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;

  @override
  Color? get barrierColor => Colors.black54;

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
    // Use different curves for opening and closing
    final Animation<double> curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Scale animation - starts small at bottom, expands to full screen
    final Animation<double> scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curvedAnimation);

    // Vertical position animation - starts at bottom
    final Animation<Offset> slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.15), // Start slightly from bottom
      end: Offset.zero, // End at normal position
    ).animate(curvedAnimation);

    // Fade animation for smoother appearance
    final Animation<double> fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      reverseCurve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    ));

    return SlideTransition(
      position: slideAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        alignment: Alignment.bottomCenter,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      ),
    );
  }
}
