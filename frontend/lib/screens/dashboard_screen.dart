import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/date_selector_widget.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../widgets/goal_progress_widget.dart';
import '../widgets/nutritional_summary_widget.dart';
import '../widgets/main_menu_drawer_widget.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  debugPrint('API Service Provider initialized');
  return ApiService();
});

final profileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  debugPrint('Fetching profiles...');
  try {
    List<dynamic> profiles = await apiService.fetchProfiles();
    debugPrint('Profiles fetched: $profiles');
    if (profiles.isNotEmpty) {
      debugPrint('Converting first profile to UserProfile object...');
      return UserProfile.fromJson(profiles.first);
    }
    debugPrint('No profiles found.');
    return null;
  } catch (e) {
    debugPrint('Error fetching profiles: $e');
    throw e;
  }
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime selectedDate = ref.watch(selectedDateProvider);
    debugPrint('DashboardScreen built with selected date: $selectedDate');


    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      drawer: const MainMenuDrawerWidget(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const DateSelector(),
            GoalProgressWidget(selectedDate: selectedDate),
            NutritionalSummary(selectedDate: selectedDate),
            const ProfileSummary(),
          ],
        ),
      ),
    );
  }
}




class ProfileSummary extends ConsumerWidget {
  const ProfileSummary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsyncValue = ref.watch(profileProvider);
    debugPrint('ProfileSummary building...');

    return profileAsyncValue.when(
      data: (profile) {
        debugPrint('Profile data received: ${profile?.username}');
        return profile != null ? Text('Username: ${profile.username}, Email: ${profile.email}') : const Text('No profile data available.');
      },
      loading: () {
        debugPrint('Profile data is loading...');
        return const CircularProgressIndicator();
      },
      error: (e, _) {
        debugPrint('Error loading profile data: $e');
        return Text('Error: $e');
      },
    );
  }
}
