
import 'package:flutter/material.dart';
import 'home_stub.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(body: Center(child: ElevatedButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeStub())), child: const Text('Mock Login'))));
  }
}
