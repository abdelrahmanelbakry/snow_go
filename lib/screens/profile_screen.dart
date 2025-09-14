import 'package:flutter/material.dart';
import 'login_screen.dart'; // replace with your actual login screen import

enum ProfileType { customer, provider }

class ProfileScreen extends StatelessWidget {
  final ProfileType profileType;

  const ProfileScreen({
    super.key,
    this.profileType = ProfileType.customer,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0E63F6);

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
            const Text('Profile',
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
        padding: const EdgeInsets.all(16),
        children: [
          // User Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: blue,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Abdelrahman Elbakry", // replace with Firebase user name
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "abdelrahman@example.com", // replace with Firebase email
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Common settings
          _ProfileOption(icon: Icons.edit, text: "Edit Profile", onTap: () {}),
          if (profileType == ProfileType.customer)
            _ProfileOption(icon: Icons.payment, text: "Payment Methods", onTap: () {}),
          _ProfileOption(icon: Icons.notifications_outlined, text: "Notifications", onTap: () {}),
          _ProfileOption(icon: Icons.help_outline, text: "Help & Support", onTap: () {}),
          _ProfileOption(icon: Icons.info_outline, text: "About SnowGo", onTap: () {}),

          // Provider-specific options
          if (profileType == ProfileType.provider) ...[
            _ProfileOption(icon: Icons.star_outline, text: "Reviews", onTap: () {}),
            _ProfileOption(icon: Icons.attach_money, text: "Earnings", onTap: () {}),
          ],

          const SizedBox(height: 40),

          // Logout button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
            child: const Text(
              "Log Out",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue.shade600),
      title: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
