import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/footers/form_footer.dart';
import 'package:turbo_disc_golf/components/panels/panel_header.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/course/course_data.dart';
import 'package:turbo_disc_golf/screens/create_course/components/holes_section.dart';
import 'package:turbo_disc_golf/screens/create_course/components/layout_info_section.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/toast/toast_service.dart';
import 'package:turbo_disc_golf/state/create_layout_cubit.dart';
import 'package:turbo_disc_golf/state/create_layout_state.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Bottom sheet / modal for creating or editing a course layout.
/// Used for adding new layouts to existing courses or editing existing layouts.
class CreateLayoutScreen extends StatefulWidget {
  const CreateLayoutScreen({
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
  State<CreateLayoutScreen> createState() => _CreateLayoutScreenState();
}

class _CreateLayoutScreenState extends State<CreateLayoutScreen> {
  static const String _sheetName = 'Create Layout';

  late final CreateLayoutCubit _createLayoutCubit;
  late final LoggingServiceBase _logger;
  late final Set<String> _existingLayoutNames;

  bool get _isEditMode => widget.existingLayout != null;

  /// Checks if the given layout name conflicts with existing layouts
  bool _hasNameConflict(String layoutName) {
    final String normalizedName = layoutName.toLowerCase().trim();
    if (normalizedName.isEmpty) return false;
    return _existingLayoutNames.contains(normalizedName);
  }

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

    // Build set of existing layout names (excluding the one being edited)
    _existingLayoutNames = widget.course.layouts
        .where((layout) => layout.id != widget.existingLayout?.id)
        .map((layout) => layout.name.toLowerCase().trim())
        .toSet();

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
        resizeToAvoidBottomInset: false,
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
                          child: LayoutInfoSection(
                            headerTitle: 'Layout',
                            layoutName: state.layoutName,
                            numberOfHoles: state.numberOfHoles,
                            hasNameConflict: _hasNameConflict(
                              state.layoutName,
                            ),
                            onLayoutNameChanged:
                                _createLayoutCubit.updateLayoutName,
                            onHoleCountChanged:
                                _createLayoutCubit.updateHoleCount,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(
                            height: 32,
                            color: SenseiColors.gray.shade100,
                            thickness: 1,
                          ),
                        ),
                        HolesSection(
                          holes: state.holes,
                          isParsingImage: state.isParsingImage,
                          parseError: state.parseError,
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
    final bool hasConflict = _hasNameConflict(state.layoutName);
    final bool canSave = state.canSave && !hasConflict;

    return FormFooter(
      label: _isEditMode ? 'Save layout' : 'Create layout',
      canSave: canSave,
      onPressed: () {
        final CourseLayout layout = _createLayoutCubit.buildLayout();

        // Call parent callback
        widget.onLayoutSaved(layout);

        // Show success message
        locator.get<ToastService>().showSuccess(
          _isEditMode ? 'Layout updated' : 'Layout "${layout.name}" created!',
        );

        // Close the sheet
        Navigator.of(context).pop();
      },
    );
  }
}
