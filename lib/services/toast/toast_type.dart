import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/utils/color_helpers.dart';

enum ToastType {
  success,
  error,
  info,
  warning,
}

extension ToastTypeExtension on ToastType {
  Color get backgroundColor => SenseiColors.darkGray;

  Color get textColor => Colors.white;

  IconData get icon {
    switch (this) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.info:
        return Icons.info_outline;
      case ToastType.warning:
        return Icons.warning_amber_outlined;
    }
  }
}
