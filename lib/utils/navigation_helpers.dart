import 'package:flutter/cupertino.dart';

Future<void> pushCupertinoRoute(
  BuildContext context,
  Widget screen, {
  bool pushFromBottom = false,
}) {
  return Navigator.push(
    context,
    CupertinoPageRoute(
      fullscreenDialog: pushFromBottom,
      builder: (context) => screen,
    ),
  );
}
