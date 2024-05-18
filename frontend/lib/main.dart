import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/goal_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();  // Initialize Mobile Ads SDK
  final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
  runApp(
    ProviderScope(
      overrides: [
        timezoneProvider.overrideWithValue(currentTimeZone),
      ],
      child: const MyApp(),
    ),
  );
}

final timezoneProvider = Provider<String>((ref) {
  throw UnimplementedError();
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timezone = ref.watch(timezoneProvider);
    return MaterialApp(
      title: 'MacroMonk',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/login': (context) => const LoginScreen(), // Ensure this route is added
        '/register': (context) => const RegistrationScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/goals': (context) => const GoalsScreen(),
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
