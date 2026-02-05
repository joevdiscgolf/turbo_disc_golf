import 'dart:async';

import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/services/toast/toast_type.dart';

class ToastAction {
  final String label;
  final VoidCallback onPressed;

  const ToastAction({required this.label, required this.onPressed});
}

class ToastOverlay extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final ToastAction? action;
  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;
  final VoidCallback onDismiss;

  const ToastOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
    this.action,
    this.icon,
    this.iconSize,
    this.iconColor,
    super.key,
  });

  @override
  State<ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeOut,
          ),
        );

    _animationController.forward();
    _startAutoDismissTimer();
  }

  void _startAutoDismissTimer() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    _autoDismissTimer?.cancel();
    await _animationController.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final IconData? iconToShow = widget.icon;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: _dismiss,
          onVerticalDragEnd: (DragEndDetails details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < 0) {
              _dismiss();
            }
          },
          child: Container(
            margin: EdgeInsets.only(top: topPadding + 8, left: 16, right: 16),
            alignment: Alignment.center,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: iconToShow != null ? 20 : 16,
                  top: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  color: widget.type.backgroundColor,
                  borderRadius: BorderRadius.circular(48),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (iconToShow != null) ...[
                      Icon(
                        iconToShow,
                        color: widget.iconColor ?? widget.type.textColor,
                        size: widget.iconSize ?? 22,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.message,
                          maxLines: 1,
                          style: TextStyle(
                            color: widget.type.textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    if (widget.action != null) ...[
                      const SizedBox(width: 8),
                      _buildActionButton(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return TextButton(
      onPressed: () {
        widget.action?.onPressed();
        _dismiss();
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        widget.action!.label,
        style: TextStyle(
          color: widget.type.textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: widget.type.textColor,
        ),
      ),
    );
  }
}
