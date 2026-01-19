import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';

/// Bottom sheet panel for selecting image source (gallery or camera)
class SelectImageSourcePanel extends StatelessWidget {
  const SelectImageSourcePanel({super.key});

  static Future<ImageSource?> show(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const SelectImageSourcePanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      locator.get<LoggingService>().track('Modal Opened', properties: {
        'modal_type': 'bottom_sheet',
        'modal_name': 'Select Image Source',
      });
    });

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PanelHeader(
            title: 'Select image source',
            onClose: () => Navigator.of(context).pop(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryButton(
                  width: double.infinity,
                  label: 'Choose from Gallery',
                  icon: Icons.photo_library,
                  onPressed: () {
                    locator.get<LoggingService>().track(
                      'Gallery Image Source Selected',
                    );
                    Navigator.pop(context, ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  width: double.infinity,
                  label: 'Take a Photo',
                  icon: Icons.camera_alt,
                  onPressed: () {
                    locator.get<LoggingService>().track(
                      'Camera Image Source Selected',
                    );
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
