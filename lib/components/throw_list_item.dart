import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/utils/naming_constants.dart';

class ThrowListItem extends StatelessWidget {
  final DiscThrow discThrow;
  final int throwIndex;
  final VoidCallback? onEdit;
  final bool showEditButton;

  const ThrowListItem({
    super.key,
    required this.discThrow,
    required this.throwIndex,
    this.onEdit,
    this.showEditButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_getThrowTypeIcon(discThrow.purpose)),
      title: Text(
        'Throw ${throwIndex + 1}${discThrow.technique != null ? ': ${throwTechniqueToName[discThrow.technique]}' : ''}',
      ),
      subtitle: _buildSubtitle(),
      trailing: showEditButton
          ? IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            )
          : null,
    );
  }

  Widget? _buildSubtitle() {
    final List<String> subtitleParts = [];

    if (discThrow.distanceFeet != null) {
      subtitleParts.add('${discThrow.distanceFeet} ft');
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
