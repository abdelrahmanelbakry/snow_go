import 'package:flutter/material.dart';
import 'package:snow_go/screens/booking_screen.dart';

import 'booking_confirmation_screen.dart';

class HomeScreen extends StatelessWidget {
  static const route = '/';
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0E63F6);
    const navy = Color(0xFF0E2B4D);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: blue,
        elevation: 0,
        titleSpacing: 0,
        automaticallyImplyLeading : false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/snowgo_mark_white.png', height: 28),
            const Text('SnowGo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                )),
          ],
        ),
        centerTitle: true,
        // leading: IconButton(
        //   icon: const Icon(Icons.menu, color: Colors.white),
        //   onPressed: () {}, // TODO: open drawer (optional)
        // ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Search over a subtle "map" hero
          Stack(
            children: [
              // Map placeholder (use your map widget later)
              Container(
                height: 210,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEAF2FA), Color(0xFFDDE7F4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(Icons.location_pin, size: 52, color: blue),
                ),
              ),
              Positioned.fill(
                top: 14,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x15000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search address',
                              border: InputBorder.none,
                            ),
                            textInputAction: TextInputAction.search,
                            onSubmitted: (v) {
                              // TODO: launch address search
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Greeting + CTA + quick services
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Good morning,\n',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: 'Abdelrahman',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: navy,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Primary CTA
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          fullscreenDialog: true, // 👈 gives you modal look
                          builder: (_) => const BookingScreen(),
                        ),
                      );

                      if (result != null) {
                        // After booking, go to confirmation
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => BookingConfirmationScreen(
                              address: result.address,
                              scheduledAt: result.scheduledAt,
                              primaryService: result.addonSalting
                                  ? '${result.primaryService} + Salting'
                                  : result.primaryService,
                              price: result.price,
                              notes: result.notes,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Book Snow Clearing'),
                  ),
                ),

                const SizedBox(height: 16),

                // Quick service tiles
                Row(
                  children: [
                    Expanded(
                      child: _ServiceTile(
                        icon: Icons.directions_car_rounded,
                        label: 'Driveway',
                        onTap: () {
                          // TODO: preselect driveway in booking flow
                          Navigator.pushNamed(context, BookingScreen.route);


                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ServiceTile(
                        icon: Icons.snowing, // or custom shovel/salt icon
                        label: 'Salting',
                        onTap: () {
                          // TODO: preselect salting in booking flow
                          Navigator.pushNamed(context, BookingScreen.route);

                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scheduled jobs preview
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                Text('Scheduled jobs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Spacer(),
                // Tap to open full list (History/Track)
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: const [
                _JobCard(title: 'Driveway • Today 4:00 PM', price: 'CA\$45.00'),
                SizedBox(width: 12),
                _JobCard(title: 'Salting • Tomorrow 9:00 AM', price: 'CA\$25.50'),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
      // bottomNavigationBar: NavigationBar(
      //   selectedIndex: 0,
      //   onDestinationSelected: (i) {
      //     // TODO: push to Track/Profile tabs; see RootNav below
      //   },
      //   destinations: const [
      //     NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
      //     NavigationDestination(icon: Icon(Icons.location_on_outlined), selectedIcon: Icon(Icons.location_on), label: 'Track'),
      //     NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      //   ],
      // ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ServiceTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 92,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: const Color(0xFF3B82F6)),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final String title;
  final String price;
  const _JobCard({required this.title, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFE6F0FF),
            child: Icon(Icons.calendar_today, size: 18, color: Color(0xFF0E63F6)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0E63F6))),
        ],
      ),
    );
  }
}
