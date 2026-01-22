import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';

class AllMistakesCard extends StatefulWidget {
  final List<Map<String, dynamic>> mistakeDetails;

  const AllMistakesCard({
    super.key,
    required this.mistakeDetails,
  });

  @override
  State<AllMistakesCard> createState() => _AllMistakesCardState();
}

class _AllMistakesCardState extends State<AllMistakesCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.mistakeDetails.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (_isExpanded) _buildExpandedContent(),
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
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'View all mistakes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          ...widget.mistakeDetails.map((mistake) {
            return _buildMistakeListItem(context, mistake);
          }),
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
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(
        context,
      ).colorScheme.errorContainer.withValues(alpha: 0.2),
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
