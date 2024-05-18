import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import '../controllers/food_log_controller.dart'; // Ensure you have the correct path to your FoodLogController

// Provider to manage selected date state
final selectedDateProvider = StateProvider<DateTime>((ref) {
  debugPrint('Selected date provider initialized');
  return DateTime.now();
});

class DateSelector extends ConsumerWidget {
  const DateSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime selectedDate = ref.watch(selectedDateProvider);
    debugPrint('DateSelector built with date: ${DateFormat.yMd().format(selectedDate)}');

    // This flag helps us track whether we've done the initial fetch
    bool initialFetchDone = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!initialFetchDone) {
        debugPrint('Fetching logs for initial date: ${selectedDate.toIso8601String()}');
        ref.read(foodLogControllerProvider.notifier).fetchFoodLogs(date: selectedDate);
        initialFetchDone = true;
      }
    });

    // Reactive fetching when the date changes
   ref.listen<DateTime>(selectedDateProvider, (previousDate, nextDate) {
      if (nextDate != previousDate && nextDate != ref.read(selectedDateProvider)) {
        debugPrint('Date selected: ${DateFormat.yMd().format(nextDate)} - Fetching logs.');
        ref.read(foodLogControllerProvider.notifier).fetchFoodLogs(date: nextDate);
      }
    });

    return EasyDateTimeLine(
  key: ValueKey(selectedDate),  // Forces rebuild whenever the selected date changes
  initialDate: selectedDate,
  onDateChange: (DateTime date) {
    debugPrint('Date manually selected: ${DateFormat.yMd().format(date)}');
    ref.read(selectedDateProvider.notifier).state = date;
  },
  headerProps: EasyHeaderProps(
    monthPickerType: MonthPickerType.switcher,
    dateFormatter: DateFormatter.custom('d MMMM yyyy')
  ),
  dayProps: EasyDayProps(
    activeDayStyle: DayStyle(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff3371FF), Color(0xff8426D6)],
        ),
      ),
    ),
    inactiveDayStyle: DayStyle(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[300],
      ),
    ),
    todayHighlightStyle: TodayHighlightStyle.withBackground,
    todayHighlightColor: Colors.greenAccent,
  ),
  locale: 'en',
);

  }
}
