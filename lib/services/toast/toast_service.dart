import 'dart:collection';

import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/services/toast/toast_overlay.dart';
import 'package:turbo_disc_golf/services/toast/toast_type.dart';

class _ToastRequest {
  final String message;
  final ToastType type;
  final Duration duration;
  final ToastAction? action;
  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;

  const _ToastRequest({
    required this.message,
    required this.type,
    required this.duration,
    this.action,
    this.icon,
    this.iconSize,
    this.iconColor,
  });
}

class ToastService {
  GlobalKey<OverlayState>? _overlayKey;
  OverlayEntry? _currentEntry;
  final Queue<_ToastRequest> _queue = Queue<_ToastRequest>();
  bool _isShowing = false;

  void initialize(GlobalKey<OverlayState> overlayKey) {
    _overlayKey = overlayKey;
  }

  void show({
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    ToastAction? action,
    IconData? icon,
    double? iconSize,
    Color? iconColor,
  }) {
    _queue.add(
      _ToastRequest(
        message: message,
        type: type,
        duration: duration,
        action: action,
        icon: icon,
        iconSize: iconSize,
        iconColor: iconColor,
      ),
    );

    _processQueue();
  }

  void showSuccess(String message, {bool showIcon = true, double iconSize = 18}) {
    show(
      message: message,
      type: ToastType.success,
      icon: showIcon ? Icons.check : null,
      iconSize: iconSize,
      iconColor: Colors.lightGreen[300],
    );
  }

  void showError(String message, {bool showIcon = true, double iconSize = 18}) {
    show(
      message: message,
      type: ToastType.error,
      duration: const Duration(seconds: 4),
      icon: showIcon ? Icons.warning : null,
      iconSize: iconSize,
      iconColor: Colors.red[300],
    );
  }

  void showInfo(String message) {
    show(message: message, type: ToastType.info);
  }

  void showWarning(String message) {
    show(message: message, type: ToastType.warning);
  }

  void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
    _isShowing = false;
    _processQueue();
  }

  void _processQueue() {
    if (_isShowing || _queue.isEmpty) {
      return;
    }

    final OverlayState? overlayState = _overlayKey?.currentState;
    if (overlayState == null) {
      debugPrint('[ToastService] OverlayState not available');
      return;
    }

    _isShowing = true;
    final _ToastRequest request = _queue.removeFirst();

    _currentEntry = OverlayEntry(
      builder: (BuildContext context) => ToastOverlay(
        message: request.message,
        type: request.type,
        duration: request.duration,
        action: request.action,
        icon: request.icon,
        iconSize: request.iconSize,
        iconColor: request.iconColor,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
          _isShowing = false;
          _processQueue();
        },
      ),
    );

    overlayState.insert(_currentEntry!);
  }
}
