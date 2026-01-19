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
           final Animation<double> secondaryFadeAnimation =
               Tween<double>(begin: 1.0, end: 0.0).animate(
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
                   child: Container(color: Colors.transparent),
                 ),

               // New page zooming in and fading in
               FadeTransition(
                 opacity: fadeAnimation,
                 child: ScaleTransition(scale: scaleAnimation, child: child),
               ),
             ],
           );
         },
       );
}
