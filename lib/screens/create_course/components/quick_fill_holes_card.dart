import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/state/create_course_cubit.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class QuickFillHolesCard extends StatefulWidget {
  const QuickFillHolesCard({super.key});

  @override
  State<QuickFillHolesCard> createState() => _QuickFillHolesCardState();
}

class _QuickFillHolesCardState extends State<QuickFillHolesCard> {
  int quickFillPar = 3;
  int quickFillFeet = 300;
  HoleType quickFillType = HoleType.open;

  @override
  Widget build(BuildContext context) {
    return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  flattenedOverWhite(const Color(0xFF64B5F6), 0.10),
                  flattenedOverWhite(const Color(0xFF1565C0), 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text(
                  'Quick Fill',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Set default values for all holes',
                  style: TextStyle(fontSize: 12),
                ),
                initiallyExpanded: false,
                backgroundColor: Colors.transparent,
                collapsedBackgroundColor: Colors.transparent,
                iconColor: Colors.grey,
                collapsedIconColor: Colors.grey,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TextFormField(
                                  initialValue: quickFillPar.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Par',
                                    contentPadding: EdgeInsets.fromLTRB(
                                      12,
                                      8,
                                      12,
                                      8,
                                    ),
                                  ),
                                  onChanged: (v) {
                                    final int? parsed = int.tryParse(v);
                                    if (parsed != null) {
                                      setState(() {
                                        quickFillPar = parsed;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TextFormField(
                                  initialValue: quickFillFeet.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Distance (ft)',
                                    contentPadding: EdgeInsets.fromLTRB(
                                      12,
                                      8,
                                      12,
                                      8,
                                    ),
                                  ),
                                  onChanged: (v) {
                                    final int? parsed = int.tryParse(v);
                                    if (parsed != null) {
                                      setState(() {
                                        quickFillFeet = parsed;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<HoleType>(
                          initialValue: quickFillType,
                          decoration: const InputDecoration(
                            labelText: 'Hole Type',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: HoleType.open,
                              child: Text('🌳 Open'),
                            ),
                            DropdownMenuItem(
                              value: HoleType.slightlyWooded,
                              child: Text('🌲 Moderate'),
                            ),
                            DropdownMenuItem(
                              value: HoleType.wooded,
                              child: Text('🌲🌲 Wooded'),
                            ),
                          ],
                          onChanged: (HoleType? value) {
                            if (value != null) {
                              setState(() {
                                quickFillType = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          width: double.infinity,
                          label: 'Apply to All Holes',
                          onPressed: () {
                            BlocProvider.of<CreateCourseCubit>(
                              context,
                            ).applyDefaultsToAllHoles(
                              defaultPar: quickFillPar,
                              defaultFeet: quickFillFeet,
                              defaultType: quickFillType,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Applied defaults to all holes'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
  }
}
