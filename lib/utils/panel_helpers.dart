import 'package:flutter/material.dart' hide ModalBottomSheetRoute;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart'
    as modal_bottom_sheet;
import 'package:turbo_disc_golf/utils/color_helpers.dart';

void displayBottomSheet(
  BuildContext context,
  Widget panel, {
  bool backgroundBarrierColor = true,
  Duration duration = const Duration(milliseconds: 200),
  Function? onDismiss,
  bool dismissibleOnTap = true,
  bool enableDrag = true,
}) {
  modal_bottom_sheet
      .showBarModalBottomSheet(
        barrierColor: backgroundBarrierColor
            ? TurbColors.gray[800]!.withValues(alpha: 0.8)
            : Colors.transparent,
        context: context,
        duration: duration,
        enableDrag: enableDrag,
        isDismissible: dismissibleOnTap,
        topControl: Container(),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        builder: (BuildContext context) => panel,
      )
      .then((_) {
        if (onDismiss != null) {
          onDismiss();
        }
      });
}
