class FoodItem {
  final int id;
  final String name;
  final double caloriesPerUnit;
  final double carbsPerUnit;
  final double proteinsPerUnit;
  final double fatsPerUnit;

  FoodItem({
    required this.id,
    required this.name,
    required this.caloriesPerUnit,
    required this.carbsPerUnit,
    required this.proteinsPerUnit,
    required this.fatsPerUnit,
  });

  // Factory constructor to create a FoodItem from JSON data
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as int,
      name: json['name'] as String,
      caloriesPerUnit: _parseDouble(json['calories_per_unit']),
      carbsPerUnit: _parseDouble(json['carbs_per_unit']),
      proteinsPerUnit: _parseDouble(json['proteins_per_unit']),
      fatsPerUnit: _parseDouble(json['fats_per_unit']),
    );
  }

  // Helper method to safely parse doubles from dynamic types, handling strings and numbers
  static double _parseDouble(dynamic value) {
    try {
      // Attempt to parse the value as a double
      return double.parse(value.toString());
    } catch (e) {
      // Log the error and return a default value if parsing fails
      print('Error parsing double: $e');
      return 0.0;
    }
  }

  // Converts a FoodItem instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories_per_unit': caloriesPerUnit,
      'carbs_per_unit': carbsPerUnit,
      'proteins_per_unit': proteinsPerUnit,
      'fats_per_unit': fatsPerUnit,
    };
  }
}
