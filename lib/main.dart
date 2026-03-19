import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/jobs_provider.dart';
import 'providers/auth_provider.dart';
import 'services/aws_http_client_service.dart';
import 'services/analytics_service.dart';
import 'widgets/auth_wrapper.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/root_nav.dart';
import 'screens/job_form_screen.dart';
import 'screens/jobs_list_screen.dart';
import 'screens/customer_profile_screen.dart';
import 'screens/customer_history_screen.dart';
import 'screens/provider_dashboard_screen.dart';
import 'screens/provider_earnings_screen.dart';
import 'screens/notifications_screen.dart';
import 'widgets/snow_overlay.dart';
import 'services/aws_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize notification service
  final notificationService = AWSNotificationService();
  await notificationService.initialize();

  // Track app open
  await AnalyticsService.trackAppOpen();

  runApp(const SnowGoApp());
}

class SnowGoApp extends StatelessWidget {
  const SnowGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AtomicJobsProvider()),
        Provider(create: (_) => AWSHttpClientService()),
      ],
      child: MaterialApp(
        title: 'SnowGo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3:
              false, // outlined fields & classic AppBar (closer to the mock)
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0E63F6),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          LoginScreen.route: (_) => const LoginScreen(),
          HomeScreen.route: (_) => const HomeScreen(),
          JobFormScreen.route: (_) => const JobFormScreen(),
          JobsListScreen.route: (_) => const JobsListScreen(),
          BookingScreen.route: (_) => const BookingScreen(),
          RootNav.route: (_) => const RootNav(),
          CustomerProfileScreen.route: (_) => const CustomerProfileScreen(),
          CustomerHistoryScreen.route: (_) => const CustomerHistoryScreen(),
          ProviderDashboardScreen.route: (_) => const ProviderDashboardScreen(),
          ProviderEarningsScreen.route: (_) => const ProviderEarningsScreen(),
          NotificationsScreen.route: (_) => const NotificationsScreen(),
        },
        builder: (context, child) {
          return Stack(
            children: [
              if (child != null) child,
              const Positioned.fill(child: SnowOverlay(flakes: 120)),
            ],
          );
        },
      ),
    );
  }
}
