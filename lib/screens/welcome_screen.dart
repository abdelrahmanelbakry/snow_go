
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  Future<void> _gotIt(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);
    if (context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
  @override Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [ Image.asset('assets/logo.png', height:120), const SizedBox(height:16), const Text('SnowGo', style: TextStyle(fontSize:28)), const SizedBox(height:8), ElevatedButton(onPressed: ()=>_gotIt(context), child: const Text('Get Started')) ])));
  }
}
