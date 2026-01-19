import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/screens/create_course/components/holes_section.dart';
import 'package:turbo_disc_golf/screens/create_course/components/layout_info_section.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/state/create_layout_cubit.dart';
import 'package:turbo_disc_golf/state/create_layout_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Bottom sheet / modal for creating or editing a course layout.
/// Used for adding new layouts to existing courses or editing existing layouts.
class CreateLayoutSheet extends StatefulWidget {
  const CreateLayoutSheet({
    super.key,
    required this.course,
    required this.onLayoutSaved,
    required this.topViewPadding,
    required this.bottomViewPadding,
    this.existingLayout,
  });

  /// The course this layout belongs to
  final Course course;

  /// Optional existing layout for edit mode
  final CourseLayout? existingLayout;

  /// Callback when a layout is saved (created or edited)
  final void Function(CourseLayout layout) onLayoutSaved;

  final double topViewPadding;
  final double bottomViewPadding;

  @override
  State<CreateLayoutSheet> createState() => _CreateLayoutSheetState();
}

class _CreateLayoutSheetState extends State<CreateLayoutSheet> {
  static const String _sheetName = 'Create Layout';

  late final CreateLayoutCubit _createLayoutCubit;
  late final LoggingServiceBase _logger;

  bool get _isEditMode => widget.existingLayout != null;

  @override
  void initState() {
    super.initState();

    // Setup scoped logger
    final LoggingService loggingService = locator.get<LoggingService>();
    _logger = loggingService.withBaseProperties({'sheet_name': _sheetName});

    // Track modal opened
    _logger.track(
      'Modal Opened',
      properties: {
        'modal_type': 'full_screen_modal',
        'modal_name': _isEditMode ? 'Edit Layout' : 'Create Layout',
        'course_name': widget.course.name,
        'is_edit_mode': _isEditMode,
      },
    );

    // Create cubit based on mode (create vs edit)
    if (widget.existingLayout != null) {
      _createLayoutCubit = CreateLayoutCubit.fromLayout(widget.existingLayout!);
    } else {
      _createLayoutCubit = CreateLayoutCubit();
    }
  }

  @override
  void dispose() {
    _createLayoutCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateLayoutCubit>.value(
      value: _createLayoutCubit,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: GenericAppBar(
          topViewPadding: widget.topViewPadding,
          title: _isEditMode ? 'Edit layout' : 'Create layout',
          rightWidget: IconButton(
            icon: const Icon(
              Icons.close,
              size: PanelConstants.closeButtonIconSize,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
          hasBackButton: false,
        ),
        body: BlocBuilder<CreateLayoutCubit, CreateLayoutState>(
          builder: (context, state) {
            return GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Column(
                children: [
                  // Scrollable content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(top: 12, bottom: 48),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LayoutInfoSection(
                                headerTitle: 'Layout',
                                layoutName: state.layoutName,
                                numberOfHoles: state.numberOfHoles,
                                isParsingImage: state.isParsingImage,
                                parseError: state.parseError,
                                onLayoutNameChanged:
                                    _createLayoutCubit.updateLayoutName,
                                onHoleCountChanged:
                                    _createLayoutCubit.updateHoleCount,
                                onParseImage: () async {
                                  HapticFeedback.lightImpact();
                                  FocusScope.of(context).unfocus();
                                  await Future.delayed(
                                    const Duration(milliseconds: 300),
                                  );
                                  if (context.mounted) {
                                    _createLayoutCubit.pickAndParseImage(
                                      context,
                                    );
                                  }
                                },
                              ),
                              Divider(
                                height: 32,
                                color: SenseiColors.gray.shade100,
                                thickness: 1,
                              ),
                              HolesSection(
                                holes: state.holes,
                                onApplyDefaults:
                                    _createLayoutCubit.applyDefaultsToAllHoles,
                                onHoleParChanged:
                                    _createLayoutCubit.updateHolePar,
                                onHoleFeetChanged:
                                    _createLayoutCubit.updateHoleFeet,
                                onHoleTypeChanged:
                                    _createLayoutCubit.updateHoleType,
                                onHoleShapeChanged:
                                    _createLayoutCubit.updateHoleShape,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Fixed bottom footer
                  _buildFooter(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, CreateLayoutState state) {
    final bool canSave = state.canSave;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: PrimaryButton(
        width: double.infinity,
        height: 56,
        label: _isEditMode ? 'Save Layout' : 'Create Layout',
        gradientBackground: canSave
            ? const [Color(0xFF137e66), Color(0xFF1a9f7f)]
            : null,
        backgroundColor: canSave
            ? Colors.transparent
            : SenseiColors.gray.shade200,
        labelColor: canSave ? Colors.white : SenseiColors.gray.shade400,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        disabled: !canSave,
        onPressed: () {
          final CourseLayout layout = _createLayoutCubit.buildLayout();

          // Call parent callback
          widget.onLayoutSaved(layout);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode
                    ? 'Layout "${layout.name}" updated!'
                    : 'Layout "${layout.name}" created!',
              ),
            ),
          );

          // Close the sheet
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
