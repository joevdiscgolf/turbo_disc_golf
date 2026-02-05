import 'package:flutter/material.dart';

/// Renders a widget off-screen (still painted, but not visible) for image capture.
///
/// This widget solves the problem of needing to capture a widget as an image
/// without displaying it to the user. It works by:
/// 1. Translating the widget vertically off-screen (below the viewport)
/// 2. Wrapping in [IgnorePointer] to prevent accidental touch interactions
/// 3. Using [RepaintBoundary] to isolate the widget for efficient capture
///
/// **Why this approach?**
/// - `Offstage` doesn't work: it skips painting entirely, so nothing to capture
/// - `Visibility(visible: false)` doesn't work: same reason
/// - `Opacity(opacity: 0)` doesn't work: paints transparent pixels
/// - Off-screen translation works: widget is painted but outside visible viewport
///
/// **Why vertical offset instead of horizontal?**
/// - Horizontal tab transitions can briefly reveal horizontally-offset widgets
/// - Vertical offset (below screen) is safe from horizontal animations
///
/// ## Usage
///
/// ```dart
/// final GlobalKey _captureKey = GlobalKey();
///
/// // Add to your widget tree (works anywhere, doesn't need Stack):
/// OffscreenCaptureTarget(
///   captureKey: _captureKey,
///   child: ShareableComposite(...),
/// )
///
/// // To capture:
/// await ShareService.captureAndShare(_captureKey, ...);
/// ```
class OffscreenCaptureTarget extends StatelessWidget {
  const OffscreenCaptureTarget({
    super.key,
    required this.captureKey,
    required this.child,
    this.size,
  });

  /// Key used for image capture via [RenderRepaintBoundary.toImage].
  final GlobalKey captureKey;

  /// The widget to capture. Typically a [ShareableComposite].
  final Widget child;

  /// Capture dimensions. Defaults to screen size for full-resolution output.
  final Size? size;

  @override
  Widget build(BuildContext context) {
    final Size captureSize = size ?? MediaQuery.of(context).size;

    return IgnorePointer(
      child: Transform.translate(
        // Move off-screen vertically (2x height below visible area)
        // Using vertical offset prevents visibility during horizontal tab transitions
        offset: Offset(0, captureSize.height * 2),
        child: RepaintBoundary(
          key: captureKey,
          child: SizedBox(
            width: captureSize.width,
            height: captureSize.height,
            child: child,
          ),
        ),
      ),
    );
  }
}
