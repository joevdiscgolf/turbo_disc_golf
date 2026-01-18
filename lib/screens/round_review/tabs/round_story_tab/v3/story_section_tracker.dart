import 'dart:math';

import 'package:flutter/material.dart';

class StorySectionTracker {
  StorySectionTracker({
    required this.scrollController,
    required this.sectionKeys,
    ValueNotifier<int?>? activeSectionNotifier,
  }) : activeSectionIndex = activeSectionNotifier ?? ValueNotifier(null),
       _shouldDisposeNotifier = activeSectionNotifier == null {
    scrollController.addListener(_onScroll);
  }

  final ScrollController scrollController;
  final List<GlobalKey> sectionKeys;
  final ValueNotifier<int?> activeSectionIndex;
  final bool _shouldDisposeNotifier;

  DateTime? _lastUpdate;

  void _onScroll() {
    // Throttle updates to every 150ms
    final now = DateTime.now();
    if (_lastUpdate != null &&
        now.difference(_lastUpdate!) < const Duration(milliseconds: 150)) {
      return;
    }
    _lastUpdate = now;

    final int? newActiveIndex = _findMostVisibleSection();

    // Don't update if we're overscrolling and would lose selection
    // This prevents jumping when bouncing at top/bottom
    if (newActiveIndex == null && activeSectionIndex.value != null) {
      final double scrollPosition = scrollController.position.pixels;
      final double minScroll = scrollController.position.minScrollExtent;
      final double maxScroll = scrollController.position.maxScrollExtent;

      // If overscrolling at top or bottom, keep current selection
      if (scrollPosition <= minScroll || scrollPosition >= maxScroll) {
        return; // Keep existing selection
      }
    }

    if (newActiveIndex != activeSectionIndex.value) {
      activeSectionIndex.value = newActiveIndex;
    }
  }

  int? _findMostVisibleSection() {
    if (sectionKeys.isEmpty) return null;

    // If at the very top, always select first section
    final double scrollPosition = scrollController.position.pixels;
    final double minScroll = scrollController.position.minScrollExtent;
    final double maxScroll = scrollController.position.maxScrollExtent;

    if (scrollPosition <= minScroll + 10) {
      return 0; // Always select first section when at/near top
    }

    if (scrollPosition >= maxScroll - 10) {
      return sectionKeys.length - 1; // Always select last section when at/near bottom
    }

    double maxVisibleHeight = 0;
    int? mostVisibleIndex;

    final double viewportHeight =
        scrollController.position.viewportDimension;

    for (int i = 0; i < sectionKeys.length; i++) {
      final RenderBox? renderBox = sectionKeys[i]
          .currentContext?.findRenderObject() as RenderBox?;

      if (renderBox == null) continue;

      // Get section position relative to screen
      final Offset position = renderBox.localToGlobal(Offset.zero);
      final Size size = renderBox.size;

      // Calculate visible portion within viewport
      final double sectionTop = position.dy;
      final double sectionBottom = position.dy + size.height;

      final double visibleTop = max(sectionTop, 0.0);
      final double visibleBottom = min(sectionBottom, viewportHeight);
      final double visibleHeight = max(0.0, visibleBottom - visibleTop);

      if (visibleHeight > maxVisibleHeight) {
        maxVisibleHeight = visibleHeight;
        mostVisibleIndex = i;
      }
    }

    return mostVisibleIndex;
  }

  void dispose() {
    scrollController.removeListener(_onScroll);
    if (_shouldDisposeNotifier) {
      activeSectionIndex.dispose();
    }
  }
}
