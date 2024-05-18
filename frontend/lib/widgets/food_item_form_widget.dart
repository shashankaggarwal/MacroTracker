import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../controllers/food_item_controller.dart';

class FoodItemFormWidget extends ConsumerStatefulWidget {
  final FoodItem? initialFoodItem;

  const FoodItemFormWidget({super.key, this.initialFoodItem});

  @override
  _FoodItemFormWidgetState createState() => _FoodItemFormWidgetState();
}

class _FoodItemFormWidgetState extends ConsumerState<FoodItemFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _carbsPerUnitController;
  late TextEditingController _proteinsPerUnitController;
  late TextEditingController _fatsPerUnitController;
  double _totalCalories = 0;
  bool _applyAdjustment = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialFoodItem?.name ?? '');
    _carbsPerUnitController = TextEditingController(text: widget.initialFoodItem?.carbsPerUnit?.toString() ?? '');
    _proteinsPerUnitController = TextEditingController(text: widget.initialFoodItem?.proteinsPerUnit?.toString() ?? '');
    _fatsPerUnitController = TextEditingController(text: widget.initialFoodItem?.fatsPerUnit?.toString() ?? '');
    _carbsPerUnitController.addListener(_updateCalories);
    _proteinsPerUnitController.addListener(_updateCalories);
    _fatsPerUnitController.addListener(_updateCalories);
    _updateCalories();
  }

  void _updateCalories() {
    final carbs = double.tryParse(_carbsPerUnitController.text) ?? 0;
    final proteins = double.tryParse(_proteinsPerUnitController.text) ?? 0;
    final fats = double.tryParse(_fatsPerUnitController.text) ?? 0;
    double calories = (carbs + proteins) * 4 + fats * 9;
    double adjustedCalories = _applyAdjustment ? calories * 1.05 : calories;
    setState(() {
      _totalCalories = _formatCalories(adjustedCalories);
    });
  }

  double _formatCalories(double calories) {
    String formatted = calories.toStringAsFixed(2);
    if (formatted.replaceAll('.', '').length > 6) {
      formatted = calories.toStringAsFixed(1);
      if (formatted.replaceAll('.', '').length > 6) {
        formatted = calories.round().toString();
      }
    }
    return double.parse(formatted);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _carbsPerUnitController.dispose();
    _proteinsPerUnitController.dispose();
    _fatsPerUnitController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false && _isMacroSumValid()) {
      double caloriesToUse = _formatCalories(_totalCalories);

      final foodItem = FoodItem(
        id: widget.initialFoodItem?.id ?? 0,
        name: _nameController.text,
        caloriesPerUnit: caloriesToUse,
        carbsPerUnit: double.tryParse(_carbsPerUnitController.text) ?? 0,
        proteinsPerUnit: double.tryParse(_proteinsPerUnitController.text) ?? 0,
        fatsPerUnit: double.tryParse(_fatsPerUnitController.text) ?? 0,
      );

      try {
        if (widget.initialFoodItem == null) {
          await ref.read(foodItemControllerProvider.notifier).createFoodItem(foodItem);
        } else {
          await ref.read(foodItemControllerProvider.notifier).updateFoodItem(foodItem);
        }
        if (mounted) {
          Navigator.pop(context, foodItem);  // Return the updated item
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An error occurred while saving the food item: ${e.toString()}')),
          );
        }
      }
    }
  }

  bool _isMacroSumValid() {
    final carbs = double.tryParse(_carbsPerUnitController.text) ?? 0;
    final proteins = double.tryParse(_proteinsPerUnitController.text) ?? 0;
    final fats = double.tryParse(_fatsPerUnitController.text) ?? 0;
    return (carbs + proteins + fats) <= 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialFoodItem == null ? 'Add Food Item' : 'Update Food Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value != null && value.isNotEmpty ? null : 'Please enter the food item name',
                ),
                TextFormField(
                  controller: _carbsPerUnitController,
                  decoration: const InputDecoration(labelText: 'Carbs per 100g'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value != null && value.isNotEmpty ? null : 'Please enter carbs per 100g',
                ),
                TextFormField(
                  controller: _proteinsPerUnitController,
                  decoration: const InputDecoration(labelText: 'Proteins per 100g'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value != null && value.isNotEmpty ? null : 'Please enter proteins per 100g',
                ),
                TextFormField(
                  controller: _fatsPerUnitController,
                  decoration: const InputDecoration(labelText: 'Fats per 100g'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value != null && value.isNotEmpty ? null : 'Please enter fats per 100g',
                ),
                SizedBox(height: 10),
                Text('Total Calories: ${_totalCalories.toStringAsFixed(2)} cal'),
                CheckboxListTile(
                  title: const Text('Caloric Adjustment for Nutrient Variations'),
                  subtitle: const Text('Check to add a 5% buffer to the total calculated calories.'),
                  value: _applyAdjustment,
                  onChanged: (bool? value) {
                    setState(() {
                      _applyAdjustment = value ?? false;
                      _updateCalories();
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Save Food Item'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
