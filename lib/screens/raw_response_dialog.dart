import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RawResponseDialog extends StatelessWidget {
  final String rawResponse;

  const RawResponseDialog({super.key, required this.rawResponse});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: const Text('Raw Gemini Response')),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: rawResponse));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            tooltip: 'Copy to clipboard',
          ),
        ],
      ),
      content: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: SingleChildScrollView(
          child: SelectableText(
            rawResponse,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
