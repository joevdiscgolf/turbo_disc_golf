import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';

class CustomExpandableSection extends StatefulWidget {
  const CustomExpandableSection({
    super.key,
    required this.child,
    required this.statusListener,
    this.expand = false,
    this.expandedInitial = false,
  });

  final Widget child;
  final Function(AnimationStatus) statusListener;
  final bool expand;
  final bool expandedInitial;

  @override
  State<CustomExpandableSection> createState() =>
      _CustomExpandableSectionState();
}

class _CustomExpandableSectionState extends State<CustomExpandableSection>
    with TickerProviderStateMixin {
  late AnimationController expandController;
  late Animation<double> animation;

  late bool _animationControllerNeedsReset;

  @override
  void initState() {
    super.initState();
    prepareAnimations();
    _animationControllerNeedsReset = widget.expandedInitial;
    if (!widget.expandedInitial) {
      _runExpandCheck();
    }
  }

  ///Setting up the animation
  void prepareAnimations({bool isReset = false}) {
    if (isReset) {
      expandController.dispose();
    }
    expandController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        )..addStatusListener(
          (AnimationStatus status) => widget.statusListener(status),
        );
    final double begin;
    final double end;
    if (widget.expandedInitial && !isReset) {
      begin = 1;
      end = 0;
    } else {
      begin = 0;
      end = 1;
    }
    animation = Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: expandController,
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeInQuart,
      ),
    );
  }

  void _runExpandCheck() {
    if (_animationControllerNeedsReset) {
      setState(() {
        prepareAnimations(isReset: true);
        _animationControllerNeedsReset = false;
      });
    }
    if (widget.expand) {
      expandController.forward();
    } else {
      expandController.reverse();
    }
  }

  @override
  void didUpdateWidget(CustomExpandableSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expand != widget.expand) {
      _runExpandCheck();
    }
  }

  @override
  void dispose() {
    expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      axisAlignment: 1.0,
      sizeFactor: animation,
      child: widget.child,
    );
  }
}

class CustomExpandableCard extends StatefulWidget {
  const CustomExpandableCard({
    super.key,
    required this.expandedWidget,
    required this.child,
    this.cardColor,
    this.horizontalPadding = 0,
  });

  final Widget expandedWidget;
  final Widget child;
  final Color? cardColor;
  final double horizontalPadding;

  @override
  State<CustomExpandableCard> createState() => _CustomExpandableCardState();
}

class _CustomExpandableCardState extends State<CustomExpandableCard> {
  bool _expandedVisible = false;
  bool _expand = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.child,

        if (_expandedVisible)
          CustomExpandableSection(
            expand: _expand,
            child: widget.expandedWidget,
            statusListener: (AnimationStatus status) =>
                _animationStatusListener(status),
          ),
        Container(
          margin: EdgeInsets.only(
            left: widget.horizontalPadding,
            right: widget.horizontalPadding,
          ),

          alignment: Alignment.bottomCenter,
          color: widget.cardColor,
          child: CustomExpandableArrow(
            expand: _expand,
            onTap: (bool expand) => _arrowListener(expand),
          ),
        ),
      ],
    );
  }

  void _animationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _expandedVisible) {
      setState(() {
        _expandedVisible = false;
      });
    }
  }

  void _arrowListener(bool updatedExpandState) {
    if (!_expand && updatedExpandState) {
      setState(() {
        _expandedVisible = true;
      });
    }
    setState(() => _expand = updatedExpandState);
  }
}

class CustomExpandableArrow extends StatefulWidget {
  const CustomExpandableArrow({
    super.key,
    required this.expand,
    required this.onTap,
  });

  final bool expand;
  final Function(bool) onTap;

  @override
  State<CustomExpandableArrow> createState() => _CustomExpandableArrowState();
}

class _CustomExpandableArrowState extends State<CustomExpandableArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    prepareAnimations();
    _runExpandCheck();
  }

  ///Setting up the animation
  void prepareAnimations() {
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInQuart,
    );
  }

  void _runExpandCheck() {
    if (widget.expand) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  void didUpdateWidget(CustomExpandableArrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _runExpandCheck();
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap(!widget.expand);
      },
      child: Container(
        padding: const EdgeInsets.only(right: 16),
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            return Transform.rotate(
              angle: _animation.value * math.pi,
              child: Icon(
                FlutterRemix.arrow_down_s_line,
                color: Color(0xFFF5F5F5),
                size: 24,
              ),
            );
          },
        ),
      ),
    );
  }
}
