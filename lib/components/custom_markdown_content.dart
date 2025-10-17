import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class CustomMarkdownContent extends StatelessWidget {
  const CustomMarkdownContent({
    super.key,
    required this.data,
    this.bodyPadding = const EdgeInsets.only(bottom: 4, top: 4),
    this.isChat = false,
  });

  final String data;
  final EdgeInsets bodyPadding;
  final bool isChat;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      styleSheet: isChat
          ? _getChatMarkdownStyleSheet(context)
          : _getMarkdownStyleSheet(context),
      styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
      // onTapLink: (text, href, title) {
      //   if (href != null) {
      //     launchUrl(Uri.parse(href));
      //   }
      // },
    );
  }

  MarkdownStyleSheet _getChatMarkdownStyleSheet(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    const EdgeInsets headingPadding = EdgeInsets.only(bottom: 0, top: 0);
    const EdgeInsets subHeadingPadding = EdgeInsets.only(bottom: 0, top: 8);

    final TextStyle bodyStyle = Theme.of(context).textTheme.titleMedium!
        .copyWith(color: Theme.of(context).colorScheme.onSurface, height: 1.45);
    return MarkdownStyleSheet(
      h1: themeData.textTheme.headlineSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        height: 1.35,
      ),
      h1Padding: headingPadding,
      h2: themeData.textTheme.headlineSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        height: 1.35,
      ),
      h2Padding: headingPadding,
      h3: themeData.textTheme.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        height: 1.35,
      ),
      h3Padding: headingPadding,
      h4: themeData.textTheme.titleLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
      h4Padding: subHeadingPadding,
      h5: themeData.textTheme.titleLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
      h5Padding: subHeadingPadding,
      h6: themeData.textTheme.titleLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
      h6Padding: subHeadingPadding,
      p: bodyStyle,
      pPadding: bodyPadding,
      listBullet: bodyStyle,
      a: bodyStyle.copyWith(
        color: Colors.blue,
        decoration: TextDecoration.underline,
        decorationColor: Colors.blue,
      ),
      code: themeData.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        backgroundColor: Theme.of(context).colorScheme.surface,
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.3,
      ),
      codeblockPadding: const EdgeInsets.all(12),
      codeblockDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      blockquote: themeData.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        backgroundColor: Theme.of(context).colorScheme.surface,
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.3,
      ),
      blockquotePadding: const EdgeInsets.all(12),
      blockquoteDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      checkbox: bodyStyle,
      tableHead: bodyStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      tableBody: bodyStyle.copyWith(fontSize: 12),
      tableBorder: TableBorder.all(
        color: Theme.of(context).colorScheme.onSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      tableCellsPadding: const EdgeInsets.all(10),
    );
  }

  MarkdownStyleSheet _getMarkdownStyleSheet(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    const EdgeInsets headingPadding = EdgeInsets.only(bottom: 4, top: 20);
    const EdgeInsets subHeadingPadding = EdgeInsets.only(bottom: 4, top: 16);
    return MarkdownStyleSheet(
      h1: themeData.textTheme.headlineSmall?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h1Padding: headingPadding,
      h2: themeData.textTheme.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        height: 1.5,
      ),
      h2Padding: subHeadingPadding,
      h3: themeData.textTheme.headlineSmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.5,
      ),
      h3Padding: subHeadingPadding,
      h4: themeData.textTheme.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.5,
      ),
      h4Padding: subHeadingPadding,
      h5: themeData.textTheme.titleLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
      ),
      h5Padding: subHeadingPadding,
      h6: themeData.textTheme.titleLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
      ),
      h6Padding: subHeadingPadding,
      p: themeData.textTheme.bodyMedium?.copyWith(
        fontSize: 18,
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.6,
      ),
      pPadding: bodyPadding,
      listBullet: themeData.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.6,
      ),
      a: themeData.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: Colors.blue,
        decoration: TextDecoration.underline,
        decorationColor: Colors.blue,
      ),
    );
  }
}
