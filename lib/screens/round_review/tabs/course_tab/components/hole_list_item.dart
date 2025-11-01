import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/throw_list_item.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';

class HoleListItem extends StatelessWidget {
  const HoleListItem({
    super.key,
    required this.hole,
    this.showAddThrowDialog,
    this.isFirst = false,
    this.isLast = false,
  });

  final DGHole hole;
  final Function()? showAddThrowDialog;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: _getDecoration(context),
      child: ExpansionTile(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hole ${hole.number}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Par ${hole.par} • ${hole.feet} ft',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _buildScoreIndicator(
              context,
              hole.relativeHoleScore,
              hole.holeScore,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildThrowListItems(hole),
                // Add throw button
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        try {
                          if (showAddThrowDialog != null) {
                            showAddThrowDialog!();
                          }
                        } catch (e) {
                          debugPrint(e.toString());
                        }
                      },
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Add Throw'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _getDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.only(
        topLeft: isFirst ? Radius.circular(12) : Radius.zero,
        topRight: isFirst ? Radius.circular(12) : Radius.zero,
        bottomLeft: isLast ? Radius.circular(12) : Radius.zero,
        bottomRight: isLast ? Radius.circular(12) : Radius.zero,
      ),
    );
  }

  Widget _buildScoreIndicator(BuildContext context, int score, int holeScore) {
    Color circleColor;
    if (score == 0) {
      circleColor = Theme.of(context).colorScheme.surface;
    } else if (score < 0) {
      circleColor = const Color(0xFF137e66); // Birdie - green
    } else if (score == 1) {
      circleColor = const Color(0xFFFF7A7A); // Bogey - light red
    } else {
      circleColor = const Color(0xFFD32F2F); // Double bogey+ - dark red
    }

    // Return score in colored circle
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
      child: Center(
        child: Text(
          '$holeScore',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: score == 0 ? null : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildThrowListItems(DGHole hole) {
    final List<Widget> widgets = [];

    for (int i = 0; i < hole.throws.length; i++) {
      widgets.add(
        ThrowListItem(
          discThrow: hole.throws[i],
          throwIndex: i,
          isFirst: i == 0,
          isLast: i == hole.throws.length - 1,
          onEdit: () {
            // todo: Implement throw editing
          },
        ),
      );

      // Add divider after each item except the last one
      if (i < hole.throws.length - 1) {
        widgets.add(
          const Divider(
            indent: 16,
            endIndent: 16,
            height: 1,
            color: Colors.grey,
          ),
        );
      }
    }

    return widgets;
  }
}
