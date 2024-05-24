import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/api_service_provider.dart';
import 'dashboard_screen.dart';  // Ensure this is the correct path

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});  // Use super parameter for key

  @override
  GoalsScreenState createState() => GoalsScreenState();  // Make class public
}

class GoalsScreenState extends ConsumerState<GoalsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _carbsGoalController = TextEditingController();
  final TextEditingController _proteinGoalController = TextEditingController();
  final TextEditingController _fatGoalController = TextEditingController();
  bool _isLoading = false;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final apiService = ref.read(apiServiceProvider);
    try {
      final userProfileData = await apiService.fetchProfiles();
      if (userProfileData != null && userProfileData.isNotEmpty) {
        setState(() {
          _userProfile = UserProfile.fromJson(userProfileData.first);
          _loadExistingGoals();
        });
      } else {
        if (mounted) {  // Ensure mounted before using context
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No profile data found.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {  // Ensure mounted before using context
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadExistingGoals() {
    _carbsGoalController.text = _userProfile!.carbsGoal.toString();
    _proteinGoalController.text = _userProfile!.proteinGoal.toString();
    _fatGoalController.text = _userProfile!.fatGoal.toString();
  }

  void _saveGoals(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final updatedGoals = {
        'calorie_goal': (_carbsGoalController.text.isNotEmpty ? int.parse(_carbsGoalController.text) * 4 : 0) +
            (_proteinGoalController.text.isNotEmpty ? int.parse(_proteinGoalController.text) * 4 : 0) +
            (_fatGoalController.text.isNotEmpty ? int.parse(_fatGoalController.text) * 9 : 0),
        'carbs_goal': int.parse(_carbsGoalController.text),
        'protein_goal': int.parse(_proteinGoalController.text),
        'fat_goal': int.parse(_fatGoalController.text),
      };

      if (_userProfile != null) {
        ref.read(apiServiceProvider).updateProfile(_userProfile!.profileId, updatedGoals).then((_) {
          final profileFuture = ref.refresh(profileProvider);
          profileFuture.when(
            data: (_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Goals updated successfully.')),
                );
                Navigator.of(context).pushReplacementNamed('/dashboard'); // Navigate to the dashboard
              }
            },
            loading: () {},
            error: (error, _) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to refresh profile: $error')),
                );
              }
            },
          );
        }).catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update goals: $error')),
            );
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user profile loaded, cannot save goals.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Your Goals')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _carbsGoalController,
                        decoration: const InputDecoration(labelText: 'Carbs Goal (grams)'),
                        keyboardType: TextInputType.number,
                        validator: (value) => (value != null && value.isNotEmpty && int.tryParse(value) != null) ? null : 'Enter a valid number',
                      ),
                      TextFormField(
                        controller: _proteinGoalController,
                        decoration: const InputDecoration(labelText: 'Protein Goal (grams)'),
                        keyboardType: TextInputType.number,
                        validator: (value) => (value != null && value.isNotEmpty && int.tryParse(value) != null) ? null : 'Enter a valid number',
                      ),
                      TextFormField(
                        controller: _fatGoalController,
                        decoration: const InputDecoration(labelText: 'Fat Goal (grams)'),
                        keyboardType: TextInputType.number,
                        validator: (value) => (value != null && value.isNotEmpty && int.tryParse(value) != null) ? null : 'Enter a valid number',
                      ),
                      ElevatedButton(
                        onPressed: () => _saveGoals(context),
                        child: const Text('Save Goals'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _carbsGoalController.dispose();
    _proteinGoalController.dispose();
    _fatGoalController.dispose();
    super.dispose();
  }
}
