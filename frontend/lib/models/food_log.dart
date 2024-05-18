import 'package:flutter/foundation.dart';

@immutable
class FoodLog {
  final int id;
  final String username;
  final String foodItemName;
  final double quantity;
  final String mealType;
  final DateTime dateLogged;
  final String? notes; // Nullable since notes can be null
  final double totalCalories;
  final double totalCarbs;
  final double totalProteins;
  final double totalFats;

  const FoodLog({
    required this.id,
    required this.username,
    required this.foodItemName,
    required this.quantity,
    required this.mealType,
    required this.dateLogged,
    this.notes,
    required this.totalCalories,
    required this.totalCarbs,
    required this.totalProteins,
    required this.totalFats,
  });

  factory FoodLog.fromJson(Map<String, dynamic> json) {
  print('Parsing FoodLog from JSON');
  
  double parseDouble(dynamic value) {
    if (value is String) {
      return double.parse(value);
    } else if (value is num) {
      return value.toDouble();
    } else {
      throw FormatException('Cannot convert $value to a double');
    }
  }
  
  return FoodLog(
    id: json['id'] as int,
    username: json['username'] as String,
    foodItemName: json['food_item_name'] as String,
    quantity: parseDouble(json['quantity']),
    mealType: json['meal_type'] as String,
    dateLogged: DateTime.parse(json['date_logged'] as String),
    notes: json['notes'] as String?,
    totalCalories: parseDouble(json['total_calories']),
    totalCarbs: parseDouble(json['total_carbs']),
    totalProteins: parseDouble(json['total_proteins']),
    totalFats: parseDouble(json['total_fats']),
  );
}

  Map<String, dynamic> toJson() {
    print('Converting FoodLog to JSON');
    return {
      'id': id,
      'username': username,
      'food_item_name': foodItemName,
      'quantity': quantity,
      'meal_type': mealType,
      'date_logged': dateLogged.toIso8601String(),
      'notes': notes,
      'total_calories': totalCalories,
      'total_carbs': totalCarbs,
      'total_proteins': totalProteins,
      'total_fats': totalFats,
    };
  }

  @override
  String toString() {
    return 'FoodLog(id: $id, username: $username, foodItemName: $foodItemName, quantity: $quantity, mealType: $mealType, dateLogged: $dateLogged, notes: $notes, totalCalories: $totalCalories, totalCarbs: $totalCarbs, totalProteins: $totalProteins, totalFats: $totalFats)';
  }
}
