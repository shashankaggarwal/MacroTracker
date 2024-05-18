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
                      title: Text(log.foodItemName),
                      subtitle: Row(
                        children: [
                          const Icon(FontAwesomeIcons.fire, color: Colors.green),
                          Text(' Cal: ${log.totalCalories ?? 'N/A'} '),
                          const Icon(Icons.rice_bowl, color: Colors.blue),
                          Text(' C: ${log.totalCarbs ?? 'N/A'}g '),
                          const Icon(FontAwesomeIcons.egg, color: Colors.red),
                          Text(' P: ${log.totalProteins ?? 'N/A'}g '),
                          const Icon(FontAwesomeIcons.bacon, color: Colors.yellow),
                          Text(' F: ${log.totalFats ?? 'N/A'}g')
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(DateFormat.Hm().format(log.dateLogged.toLocal())),
                          IconButton(
                            icon: const Icon(Icons.delete),
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
                            const Icon(FontAwesomeIcons.fire, color: Colors.green),
                            Text(' Cal ${mealTypeTotals[entry.key]!['Calories']?.toStringAsFixed(2) ?? 'N/A'}, '),
                            const Icon(Icons.rice_bowl, color: Colors.blue),
                            Text(' C ${mealTypeTotals[entry.key]!['Carbs']?.toStringAsFixed(2) ?? 'N/A'}g, '),
                            const Icon(FontAwesomeIcons.egg, color: Colors.red),
                            Text(' P ${mealTypeTotals[entry.key]!['Proteins']?.toStringAsFixed(2) ?? 'N/A'}g, '),
                            const Icon(FontAwesomeIcons.bacon, color: Colors.yellow),
                            Text(' F ${mealTypeTotals[entry.key]!['Fats']?.toStringAsFixed(2) ?? 'N/A'}g')
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
                      const Icon(FontAwesomeIcons.fire, color: Colors.green),
                      Text(' Cal ${totalCalories.toStringAsFixed(2)}, '),
                      const Icon(Icons.rice_bowl, color: Colors.blue),
                      Text(' C ${totalCarbs.toStringAsFixed(2)}g, '),
                      const Icon(FontAwesomeIcons.egg, color: Colors.red),
                      Text(' P ${totalProteins.toStringAsFixed(2)}g, '),
                      const Icon(FontAwesomeIcons.bacon, color: Colors.yellow),
                      Text(' F ${totalFats.toStringAsFixed(2)}g')
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
