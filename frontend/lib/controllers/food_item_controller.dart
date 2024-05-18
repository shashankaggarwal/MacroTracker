import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../services/api_service.dart';
import '../services/api_service_provider.dart';

class FoodItemState {
  final List<FoodItem> foodItems;
  final bool isLoading;
  final String? error;

  FoodItemState({this.foodItems = const [], this.isLoading = false, this.error});

  FoodItemState copyWith({List<FoodItem>? foodItems, bool? isLoading, String? error}) {
    return FoodItemState(
      foodItems: foodItems ?? this.foodItems,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class FoodItemController extends StateNotifier<FoodItemState> {
  final ApiService _apiService;

  FoodItemController({required ApiService apiService})
      : _apiService = apiService,
        super(FoodItemState());

  // To search for food items
  Future<void> searchFoodItems(String query) async {
  print("Starting search for items with query: $query"); // Log the start of the search
  state = state.copyWith(isLoading: true);
  print("Set state to loading"); // Confirm state set to loading
  try {
    final response = await _apiService.searchFoodItems(query);
    print("Received response: $response"); // Log the raw response from API

    final List<FoodItem> foodItems = List<Map<String, dynamic>>.from(response)
        .map((itemMap) => FoodItem.fromJson(itemMap))
        .toList();
    print("Processed food items: $foodItems"); // Log the processed food items list

    state = state.copyWith(foodItems: foodItems, isLoading: false);
    print("Updated state with new food items, set loading to false"); // Log state update
  } catch (e) {
    print("Failed to search food items with error: $e"); // Log any errors during the search
    state = state.copyWith(isLoading: false, error: e.toString());
  }
}


  // To create a new food item
  Future<void> createFoodItem(FoodItem foodItem) async {
    state = state.copyWith(isLoading: true);
    try {
      final Map<String, dynamic> response = await _apiService.createFoodItem(foodItem.toJson());
      final FoodItem newItem = FoodItem.fromJson(response);
      state = state.copyWith(
        foodItems: [...state.foodItems, newItem],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // To update an existing food item
  Future<void> updateFoodItem(FoodItem updatedItem) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.updateFoodItem(updatedItem.id, updatedItem.toJson());
      final List<FoodItem> updatedFoodItems = state.foodItems.map((item) {
        return item.id == updatedItem.id ? updatedItem : item;
      }).toList();
      state = state.copyWith(
        foodItems: updatedFoodItems,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // To delete an existing food item
  Future<void> deleteFoodItem(int itemId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.deleteFoodItem(itemId);
      final List<FoodItem> updatedFoodItems = state.foodItems.where((item) => item.id != itemId).toList();
      state = state.copyWith(
        foodItems: updatedFoodItems,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final foodItemControllerProvider = StateNotifierProvider<FoodItemController, FoodItemState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return FoodItemController(apiService: apiService);
});
