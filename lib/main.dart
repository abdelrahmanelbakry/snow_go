import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/jobs_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/root_nav.dart';
import 'screens/job_form_screen.dart';
import 'screens/jobs_list_screen.dart';
import 'widgets/snow_overlay.dart';

void main() => runApp(const SnowGoApp());

class SnowGoApp extends StatelessWidget {
  const SnowGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AtomicJobsProvider(),
      child: MaterialApp(
        title: 'SnowGo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: false, // outlined fields & classic AppBar (closer to the mock)
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0E63F6),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
        ),
        initialRoute: LoginScreen.route,
        routes: {
          LoginScreen.route: (_) => const LoginScreen(),
          HomeScreen.route: (_) => const HomeScreen(),
          JobFormScreen.route: (_) => const JobFormScreen(),
          JobsListScreen.route: (_) => const JobsListScreen(),
          BookingScreen.route: (_) => const BookingScreen(),
          RootNav.route: (_) => const RootNav(),
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
