import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/jobs_provider.dart';
import 'screens/home_screen.dart';
import 'screens/job_form_screen.dart';
import 'screens/job_details_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/jobs_list_screen.dart';

void main() => runApp(const SnowGoApp());

class SnowGoApp extends StatelessWidget {
  const SnowGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JobsProvider(),
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
        initialRoute: HomeScreen.route,
        routes: {
          HomeScreen.route: (_) => const HomeScreen(),
          JobFormScreen.route: (_) => const JobFormScreen(),
          JobsListScreen.route: (_) => const JobsListScreen(),
        },
      ),
    );
  }
}
