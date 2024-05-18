import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../controllers/food_log_controller.dart';
import '../models/food_log.dart'; // Ensure this import is correct
import '../widgets/date_range_selector_widget.dart';

class FoodLogDisplayScreen extends ConsumerStatefulWidget {
  const FoodLogDisplayScreen({super.key});

  @override
  FoodLogDisplayScreenState createState() => FoodLogDisplayScreenState();
}

class FoodLogDisplayScreenState extends ConsumerState<FoodLogDisplayScreen> {
  DateTimeRange? _selectedRange;
  final ScrollController _scrollController = ScrollController();
  final int _logsPerPage = 10;
  final List<FoodLog> _displayedLogs = []; // Make this field final
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent &&
        !_isLoadingMore &&
        _displayedLogs.length < ref.read(foodLogControllerProvider).foodLogs.length) {
      _loadMoreLogs();
    }
  }

  void _loadMoreLogs() {
    setState(() {
      _isLoadingMore = true;
    });

    final allLogs = ref.read(foodLogControllerProvider).foodLogs;
    final startIndex = _displayedLogs.length;
    final endIndex = startIndex + _logsPerPage;

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _displayedLogs.addAll(allLogs.sublist(startIndex, endIndex.clamp(0, allLogs.length)));
        _isLoadingMore = false;
      });
    });
  }

  void _filterLogs(DateTimeRange range) {
    setState(() {
      _selectedRange = range;
      _displayedLogs.clear();
      ref.read(foodLogControllerProvider.notifier).fetchFoodLogs(startDate: range.start, endDate: range.end).then((_) {
        _loadMoreLogs();
      });
    });
  }

  Widget _buildPaginatedLogs() {
    final foodLogsState = ref.watch(foodLogControllerProvider);

    if (foodLogsState.isLoading && _displayedLogs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    } else if (foodLogsState.error != null) {
      return Center(child: Text('Error: ${foodLogsState.error}'));
    }

    if (_displayedLogs.isEmpty) {
      return const Center(child: Text('No logs available for the selected date range.'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _displayedLogs.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (_, index) {
        if (index == _displayedLogs.length) {
          return const Center(child: CircularProgressIndicator());
        }

        final log = _displayedLogs[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListTile(
            title: Text(log.foodItemName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meal: ${log.mealType}'),
                Text('Quantity: ${log.quantity} grams'),
                Text('Calories: ${log.totalCalories} kcal'),
                Text('Carbs: ${log.totalCarbs}g, Proteins: ${log.totalProteins}g, Fats: ${log.totalFats}g'),
                Text('Logged on: ${DateFormat('yyyy-MM-dd – HH:mm').format(log.dateLogged.toLocal())}'),
                if (log.notes != null && log.notes!.isNotEmpty) Text('Notes: ${log.notes}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                bool? confirmDelete = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: const Text('Are you sure you want to delete this log?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmDelete == true) {
                  await ref.read(foodLogControllerProvider.notifier).deleteFoodLog(log.id);
                  setState(() {
                    _displayedLogs.remove(log);
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Log Display'),
      ),
      body: Column(
        children: [
          DateRangeSelector(
            onDateRangeSelected: (DateTimeRange range) {
              _filterLogs(range);
            },
          ),
          Expanded(
            child: _selectedRange == null
              ? const Center(child: Text('Select a date range to view logs.'))
              : _buildPaginatedLogs(),
          ),
        ],
      ),
    );
  }
}
