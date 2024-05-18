import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/dashboard_screen.dart';
import '../screens/food_log_screen.dart';
import '../screens/goal_screen.dart';
import '../screens/food_log_display_screen.dart';
import '../controllers/auth_controller.dart';

class MainMenuDrawerWidget extends ConsumerWidget {
  const MainMenuDrawerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(profileProvider);  // Assuming you have a profileProvider for user data

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: userProfile.when(
              data: (profile) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, ${profile?.username ?? 'Guest'}', style: const TextStyle(color: Colors.white, fontSize: 24)),
                  Text(profile?.email ?? 'email@example.com', style: const TextStyle(color: Colors.white, fontSize: 14)),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(profile?.username.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(fontSize: 40.0)),
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => const Text('Failed to load profile'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DashboardScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.fastfood),
            title: const Text('Food Log'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FoodLogScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text('Goals'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoalsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.timeline),
            title: const Text('Food Log Display'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FoodLogDisplayScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                ref.read(authControllerProvider.notifier).logout();
                if (!context.mounted) return; // Check if the context is still valid
                Navigator.of(context).pushReplacementNamed('/login'); // Assuming you have a login screen route
              }
            },
          ),
        ],
      ),
    );
  }
}
