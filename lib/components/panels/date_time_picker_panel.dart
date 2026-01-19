import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';

/// A beautiful date and time picker displayed in a bottom sheet.
/// Shows a calendar for date selection and a time selector row.
class DateTimePickerPanel extends StatefulWidget {
  const DateTimePickerPanel({
    super.key,
    required this.initialDateTime,
    required this.onConfirm,
  });

  final DateTime initialDateTime;
  final ValueChanged<DateTime> onConfirm;

  /// Shows the date time picker as a modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required DateTime initialDateTime,
    required ValueChanged<DateTime> onConfirm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) => DateTimePickerPanel(
        initialDateTime: initialDateTime,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<DateTimePickerPanel> createState() => _DateTimePickerPanelState();
}

class _DateTimePickerPanelState extends State<DateTimePickerPanel> {
  late DateTime _tempDate;
  late TimeOfDay _tempTime;

  @override
  void initState() {
    super.initState();
    _tempDate = widget.initialDateTime;
    _tempTime = TimeOfDay.fromDateTime(widget.initialDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildCalendar(),
              _buildTimeSelector(),
              const SizedBox(height: 12),
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Select Date & Time',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black45),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Material(
      color: Colors.white,
      child: Theme(
        data: ThemeData(
          brightness: Brightness.light,
          canvasColor: Colors.white,
          cardColor: Colors.white,
          scaffoldBackgroundColor: Colors.white,
          primaryColor: const Color(0xFF137e66),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF137e66),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
          ),
          textTheme: Typography.blackMountainView,
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          child: CalendarDatePicker(
            initialDate: _tempDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            // Set currentDate to a past date to avoid "today" styling issues
            currentDate: DateTime(2000, 1, 1),
            onDateChanged: (DateTime date) {
              setState(() {
                _tempDate = date;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: _showTimePicker,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: Color(0xFF137e66),
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                'Time: ${_tempTime.format(context)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTimePicker() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _tempTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF137e66),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _tempTime = picked;
      });
    }
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: PrimaryButton(
        label: 'Confirm',
        width: double.infinity,
        height: 50,
        backgroundColor: const Color(0xFF137e66),
        labelColor: Colors.white,
        onPressed: () {
          final DateTime updatedDateTime = DateTime(
            _tempDate.year,
            _tempDate.month,
            _tempDate.day,
            _tempTime.hour,
            _tempTime.minute,
          );
          widget.onConfirm(updatedDateTime);
          Navigator.pop(context);
        },
      ),
    );
  }
}
