import 'package:flutter/material.dart';
import 'counter_offer_screeen.dart';

class ProviderJobRequestsScreen extends StatefulWidget {
  const ProviderJobRequestsScreen({super.key});

  @override
  State<ProviderJobRequestsScreen> createState() =>
      _ProviderJobRequestsScreenState();
}

class _ProviderJobRequestsScreenState extends State<ProviderJobRequestsScreen> {
  static const blue = Color(0xFF0E63F6);
  static const navy = Color(0xFF0E2B4D);

  String selectedRadius = "10km";
  String selectedSort = "Soonest";

  final jobs = [
    {
      "address": "90 Main St.",
      "date": "Sep 12, 2025 • 4:00 PM",
      "price": 45.0,
      "notes": "Please clear side path"
    },
    {
      "address": "12 Queen Ave.",
      "date": "Sep 12, 2025 • 8:00 AM",
      "price": 60.0,
      "notes": "Driveway and walkway"
    },
    {
      "address": "77 King’s Rd.",
      "date": "Sep 13, 2025 • 2:00 PM",
      "price": 40.0,
      "notes": ""
    },
  ];

  void _clearFilters() {
    setState(() {
      selectedRadius = "10km";
      selectedSort = "Soonest";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: blue,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/snowgo_mark_white.png", height: 28),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Filters",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Clear Filters pill
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text("Clear"),
                          selected: false,
                          labelStyle: const TextStyle(
                            color: blue,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: Colors.white,
                          shape: const StadiumBorder(
                            side: BorderSide(color: blue, width: 1.5),
                          ),
                          onSelected: (_) => _clearFilters(),
                        ),
                      ),
                      // Radius options
                      ...["5km", "10km", "20km"].map((radius) {
                        final isSelected = selectedRadius == radius;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(radius),
                            selected: isSelected,
                            selectedColor: blue,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : blue,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: Colors.white,
                            shape: const StadiumBorder(
                              side: BorderSide(color: blue, width: 1.5),
                            ),
                            onSelected: (_) {
                              setState(() => selectedRadius = radius);
                            },
                          ),
                        );
                      }).toList(),
                      const SizedBox(width: 16),
                      // Sort options
                      ...["Soonest", "Highest Price", "Nearest"].map((sort) {
                        final isSelected = selectedSort == sort;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(sort),
                            selected: isSelected,
                            selectedColor: blue,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : blue,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: Colors.white,
                            shape: const StadiumBorder(
                              side: BorderSide(color: blue, width: 1.5),
                            ),
                            onSelected: (_) {
                              setState(() => selectedSort = sort);
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Active filters with removable chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                if (selectedRadius.isNotEmpty)
                  Chip(
                    label: Text(selectedRadius),
                    backgroundColor: blue.withOpacity(0.1),
                    labelStyle: const TextStyle(color: blue),
                    deleteIcon: const Icon(Icons.close, size: 18, color: blue),
                    onDeleted: () {
                      setState(() => selectedRadius = "10km");
                    },
                  ),
                if (selectedSort.isNotEmpty)
                  Chip(
                    label: Text(selectedSort),
                    backgroundColor: blue.withOpacity(0.1),
                    labelStyle: const TextStyle(color: blue),
                    deleteIcon: const Icon(Icons.close, size: 18, color: blue),
                    onDeleted: () {
                      setState(() => selectedSort = "Soonest");
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Job list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.location_on_outlined, color: navy),
                          const SizedBox(width: 8),
                          Expanded(child: Text(job["address"].toString())),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.calendar_today_outlined, color: navy),
                          const SizedBox(width: 8),
                          Text(job["date"].toString()),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.attach_money, color: navy),
                          const SizedBox(width: 8),
                          Text("CA\$ ${job["price"]}"),
                        ]),
                        if ((job["notes"] as String).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.notes_outlined, color: navy),
                            const SizedBox(width: 8),
                            Expanded(child: Text(job["notes"].toString()
                            )),
                          ]),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: blue),
                                  foregroundColor: blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CounterOfferScreen(
                                        address: job["address"]!,
                                        requestedAt: DateTime.now(),
                                        requestedPrice: job["price"] as double,
                                        notes: job["notes"] as String,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text("Counter Offer"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {
                                  // TODO: Accept request logic
                                },
                                child: const Text("Accept"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
