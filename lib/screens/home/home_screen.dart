import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("SnowGo"),
        actions: [
          IconButton(
            tooltip: "Sign out",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Hi ${user.email}",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.primary.withOpacity(.1),
                child: Icon(Icons.ac_unit_rounded, color: cs.primary),
              ),
              title: const Text("Post a new snow clearing request"),
              subtitle: const Text("Set your driveway size, price and time"),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: () {
                // TODO: navigate to create-job screen
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.secondaryContainer,
                child: Icon(Icons.map_rounded, color: cs.onSecondaryContainer),
              ),
              title: const Text("Track provider"),
              subtitle: const Text("Live map when a provider is en route"),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: () {
                // TODO: navigate to map screen
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.tertiaryContainer,
                child: Icon(Icons.history_rounded, color: cs.onTertiaryContainer),
              ),
              title: const Text("My jobs"),
              subtitle: const Text("See statuses, offers and history"),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: () {
                // TODO: navigate to jobs list
              },
            ),
          ),
        ],
      ),
    );
  }
}
