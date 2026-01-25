import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';

import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/pdga_constants.dart';

/// A reusable panel for selecting a PDGA division.
/// Shows in a bottom sheet with search functionality.
class DivisionSelectionPanel extends StatefulWidget {
  const DivisionSelectionPanel({super.key, this.selectedDivision});

  final String? selectedDivision;

  @override
  State<DivisionSelectionPanel> createState() => _DivisionSelectionPanelState();
}

class _DivisionSelectionPanelState extends State<DivisionSelectionPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredDivisions {
    if (_searchQuery.isEmpty) return PDGADivisions.all;

    final String query = _searchQuery.toLowerCase();
    return PDGADivisions.all.where((division) {
      final String displayName = PDGADivisions.getDisplayName(
        division,
      ).toLowerCase();
      return division.toLowerCase().contains(query) ||
          displayName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        final List<String> divisions = _filteredDivisions;

        return Column(
          children: [
            PanelHeader(
              title: 'Select division',
              onClose: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search divisions...',
                  hintStyle: TextStyle(color: SenseiColors.gray[400]),
                  prefixIcon: Icon(
                    FlutterRemix.search_line,
                    color: SenseiColors.gray[400],
                    size: 20,
                  ),
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
                  filled: true,
                  fillColor: SenseiColors.gray[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: SenseiColors.gray[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: SenseiColors.gray[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Expanded(
              child: divisions.isEmpty
                  ? Center(
                      child: Text(
                        'No divisions found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SenseiColors.gray[500],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 64),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: divisions.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            thickness: 1,
                            color: SenseiColors.gray[200],
                          ),
                          itemBuilder: (context, index) {
                            final String division = divisions[index];
                            final bool isSelected =
                                division == widget.selectedDivision;

                            return DivisionListItem(
                              division: division,
                              isSelected: isSelected,
                              onTap: () => Navigator.of(context).pop(division),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// A single list item for division selection.
class DivisionListItem extends StatelessWidget {
  const DivisionListItem({
    super.key,
    required this.division,
    required this.isSelected,
    required this.onTap,
  });

  final String division;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: isSelected ? flattenedOverWhite(Colors.blue, 0.08) : null,
        child: Row(
          children: [
            Text(
              division,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.blue : SenseiColors.gray[700],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getFullName(division),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: SenseiColors.gray[400],
                ),
                overflow: TextOverflow.ellipsis,
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

  String _getFullName(String division) {
    final String displayName = PDGADivisions.getDisplayName(division);
    // Remove the division code prefix (e.g., "MPO – " from "MPO – Mixed Professional Open")
    final int dashIndex = displayName.indexOf('–');
    if (dashIndex != -1 && dashIndex + 2 < displayName.length) {
      return displayName.substring(dashIndex + 2);
    }
    return displayName;
  }
}
