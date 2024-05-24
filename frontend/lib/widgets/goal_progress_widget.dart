import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/food_log.dart';
import '../models/user_profile.dart';
import '../controllers/food_log_controller.dart';
import '../screens/dashboard_screen.dart';

class GoalProgressWidget extends StatefulWidget {
  final DateTime selectedDate;

  const GoalProgressWidget({Key? key, required this.selectedDate}) : super(key: key);

  @override
  _GoalProgressWidgetState createState() => _GoalProgressWidgetState();
}

class _GoalProgressWidgetState extends State<GoalProgressWidget> {
  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final foodLogState = ref.watch(foodLogControllerProvider);
        final profileAsyncValue = ref.watch(profileProvider);

        return profileAsyncValue.when(
          data: (profile) {
            if (profile == null) {
              return const Text('No profile data available.');
            }

            if (foodLogState.isLoading) {
              return const CircularProgressIndicator();
            } else if (foodLogState.error != null) {
              return Text('Error: ${foodLogState.error}');
            }

            return _buildProgress(profile, foodLogState.foodLogs, widget.selectedDate);
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
        );
      },
    );
  }

  Widget _buildProgress(UserProfile profile, List<FoodLog> foodLogs, DateTime selectedDate) {
    final logsForSelectedDate = foodLogs.where((log) => log.dateLogged.day == selectedDate.day).toList();

    final totalCalories = logsForSelectedDate.fold<double>(0.0, (total, log) => total + log.totalCalories);
    final calorieGoal = profile.calorieGoal.toDouble();

    final totalCarbs = logsForSelectedDate.fold<double>(0.0, (total, log) => total + log.totalCarbs);
    final carbsGoal = profile.carbsGoal.toDouble();

    final totalProteins = logsForSelectedDate.fold<double>(0.0, (total, log) => total + log.totalProteins);
    final proteinGoal = profile.proteinGoal.toDouble();

    final totalFats = logsForSelectedDate.fold<double>(0.0, (total, log) => total + log.totalFats);
    final fatGoal = profile.fatGoal.toDouble();

    return Wrap(
      spacing: 20.0, // horizontal space between children
      runSpacing: 20.0, // vertical space between lines
      alignment: WrapAlignment.center,
      children: [
        _buildNutrientProgress(
          icon: const FaIcon(FontAwesomeIcons.fire, color: Colors.green),
          value: totalCalories,
          goal: calorieGoal,
          label: 'Calories',
        ),
        _buildNutrientProgress(
          icon: const Icon(Icons.rice_bowl, color: Colors.blue),
          value: totalCarbs,
          goal: carbsGoal,
          label: 'Carbs',
          unit: 'g',
        ),
        _buildNutrientProgress(
          icon: const FaIcon(FontAwesomeIcons.egg, color: Colors.red),
          value: totalProteins,
          goal: proteinGoal,
          label: 'Proteins',
          unit: 'g',
        ),
        _buildNutrientProgress(
          icon: const FaIcon(FontAwesomeIcons.bacon, color: Colors.yellow),
          value: totalFats,
          goal: fatGoal,
          label: 'Fats',
          unit: 'g',
        ),
      ],
    );
  }

  Widget _buildNutrientProgress({
    required Widget icon,
    required double value,
    required double goal,
    required String label,
    String unit = '',
  }) {
    const double iconSize = 24.0;
    const double progressSize = 80.0;

    final progress = value / (goal <= 0 ? 1 : goal);
    final clampedProgress = progress.clamp(0.0, 1.0);

    Color progressColor;
    if (clampedProgress < 0.5) {
      progressColor = Colors.red.shade400;
    } else if (clampedProgress < 0.8) {
      progressColor = Colors.orange.shade400;
    } else {
      progressColor = Colors.green.shade400;
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: icon,
          ),
          const SizedBox(height: 8.0),
          CircularPercentIndicator(
            radius: progressSize / 2,
            lineWidth: 8.0,
            percent: clampedProgress,
            center: Text('${(clampedProgress * 100).toStringAsFixed(0)}%'),
            progressColor: progressColor,
            animateFromLastPercent: true, // Enables the animation from the last percent value
            animation: true, // Animates the progress change
            animationDuration: 500, // Duration of the animation in milliseconds
            curve: Curves.bounceInOut,
          ),
          Text(
            '$label:',
            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          Text(
            '${value.round()} $unit / ${goal.round()} $unit',
            style: const TextStyle(fontSize: 16.0),
          ),
        ],
      ),
    );
  }
}
