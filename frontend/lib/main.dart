import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/goal_screen.dart';
import 'screens/food_log_screen.dart'; // Ensure this import is added
import 'controllers/notification_controller.dart';  // Import the notification controller

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (!kIsWeb) {
      await MobileAds.instance.initialize().then((InitializationStatus status) {
        print('Mobile Ads initialized: $status');
      }).catchError((e) {
        print('Error initializing Mobile Ads: $e');
      });
    }
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    print('Timezone fetched: $currentTimeZone');
    runApp(
      ProviderScope(
        overrides: [
          timezoneProvider.overrideWithValue(currentTimeZone),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print('Error during initialization: $e');
  }
}

final timezoneProvider = Provider<String>((ref) {
  throw UnimplementedError();
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timezone = ref.watch(timezoneProvider);
    if (!kIsWeb) {
      ref.read(notificationControllerProvider).initializeNotifications(navigatorKey).catchError((e) {
        print('Error initializing notifications: $e');
      });
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MacroMonk',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/goals': (context) => const GoalsScreen(),
        '/foodLog': (context) => const FoodLogScreen(),  // Ensure the route to FoodLogScreen is added
      },
      builder: (context, child) {
        return TimeZoneProvider(timezone: timezone, child: child!);
      },
    );
  }
}

class TimeZoneProvider extends InheritedWidget {
  final String timezone;

  const TimeZoneProvider({
    Key? key,
    required this.timezone,
    required Widget child,
  }) : super(key: key, child: child);

  static TimeZoneProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TimeZoneProvider>();
  }

  @override
  bool updateShouldNotify(TimeZoneProvider oldWidget) {
    return timezone != oldWidget.timezone;
  }
}
