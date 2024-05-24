import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/food_item.dart';
import '../controllers/food_item_controller.dart';
import '../controllers/food_log_controller.dart';
import '../widgets/food_item_form_widget.dart';
import '../services/ad_service.dart';
import '../widgets/log_entry_manager.dart';
import '../widgets/date_selector_widget.dart';

class FoodLogScreen extends ConsumerStatefulWidget {
  const FoodLogScreen({Key? key}) : super(key: key);

  @override
  _FoodLogScreenState createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends ConsumerState<FoodLogScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  FoodItem? _selectedFoodItem;
  double _quantity = 0.0;
  String _mealType = '';
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _timeController.text = DateFormat('HH:mm').format(DateTime.now());
    if (!kIsWeb) {
      _adService.initialize();
      _adService.loadRewardedAd();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _showFoodItemForm(BuildContext context, {FoodItem? initialFoodItem}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: FoodItemFormWidget(initialFoodItem: initialFoodItem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ).then((_) {
      _searchController.clear();
    });
  }

  void _selectFoodItem(FoodItem foodItem) {
    setState(() {
      _selectedFoodItem = foodItem;
      _searchController.clear();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateFormat('yyyy-MM-dd').parse(_dateController.text),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_timeController.text.split(':')[0]),
        minute: int.parse(_timeController.text.split(':')[1]),
      ),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  void _submitFoodLog() {
    if (_selectedFoodItem != null && _quantity > 0 && _mealType.isNotEmpty) {
      String notes = _notesController.text;
      DateTime localDateTime = DateFormat('yyyy-MM-dd HH:mm').parse('${_dateController.text} ${_timeController.text}');
      DateTime utcDateTime = tz.TZDateTime.from(localDateTime, tz.local).toUtc();

      ref.read(foodLogControllerProvider.notifier).createFoodLog(
        _selectedFoodItem!,
        _quantity,
        _mealType,
        utcDateTime,
        notes,
      ).then((_) {
        ref.read(selectedDateProvider.notifier).state = utcDateTime;
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Food log added successfully'), duration: Duration(seconds: 2)),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add food log: $error')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodItemState = ref.watch(foodItemControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Log Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Food Items',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => ref.read(foodItemControllerProvider.notifier).searchFoodItems(value),
            ),
            if (foodItemState.isLoading)
              const Center(child: CircularProgressIndicator()),
            if (!foodItemState.isLoading && _searchController.text.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                itemCount: foodItemState.foodItems.length,
                itemBuilder: (context, index) {
                  final foodItem = foodItemState.foodItems[index];
                  return ListTile(
                    title: Text(foodItem.name),
                    subtitle: Text('Calories: ${foodItem.caloriesPerUnit} cal'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showFoodItemForm(context, initialFoodItem: foodItem),
                    ),
                    onTap: () => _selectFoodItem(foodItem),
                  );
                },
              ),
            if (_selectedFoodItem != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: Text(_selectedFoodItem!.name),
                    subtitle: Text('Calories: ${_selectedFoodItem!.caloriesPerUnit} cal'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showFoodItemForm(context, initialFoodItem: _selectedFoodItem),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => setState(() {
                            _selectedFoodItem = null;
                            _quantity = 0.0;
                            _mealType = '';
                            _notesController.clear();
                          }),
                        ),
                      ],
                    ),
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Quantity in Grams'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) => setState(() {
                      _quantity = double.tryParse(value) ?? 0.0;
                    }),
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Meal Type'),
                    value: _mealType.isNotEmpty ? _mealType : null,
                    onChanged: (value) => setState(() {
                      _mealType = value ?? '';
                    }),
                    items: const ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                  TextField(
                    controller: _timeController,
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(context),
                  ),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  if (!kIsWeb)
                    LogEntryManager(
                      onLogSubmitted: _submitFoodLog,
                      adService: _adService,
                    ),
                  if (kIsWeb)
                    ElevatedButton(
                      onPressed: _submitFoodLog,
                      child: Text('Add to Log'),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showFoodItemForm(context),
              child: const Text('Add New Food Item'),
            ),
          ],
        ),
      ),
    );
  }
}
