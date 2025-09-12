import 'package:flutter/material.dart';
import 'package:snow_go/screens/root_nav.dart';

/// Pass the details you just collected on the booking screen.
class BookingConfirmationScreen extends StatelessWidget {
  static const route = '/booking-confirmation';

  final String address;
  final DateTime scheduledAt;
  final bool addonSalting;     // for display if needed
  final String primaryService; // e.g. "Driveway"
  final double? price;         // optional
  final String? notes;         // optional

  const BookingConfirmationScreen({
    super.key,
    required this.address,
    required this.scheduledAt,
    required this.primaryService,
    this.addonSalting = false,
    this.price,
    this.notes,
  });

  String _formatDateTime(BuildContext context, DateTime dt) {
    final timeOfDay = TimeOfDay.fromDateTime(dt);
    final h = timeOfDay.hourOfPeriod.toString().padLeft(2, '0');
    final m = timeOfDay.minute.toString().padLeft(2, '0');
    final ampm = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '${_month(dt.month)} ${dt.day}, ${dt.year} • $h:$m $ampm';
  }

  String _month(int m) {
    const names = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return names[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0E63F6);
    const navy = Color(0xFF0E2B4D);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('SnowGo',
            style: TextStyle(
              color: navy,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            )),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const SizedBox(height: 8),

            // Big check in a blue circle
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 64),
              ),
            ),
            const SizedBox(height: 18),

            // Title + subtitle
            const Center(
              child: Text(
                'Booking Confirmed',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: navy,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Your driveway snow clearing has been\nconfirmed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Summary card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                children: [
                  _RowItem(
                    icon: Icons.home_outlined,
                    text: address,
                  ),
                  const Divider(height: 20),
                  _RowItem(
                    icon: Icons.event_outlined,
                    text: _formatDateTime(context, scheduledAt),
                  ),
                  const Divider(height: 20),
                  _RowItem(
                    icon: Icons.snowing, // swap for your shovel icon asset if you prefer
                    text: addonSalting
                        ? '$primaryService + Salting'
                        : primaryService,
                  ),
                  if (price != null) ...[
                    const Divider(height: 20),
                    _RowItem(
                      icon: Icons.payments_outlined,
                      text: 'CA\$ ${price!.toStringAsFixed(price! % 1 == 0 ? 0 : 2)}',
                    ),
                  ],
                  if (notes != null && notes!.trim().isNotEmpty) ...[
                    const Divider(height: 20),
                    _RowItem(
                      icon: Icons.notes_outlined,
                      text: notes!,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // OK button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: () {
                  // Close the flow; pop back to the first route or just pop once.
                  // Choose one of the following depending on your navigation:
                  // Navigator.of(context).pop(); // simple pop back to previous
                  Navigator.of(context).popUntil((route) => route.settings.name == RootNav.route);
                },
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RowItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6B7280)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
