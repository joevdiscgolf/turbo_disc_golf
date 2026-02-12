import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/models/pose_model.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Panel for selecting pose detection mode (standard, advanced, or professional).
/// Displayed as a bottom sheet with card options.
class PoseModelSelectionPanel extends StatelessWidget {
  const PoseModelSelectionPanel({super.key, required this.onSelected});

  final Function(PoseModel poseModel) onSelected;

  /// Shows the panel as a modal bottom sheet.
  /// Returns the selected [PoseModel], or null if dismissed without selection.
  static Future<PoseModel?> show(BuildContext context) {
    return showModalBottomSheet<PoseModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PoseModelSelectionPanel(
        onSelected: (poseModel) => Navigator.pop(context, poseModel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PanelConstants.panelBorderRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: autoBottomPadding(context),
            ),
            child: Column(
              children: [
                _buildPoseModelCard(context: context, poseModel: PoseModel.standard),
                const SizedBox(height: 8),
                _buildPoseModelCard(context: context, poseModel: PoseModel.advanced),
                const SizedBox(height: 8),
                _buildPoseModelCard(context: context, poseModel: PoseModel.professional),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Precision mode',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[600]),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPoseModelCard({
    required BuildContext context,
    required PoseModel poseModel,
  }) {
    // Gradient colors from the enum (matches handedness selector pattern)
    final Color color1 = poseModel.color;
    final Color color2 = poseModel.lightColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onSelected(poseModel);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color1, color2],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: poseModel.color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(poseModel.icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poseModel.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    poseModel.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
