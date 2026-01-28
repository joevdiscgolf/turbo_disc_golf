import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const defaultIosStyle = SystemUiOverlayStyle(
  statusBarBrightness: Brightness.light, // iOS = black icons
);

class StatusBarStyleScope extends InheritedWidget {
  final SystemUiOverlayStyle style;

  const StatusBarStyleScope({
    super.key,
    required this.style,
    required super.child,
  });

  static SystemUiOverlayStyle? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<StatusBarStyleScope>()
        ?.style;
  }

  @override
  bool updateShouldNotify(StatusBarStyleScope oldWidget) =>
      style != oldWidget.style;
}

class StatusBarObserver extends NavigatorObserver {
  void _apply(Route<dynamic>? route) {
    // Get the context for the navigator that owns this route.
    final navCtx = route?.navigator?.context;
    if (navCtx == null) return;

    // Default.
    var style = defaultIosStyle;

    // If the current route subtree provides a style, use it.
    final provided = StatusBarStyleScope.maybeOf(navCtx);
    if (provided != null) style = provided;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(style);
    });
  }

  @override
  void didPush(Route route, Route? previousRoute) => _apply(route);

  @override
  void didPop(Route route, Route? previousRoute) => _apply(previousRoute);

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => _apply(newRoute);
}
