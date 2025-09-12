import 'dart:async';
import 'package:flutter/material.dart';

class CounterOfferApprovalScreen extends StatefulWidget {
  const CounterOfferApprovalScreen({super.key});

  @override
  State<CounterOfferApprovalScreen> createState() =>
      _CounterOfferApprovalScreenState();
}

class _CounterOfferApprovalScreenState
    extends State<CounterOfferApprovalScreen> {
  static const blue = Color(0xFF0E63F6);
  static const navy = Color(0xFF0E2B4D);

  late Timer _timer;
  Duration _remaining = const Duration(minutes: 10);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds > 0) {
        setState(() {
          _remaining = _remaining - const Duration(seconds: 1);
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining.inSeconds == 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: blue,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "assets/snowgo_mark_white.png",
              height: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              "SnowGo",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Counter Offer Details
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Counter Offer",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: navy),
                      SizedBox(width: 8),
                      Text("90 Main St."),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: navy),
                      SizedBox(width: 8),
                      Text("Sep 13, 2025 • 6:00 PM"),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.attach_money, color: navy),
                      SizedBox(width: 8),
                      Text("CA\$ 55.00"),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.notes_outlined, color: navy),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text("Please clear side path"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Timer or expired message
          if (!isExpired) ...[
            Text(
              "You have ${_formatTime(_remaining)} left to respond to this counter offer.",
              style: const TextStyle(fontSize: 16, color: navy),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            const Text(
              "This counter offer has expired.",
              style: TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 32),

          // Action buttons
          if (!isExpired) ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                // TODO: handle accept
              },
              child: const Text("Accept Offer",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                // TODO: handle reject
              },
              child: const Text("Reject Offer",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),

      // Root Nav Bar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
