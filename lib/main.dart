import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snow_go/screens/customer_signup_screen.dart';
import 'providers/jobs_provider.dart';
import 'screens/home_screen.dart';
import 'screens/job_form_screen.dart';
import 'screens/job_details_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/jobs_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/provider_signup_screen.dart';
import 'screens/customer_signup_screen.dart';

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
        initialRoute: LoginScreen.route,
        routes: {
          LoginScreen.route: (_) => const LoginScreen(),
          HomeScreen.route: (_) => const HomeScreen(),
          JobFormScreen.route: (_) => const JobFormScreen(),
          JobsListScreen.route: (_) => const JobsListScreen(),
          ProviderSignupScreen.route: (_) => const ProviderSignupScreen(),
          CustomerSignupScreen.route: (_) => const CustomerSignupScreen(),
        },
      ),
    );
  }
}
