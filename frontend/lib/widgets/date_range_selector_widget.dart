import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  // Make sure to import this for DateFormat

// Callback type definition for date range selection
typedef DateRangeCallback = void Function(DateTimeRange dateRange);

class DateRangeSelector extends StatefulWidget {
  final DateRangeCallback onDateRangeSelected;

  const DateRangeSelector({Key? key, required this.onDateRangeSelected}) : super(key: key);

  @override
  _DateRangeSelectorState createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  DateTimeRange? _selectedRange;

  void _presentDatePicker(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 5),
      initialDateRange: _selectedRange ?? DateTimeRange(
        start: today.subtract(const Duration(days: 7)), 
        end: today,
      ),
    );

    if (pickedRange != null && pickedRange != _selectedRange) {
      setState(() {
        _selectedRange = pickedRange;
      });
      widget.onDateRangeSelected(pickedRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _presentDatePicker(context),
          child: Text(_selectedRange == null
              ? 'Select Date Range'
              : 'From ${DateFormat('yMMMd').format(_selectedRange!.start)} '
                'to ${DateFormat('yMMMd').format(_selectedRange!.end)}'),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Theme.of(context).primaryColor),
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
          ),
        ),
        if (_selectedRange != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Selected Range: From ${DateFormat('yMMMd').format(_selectedRange!.start)} to ${DateFormat('yMMMd').format(_selectedRange!.end)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
