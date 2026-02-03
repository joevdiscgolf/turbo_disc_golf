import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';

import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// A reusable panel for selecting from a list of items.
/// Shows in a bottom sheet with optional search functionality.
class GenericSelectorPanel<T> extends StatefulWidget {
  const GenericSelectorPanel({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.getDisplayName,
    required this.getId,
    required this.title,
    this.getSubtitle,
    this.searchHint,
    this.enableSearch = false,
  });

  /// List of available items to select from.
  final List<T> items;

  /// Currently selected item (can be null).
  final T? selectedItem;

  /// Function to get the display name for an item.
  final String Function(T item) getDisplayName;

  /// Optional function to get a subtitle for an item.
  final String? Function(T item)? getSubtitle;

  /// Function to get a unique identifier for an item (for comparison).
  final String Function(T item) getId;

  /// Title shown in the panel header.
  final String title;

  /// Hint text for the search field.
  final String? searchHint;

  /// Whether to show the search field.
  final bool enableSearch;

  @override
  State<GenericSelectorPanel<T>> createState() => _GenericSelectorPanelState<T>();
}

class _GenericSelectorPanelState<T> extends State<GenericSelectorPanel<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filteredItems {
    if (_searchQuery.isEmpty) return widget.items;

    final String query = _searchQuery.toLowerCase();
    return widget.items.where((item) {
      final String displayName = widget.getDisplayName(item).toLowerCase();
      final String? subtitle = widget.getSubtitle?.call(item)?.toLowerCase();
      return displayName.contains(query) ||
          (subtitle != null && subtitle.contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<T> items = _filteredItems;

    return Column(
      children: [
        PanelHeader(
          title: widget.title,
          onClose: () => Navigator.of(context).pop(),
        ),
        if (widget.enableSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.searchHint ?? 'Search...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Icon(
                          FlutterRemix.close_circle_fill,
                          color: SenseiColors.gray[400],
                          size: 20,
                        ),
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No items found',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SenseiColors.gray[500],
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: SenseiColors.gray.shade50,
                    indent: 16,
                    endIndent: 16,
                  ),
                  physics: const ClampingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final T item = items[index];
                    final String itemId = widget.getId(item);
                    final String? selectedId = widget.selectedItem != null
                        ? widget.getId(widget.selectedItem as T)
                        : null;
                    final bool isSelected = itemId == selectedId;

                    return _GenericListItem<T>(
                      item: item,
                      displayName: widget.getDisplayName(item),
                      subtitle: widget.getSubtitle?.call(item),
                      isSelected: isSelected,
                      onTap: () => Navigator.of(context).pop(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// A single list item for generic selection.
class _GenericListItem<T> extends StatelessWidget {
  const _GenericListItem({
    required this.item,
    required this.displayName,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
  });

  final T item;
  final String displayName;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.blue : SenseiColors.gray[700],
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SenseiColors.gray[400],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                FlutterRemix.checkbox_circle_fill,
                color: Colors.blue,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
