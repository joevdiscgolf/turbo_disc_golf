import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/state/record_round_cubit.dart';
import 'package:turbo_disc_golf/state/record_round_state.dart';

/// Panel for selecting the number of holes in a round
class HoleCountSelectorPanel extends StatefulWidget {
  const HoleCountSelectorPanel({
    super.key,
    required this.currentHoleIndex,
    required this.onHoleCountChanged,
  });

  final int currentHoleIndex;
  final Function(int newTotalHoles, int adjustedHoleIndex) onHoleCountChanged;

  @override
  State<HoleCountSelectorPanel> createState() => _HoleCountSelectorPanelState();
}

class _HoleCountSelectorPanelState extends State<HoleCountSelectorPanel> {
  late final RecordRoundCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = BlocProvider.of<RecordRoundCubit>(context);
  }

  void _handleHoleCountSelection(int newTotalHoles) {
    _cubit.setTotalHoles(newTotalHoles);

    // Adjust current hole index if needed
    int adjustedHoleIndex = widget.currentHoleIndex;
    if (widget.currentHoleIndex >= newTotalHoles) {
      adjustedHoleIndex = newTotalHoles - 1;
    }

    widget.onHoleCountChanged(newTotalHoles, adjustedHoleIndex);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final RecordRoundActive state = _cubit.state as RecordRoundActive;
    final int currentHoleCount = state.totalHoles;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Number of Holes',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 9 holes option
              _HoleCountOption(
                holeCount: 9,
                isSelected: currentHoleCount == 9,
                onTap: () => _handleHoleCountSelection(9),
              ),
              const SizedBox(height: 8),
              // 18 holes option
              _HoleCountOption(
                holeCount: 18,
                isSelected: currentHoleCount == 18,
                onTap: () => _handleHoleCountSelection(18),
              ),
              const SizedBox(height: 8),
              // Custom option
              _CustomHoleCountOption(
                currentHoleCount: currentHoleCount,
                isCustom: currentHoleCount != 9 && currentHoleCount != 18,
                onCustomSelected: _handleHoleCountSelection,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hole count option for bottom sheet selection
class _HoleCountOption extends StatelessWidget {
  const _HoleCountOption({
    required this.holeCount,
    required this.isSelected,
    required this.onTap,
  });

  final int holeCount;
  final bool isSelected;
  final VoidCallback onTap;

  static const Color _holeAccent = Color(0xFF2196F3); // blue

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: isSelected ? _holeAccent.withValues(alpha: 0.08) : null,
      leading: Icon(
        Icons.sports_golf,
        color: isSelected ? _holeAccent : Colors.black87,
      ),
      title: Text(
        '$holeCount holes',
        style: isSelected
            ? const TextStyle(
                fontWeight: FontWeight.bold,
                color: _holeAccent,
              )
            : null,
      ),
      trailing: isSelected
          ? const Icon(
              Icons.check_circle,
              color: _holeAccent,
            )
          : null,
      onTap: onTap,
    );
  }
}

/// Custom hole count option with text field
class _CustomHoleCountOption extends StatefulWidget {
  const _CustomHoleCountOption({
    required this.currentHoleCount,
    required this.isCustom,
    required this.onCustomSelected,
  });

  final int currentHoleCount;
  final bool isCustom;
  final Function(int) onCustomSelected;

  @override
  State<_CustomHoleCountOption> createState() => _CustomHoleCountOptionState();
}

class _CustomHoleCountOptionState extends State<_CustomHoleCountOption> {
  late final TextEditingController _controller;
  bool _isEditing = false;

  static const Color _holeAccent = Color(0xFF2196F3); // blue

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.isCustom ? widget.currentHoleCount.toString() : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    final int? customCount = int.tryParse(_controller.text);
    if (customCount != null && customCount > 0 && customCount <= 99) {
      widget.onCustomSelected(customCount);
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number between 1 and 99'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: widget.isCustom && !_isEditing
          ? _holeAccent.withValues(alpha: 0.08)
          : null,
      leading: Icon(
        Icons.edit_note,
        color: widget.isCustom ? _holeAccent : Colors.black87,
      ),
      title: _isEditing
          ? Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter number',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _handleSave(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check, color: _holeAccent),
                  onPressed: _handleSave,
                ),
              ],
            )
          : Text(
              widget.isCustom
                  ? 'Custom (${widget.currentHoleCount} holes)'
                  : 'Custom',
              style: widget.isCustom
                  ? const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _holeAccent,
                    )
                  : null,
            ),
      trailing: !_isEditing && widget.isCustom
          ? const Icon(
              Icons.check_circle,
              color: _holeAccent,
            )
          : null,
      onTap: () {
        setState(() => _isEditing = true);
      },
    );
  }
}
