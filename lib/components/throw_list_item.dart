import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/utils/naming_constants.dart';

class ThrowListItem extends StatelessWidget {
  final DiscThrow discThrow;
  final int throwIndex;
  final VoidCallback? onEdit;
  final bool showEditButton;
  final bool isFirst;
  final bool isLast;

  const ThrowListItem({
    super.key,
    required this.discThrow,
    required this.throwIndex,
    this.onEdit,
    this.showEditButton = true,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    BorderRadius borderRadius;
    if (isFirst && isLast) {
      borderRadius = BorderRadius.circular(12);
    } else if (isFirst) {
      borderRadius = const BorderRadius.vertical(top: Radius.circular(12));
    } else if (isLast) {
      borderRadius = const BorderRadius.vertical(bottom: Radius.circular(12));
    } else {
      borderRadius = BorderRadius.zero;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        // borderRadius: borderRadius,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            _getThrowTypeIcon(discThrow.purpose),
            color: Theme.of(context).iconTheme.color,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Throw ${throwIndex + 1}${discThrow.technique != null ? ': ${throwTechniqueToName[discThrow.technique]}' : ''}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (_buildSubtitle() != null) ...[
                  const SizedBox(height: 4),
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    child: _buildSubtitle()!,
                  ),
                ],
              ],
            ),
          ),
          if (showEditButton)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget? _buildSubtitle() {
    final List<String> subtitleParts = [];

    if (discThrow.distanceFeetBeforeThrow != null) {
      subtitleParts.add('${discThrow.distanceFeetBeforeThrow} ft');
    }

    if (discThrow.disc != null) {
      subtitleParts.add(discThrow.disc!.name);
    }

    if (discThrow.landingSpot != null) {
      subtitleParts.add(landingSpotToName[discThrow.landingSpot] ?? '');
    }

    if (subtitleParts.isEmpty) return null;

    return Text(subtitleParts.join(' • '));
  }

  IconData _getThrowTypeIcon(ThrowPurpose? type) {
    switch (type) {
      case ThrowPurpose.teeDrive:
        return Icons.sports_golf;
      case ThrowPurpose.fairwayDrive:
        return Icons.trending_flat;
      case ThrowPurpose.approach:
        return Icons.call_made;
      case ThrowPurpose.putt:
        return Icons.flag;
      case ThrowPurpose.scramble:
        return Icons.refresh;
      case ThrowPurpose.penalty:
        return Icons.warning;
      case ThrowPurpose.other:
        return Icons.sports;
      default:
        return Icons.sports;
    }
  }
}
