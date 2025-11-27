import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Description card (larger) with unified background and subtle amber tint.
class VoiceDescriptionCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isListening;
  final Color accent;
  final VoidCallback? onClear;

  const VoiceDescriptionCard({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isListening,
    required this.accent,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Colors.grey.shade50;

    return Container(
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: flattenedOverWhite(accent, 0.5)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            flattenedOverWhite(accent, 0.3),
            Colors.white, // Fade to white at bottom right
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // title row with circular icon (matching _InfoCard)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Colors.white, accent.withValues(alpha: 0.04)],
                    stops: const [0.6, 1.0],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.08), // Colored shadow
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(Icons.note, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Text(
                'Round Description',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (isListening)
                Row(
                  children: [
                    const Icon(Icons.mic, size: 16, color: Color(0xFF2196F3)),
                    const SizedBox(width: 6),
                    Text(
                      'Listening',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
              if (!isListening && onClear != null && controller.text.isNotEmpty)
                TextButton(
                  onPressed: onClear,
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // text field area (transparent background so it inherits the card color)
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
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
    );
  }
}
