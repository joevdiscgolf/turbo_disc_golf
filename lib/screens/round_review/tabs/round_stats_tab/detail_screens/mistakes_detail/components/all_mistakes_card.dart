import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

class AllMistakesCard extends StatefulWidget {
  final List<Map<String, dynamic>> mistakeDetails;

  const AllMistakesCard({super.key, required this.mistakeDetails});

  @override
  State<AllMistakesCard> createState() => _AllMistakesCardState();
}

class _AllMistakesCardState extends State<AllMistakesCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mistakeDetails.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surface,
      elevation: defaultCardElevation,
      shadowColor: defaultCardShadowColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          ClipRect(
            child: SizeTransition(
              axisAlignment: -1,
              sizeFactor: _animationController,
              child: _buildExpandedContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _isExpanded = !_isExpanded;
        });
        if (_isExpanded) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'All mistakes',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          ...addRunSpacing(
            widget.mistakeDetails.map((mistake) {
              return _buildMistakeListItem(context, mistake);
            }).toList(),
            axis: Axis.vertical,
            runSpacing: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildMistakeListItem(
    BuildContext context,
    Map<String, dynamic> mistake,
  ) {
    final int holeNumber = mistake['holeNumber'];
    final int throwIndex = mistake['throwIndex'];
    final DiscThrow discThrow = mistake['throw'];
    final String label = mistake['label'];

    final List<String> subtitleParts = [];
    subtitleParts.add('Shot ${throwIndex + 1}');
    if (discThrow.distanceFeetBeforeThrow != null) {
      subtitleParts.add('${discThrow.distanceFeetBeforeThrow} ft');
    }

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: flattenedOverWhite(Color(0xFFFF7A7A), 0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFF7A7A),
          child: Text(
            '$holeNumber',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitleParts.join(' • ')),
      ),
    );
  }
}
