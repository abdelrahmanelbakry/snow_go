
import 'package:flutter/material.dart';
import 'available_jobs_screen.dart';
import '../services/provider_location_service.dart';

class HomeStub extends StatelessWidget {
  const HomeStub({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('SnowGo Home')), body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ElevatedButton(onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> const AvailableJobsScreen())), child: const Text('Available Jobs')),
    ])));
  }
}
