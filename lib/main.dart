
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/snow_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  final first = prefs.getBool('isFirstLaunch') ?? true;
  runApp(SnowGoApp(isFirstLaunch: first));
}

class SnowGoApp extends StatelessWidget {
  final bool isFirstLaunch;
  const SnowGoApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnowGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Stack(children: [ isFirstLaunch ? const WelcomeScreen() : const LoginScreen(), const SnowOverlay() ]),
    );
  }
}
