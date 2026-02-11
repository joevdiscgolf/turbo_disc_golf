import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';

/// Generic education panel that can display educational content in a modal bottom sheet.
/// Flexible content structure to support various types of educational materials.
class EducationPanel extends StatefulWidget {
  const EducationPanel({
    super.key,
    required this.title,
    required this.contentBuilder,
    this.bottomViewPadding = 0,
    this.accentColor = const Color(0xFF7E57C2),
    this.buttonLabel = 'Got it!',
    this.modalName = 'Education Panel',
    this.isFirstTimeDisplay = false,
  });

  final String title;
  final Widget Function(BuildContext context) contentBuilder;
  final double bottomViewPadding;
  final Color accentColor;
  final String buttonLabel;
  final String modalName;

  /// When true, the close button is hidden and the primary button starts
  /// disabled until the user has scrolled to the bottom (if scrolling is
  /// required) and a 300ms delay has passed.
  final bool isFirstTimeDisplay;

  /// Shows this panel as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required Widget Function(BuildContext context) contentBuilder,
    Color accentColor = const Color(0xFF7E57C2),
    String buttonLabel = 'Got it!',
    String modalName = 'Education Panel',
    bool isFirstTimeDisplay = false,
  }) async {
    // Track modal opened
    locator.get<LoggingService>().track('Modal Opened', properties: {
      'modal_type': 'bottom_sheet',
      'modal_name': modalName,
    });

    HapticFeedback.lightImpact();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: !isFirstTimeDisplay,
      enableDrag: !isFirstTimeDisplay,
      builder: (context) => EducationPanel(
        title: title,
        contentBuilder: contentBuilder,
        bottomViewPadding: MediaQuery.of(context).viewPadding.bottom,
        accentColor: accentColor,
        buttonLabel: buttonLabel,
        modalName: modalName,
        isFirstTimeDisplay: isFirstTimeDisplay,
      ),
    );
  }

  @override
  State<EducationPanel> createState() => _EducationPanelState();
}

class _EducationPanelState extends State<EducationPanel> {
  final ScrollController _scrollController = ScrollController();
  bool _buttonEnabled = false;
  bool _hasCheckedScrollRequirement = false;
  Timer? _enableTimer;

  @override
  void initState() {
    super.initState();

    // If not first time display, button is enabled immediately
    if (!widget.isFirstTimeDisplay) {
      _buttonEnabled = true;
    } else {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _enableTimer?.cancel();
    super.dispose();
  }

  void _checkScrollRequirement() {
    if (_hasCheckedScrollRequirement || !widget.isFirstTimeDisplay) return;
    _hasCheckedScrollRequirement = true;

    // Check if scrolling is required
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final double maxScrollExtent = _scrollController.position.maxScrollExtent;
      if (maxScrollExtent <= 0) {
        // No scrolling required, start the delay immediately
        _startEnableTimer();
      }
    });
  }

  void _onScroll() {
    if (_buttonEnabled || !widget.isFirstTimeDisplay) return;

    final double maxScrollExtent = _scrollController.position.maxScrollExtent;
    final double currentScroll = _scrollController.position.pixels;

    // Check if scrolled to bottom (with small tolerance)
    if (currentScroll >= maxScrollExtent - 10) {
      _startEnableTimer();
    }
  }

  void _startEnableTimer() {
    if (_enableTimer != null) return;

    _enableTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _buttonEnabled = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PanelHeader(
            title: widget.title,
            showCloseButton: !widget.isFirstTimeDisplay,
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (!_hasCheckedScrollRequirement) {
                  _checkScrollRequirement();
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.contentBuilder(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomButton(context),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + widget.bottomViewPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: PrimaryButton(
        label: widget.buttonLabel,
        width: double.infinity,
        height: 56,
        backgroundColor: _buttonEnabled
            ? widget.accentColor
            : widget.accentColor.withValues(alpha: 0.5),
        labelColor: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        disabled: !_buttonEnabled,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
