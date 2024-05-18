import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../controllers/food_item_controller.dart';
import '../controllers/food_log_controller.dart';
import '../widgets/food_item_form_widget.dart';

class FoodItemSearchWidget extends ConsumerStatefulWidget {
  final void Function(FoodItem selectedFoodItem) onFoodItemSelected;

  const FoodItemSearchWidget({Key? key, required this.onFoodItemSelected}) : super(key: key);

  @override
  _FoodItemSearchWidgetState createState() => _FoodItemSearchWidgetState();
}

class _FoodItemSearchWidgetState extends ConsumerState<FoodItemSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedMealType = 'Breakfast'; // Default value, could also start with an empty string
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController(); // Added to collect notes

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _quantityController.dispose();
    _notesController.dispose(); // Dispose notes controller
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      ref.read(foodItemControllerProvider.notifier).searchFoodItems(_searchController.text);
    }
  }

  void selectFoodItem(FoodItem foodItem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Log ${foodItem.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: 'Enter quantity'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              DropdownButtonFormField<String>(
                value: _selectedMealType,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMealType = newValue!;
                  });
                },
                items: <String>['Breakfast', 'Lunch', 'Dinner', 'Snack']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: InputDecoration(labelText: 'Meal Type'),
              ),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(labelText: 'Notes (optional)'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Add to Log'),
              onPressed: () {
                if (_quantityController.text.isNotEmpty) {
                  final DateTime dateLogged = DateTime.now(); // Assuming log for the current date
                  final double quantity = double.parse(_quantityController.text);
                  final String notes = _notesController.text;
                  ref.read(foodLogControllerProvider.notifier).createFoodLog(
                    foodItem,
                    quantity,
                    _selectedMealType,
                    dateLogged,
                    notes,
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodItemState = ref.watch(foodItemControllerProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Food Items',
              suffixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: foodItemState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: foodItemState.foodItems.length,
                  itemBuilder: (context, index) {
                    final foodItem = foodItemState.foodItems[index];
                    return ListTile(
                      title: Text(foodItem.name),
                      subtitle: Text('Calories: ${foodItem.caloriesPerUnit.toString()} cal'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => FoodItemFormWidget(initialFoodItem: foodItem),
                            ),
                          );
                        },
                      ),
                      onTap: () => selectFoodItem(foodItem),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
