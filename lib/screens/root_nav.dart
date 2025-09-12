// lib/screens/root_nav.dart
import 'package:flutter/material.dart';
import 'counter_offer_approval_screen.dart';
import 'counter_offer_screeen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'provider_job_requests_screen.dart';

class RootNav extends StatefulWidget {
  static const route = '/root';
  const RootNav({super.key});
  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _index = 0;

  final _pages = const [
    //CounterOfferApprovalScreen(),
    //CounterOfferScreen(),
    // ProviderJobRequestsScreen(),
    HomeScreen(),
    HistoryScreen(),
    ProfileScreen(profileType: ProfileType.provider,),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.manage_history_outlined), selectedIcon: Icon(Icons.history_outlined), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
