import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../controllers/food_log_controller.dart';
import '../models/food_log.dart';

class NutritionalSummary extends ConsumerWidget {
  final DateTime selectedDate;

  const NutritionalSummary({Key? key, required this.selectedDate}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodLogsState = ref.watch(foodLogControllerProvider);

    if (foodLogsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (foodLogsState.error != null) {
      return Center(child: Text('Error: ${foodLogsState.error}'));
    }

    var dailyLogs = foodLogsState.foodLogs
        .where((log) =>
            log.dateLogged.day == selectedDate.day &&
            log.dateLogged.month == selectedDate.month &&
            log.dateLogged.year == selectedDate.year)
        .toList();

    if (dailyLogs.isEmpty) {
      return Center(
        child: Text('No food logs available for ${DateFormat.yMd().format(selectedDate)}'),
      );
    }

    Map<String, List<FoodLog>> groupedLogs = {};
    Map<String, Map<String, double>> mealTypeTotals = {};

    double totalCalories = 0, totalCarbs = 0, totalProteins = 0, totalFats = 0;

    for (FoodLog log in dailyLogs) {
      groupedLogs.putIfAbsent(log.mealType, () => []).add(log);
      var mealTotals = mealTypeTotals.putIfAbsent(log.mealType, () => {
        'Calories': 0.0, 'Carbs': 0.0, 'Proteins': 0.0, 'Fats': 0.0
      });

      mealTotals['Calories'] = mealTotals['Calories']! + (log.totalCalories ?? 0);
      mealTotals['Carbs'] = mealTotals['Carbs']! + (log.totalCarbs ?? 0);
      mealTotals['Proteins'] = mealTotals['Proteins']! + (log.totalProteins ?? 0);
      mealTotals['Fats'] = mealTotals['Fats']! + (log.totalFats ?? 0);

      totalCalories += log.totalCalories ?? 0;
      totalCarbs += log.totalCarbs ?? 0;
      totalProteins += log.totalProteins ?? 0;
      totalFats += log.totalFats ?? 0;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Nutritional Summary for ${DateFormat.yMd().format(selectedDate)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ...groupedLogs.entries.map((entry) {
            return ExpansionTile(
              title: Text(
                '${entry.key} (${entry.value.length} items)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.restaurant_menu, color: Colors.blue),
              children: [
                ...entry.value.map(
                  (log) {
                    return ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(log.foodItemName, overflow: TextOverflow.ellipsis),
                          ),
                          Text(
                            DateFormat.Hm().format(log.dateLogged.toLocal()),
                            style: TextStyle(fontSize: 12),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 16),
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
                                ref.read(foodLogControllerProvider.notifier).deleteFoodLog(log.id);
                              }
                            },
                          ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          const Icon(FontAwesomeIcons.fire, color: Colors.green, size: 16),
                          Text(' Cal: ${log.totalCalories?.round() ?? 'N/A'} '),
                          const Icon(Icons.rice_bowl, color: Colors.blue, size: 16),
                          Text(' C: ${log.totalCarbs?.round() ?? 'N/A'}g '),
                          const Icon(FontAwesomeIcons.egg, color: Colors.red, size: 16),
                          Text(' P: ${log.totalProteins?.round() ?? 'N/A'}g '),
                          const Icon(FontAwesomeIcons.bacon, color: Colors.yellow, size: 16),
                          Text(' F: ${log.totalFats?.round() ?? 'N/A'}g')
                        ],
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Center(
                    child: Column(
                      children: [
                        Text('Total of ${entry.key}: '),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(FontAwesomeIcons.fire, color: Colors.green, size: 16),
                            Text(' Cal ${mealTypeTotals[entry.key]!['Calories']?.round() ?? 'N/A'}, '),
                            const Icon(Icons.rice_bowl, color: Colors.blue, size: 16),
                            Text(' C ${mealTypeTotals[entry.key]!['Carbs']?.round() ?? 'N/A'}g, '),
                            const Icon(FontAwesomeIcons.egg, color: Colors.red, size: 16),
                            Text(' P ${mealTypeTotals[entry.key]!['Proteins']?.round() ?? 'N/A'}g, '),
                            const Icon(FontAwesomeIcons.bacon, color: Colors.yellow, size: 16),
                            Text(' F ${mealTypeTotals[entry.key]!['Fats']?.round() ?? 'N/A'}g')
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: Center(
              child: Column(
                children: [
                  const Text('Total for the day: '),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(FontAwesomeIcons.fire, color: Colors.green, size: 16),
                      Text(' Cal ${totalCalories.round()}, '),
                      const Icon(Icons.rice_bowl, color: Colors.blue, size: 16),
                      Text(' C ${totalCarbs.round()}g, '),
                      const Icon(FontAwesomeIcons.egg, color: Colors.red, size: 16),
                      Text(' P ${totalProteins.round()}g, '),
                      const Icon(FontAwesomeIcons.bacon, color: Colors.yellow, size: 16),
                      Text(' F ${totalFats.round()}g')
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
