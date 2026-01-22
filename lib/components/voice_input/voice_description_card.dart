import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Description card with clean shadow-based depth styling.
class VoiceDescriptionCard extends StatefulWidget {
  const VoiceDescriptionCard({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isListening,
    required this.accent,
    this.onClear,
    required this.isSingleHole,
    this.onHelpTap,
    this.height,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isListening;
  final Color accent;
  final VoidCallback? onClear;
  final bool isSingleHole;

  /// Callback when the help icon is tapped.
  /// If provided, a help icon will be shown next to the title.
  final VoidCallback? onHelpTap;

  /// Optional fixed height for the card. If null, uses minHeight constraint of 200.
  final double? height;

  @override
  State<VoiceDescriptionCard> createState() => _VoiceDescriptionCardState();
}

class _VoiceDescriptionCardState extends State<VoiceDescriptionCard> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    widget.controller.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scrollToBottom);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Use a post-frame callback to ensure the scroll happens after the text is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.focusNode.requestFocus(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: widget.height ?? 200,
            maxHeight: widget.height ?? double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // title row
              SizedBox(
                height: 36,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${widget.isSingleHole ? 'Hole' : 'Round'} description',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.onHelpTap != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onHelpTap!();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.help_outline,
                            size: 18,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (widget.isListening)
                      Row(
                        children: [
                          const Icon(
                            Icons.mic,
                            size: 16,
                            color: Color(0xFF2196F3),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Listening',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF2196F3)),
                          ),
                        ],
                      ),
                    if (!widget.isListening &&
                        widget.onClear != null &&
                        widget.controller.text.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          widget.onClear!();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(60, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Clear',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // text field area (transparent background so it inherits the card color)
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  scrollController: _scrollController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  cursorColor: const Color(0xFF2196F3),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Speak to fill this in, or type manually',
                    hintStyle: TextStyle(fontSize: 15, color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
