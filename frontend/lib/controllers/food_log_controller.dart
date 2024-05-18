import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/food_log.dart';
import '../models/food_item.dart';
import '../services/api_service.dart';
import '../services/api_service_provider.dart';

class FoodLogState {
  final List<FoodLog> foodLogs;
  final bool isLoading;
  final String? error;

  FoodLogState({this.foodLogs = const [], this.isLoading = false, this.error});

  FoodLogState copyWith({List<FoodLog>? foodLogs, bool? isLoading, String? error}) {
    return FoodLogState(
      foodLogs: foodLogs ?? this.foodLogs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class FoodLogController extends StateNotifier<FoodLogState> {
  final ApiService _apiService;

  FoodLogController({required ApiService apiService})
      : _apiService = apiService,
        super(FoodLogState());

 // Adjusting the fetchFoodLogs method to accept optional date parameters
Future<void> fetchFoodLogs({DateTime? date, DateTime? startDate, DateTime? endDate}) async {
  state = state.copyWith(isLoading: true);
  try {
    final response = await _apiService.fetchFoodLogs(date: date, startDate: startDate, endDate: endDate);
    final foodLogs = (response as List).map((log) => FoodLog.fromJson(log)).toList();
    state = state.copyWith(foodLogs: foodLogs, isLoading: false);
    debugPrint('fetchFoodLogs: Fetched ${foodLogs.length} logs.');
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
    debugPrint('fetchFoodLogs: Error fetching logs - $e');
  }
}


  Future<void> createFoodLog(FoodItem foodItem, double quantity, String mealType, DateTime dateLogged, String notes) async {
  state = state.copyWith(isLoading: true); // Begin operation, set loading true
  debugPrint('createFoodLog: Attempting to create log for foodItem: ${foodItem.name}');
  try {
    final logData = {
      'food_item_id': foodItem.id,
      'quantity': quantity,
      'meal_type': mealType.toLowerCase(),
      'date_logged': dateLogged.toIso8601String(),
      'notes': notes,
    };
    await _apiService.createFoodLog(logData);
    debugPrint('createFoodLog: Created log for foodItem: ${foodItem.name}');
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
    debugPrint('createFoodLog: Error creating log - $e');
  } finally {
    state = state.copyWith(isLoading: false); // End operation, set loading false regardless of result
  }
}


  Future<void> updateFoodLog(int logId, FoodItem foodItem, double quantity, String mealType, DateTime dateLogged, String notes) async {
    state = state.copyWith(isLoading: true);
    debugPrint('updateFoodLog: Attempting to update log with ID: $logId');
    try {
      final logData = {
        'food_item_id': foodItem.id,
        'quantity': quantity,
        'meal_type': mealType.toLowerCase(),
        'date_logged': dateLogged.toIso8601String(),
        'notes': notes,
      };
      await _apiService.updateFoodLog(logId, logData);
      await fetchFoodLogs();
      debugPrint('updateFoodLog: Updated log with ID: $logId');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      debugPrint('updateFoodLog: Error updating log with ID $logId - $e');
    }
  }

  Future<void> deleteFoodLog(int logId) async {
  state = state.copyWith(isLoading: true);
  debugPrint('deleteFoodLog: Attempting to delete log with ID: $logId');
  try {
    await _apiService.deleteFoodLog(logId);
    state = state.copyWith(
      foodLogs: state.foodLogs.where((log) => log.id != logId).toList(),
      isLoading: false,
    );
    debugPrint('deleteFoodLog: Deleted log with ID: $logId');
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
    debugPrint('deleteFoodLog: Error deleting log with ID $logId - $e');
  }
}

}

final foodLogControllerProvider = StateNotifierProvider<FoodLogController, FoodLogState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return FoodLogController(apiService: apiService);
});
