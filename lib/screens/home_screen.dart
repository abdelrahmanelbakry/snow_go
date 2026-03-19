import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jobs_provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../widgets/atomic_job_card.dart';
import 'booking_screen.dart';
import 'provider_dashboard_screen.dart';
import '../widgets/jobs_map_widget.dart';

class HomeScreen extends StatefulWidget {
  static const String route = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Jobs are already initialized with seed data in AtomicJobsProvider constructor
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0E63F6);

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isProvider = authProvider.isProvider;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: blue,
            elevation: 0,
            titleSpacing: 0,
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/snowgo_mark_white.png', height: 28),
                Text(isProvider ? 'SnowGo Provider' : 'SnowGo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    )),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle, color: Colors.white),
                onSelected: (value) {
                  if (value == 'logout') {
                    authProvider.signOut();
                  } else if (value == 'switch_role') {
                    _showRoleSwitchDialog(context, authProvider);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'switch_role',
                    child: Text('Switch to ${isProvider ? 'Customer' : 'Provider'}'),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Text('Logout'),
                  ),
                ],
              ),
            ],
          ),
          body: isProvider ? _buildProviderView(context) : _buildCustomerView(context),
        );
      },
    );
  }

  Widget _buildCustomerView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          // Map section
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Consumer<AtomicJobsProvider>(
                builder: (context, jobsProvider, child) {
                  return JobsMapWidget(
                    jobs: jobsProvider.state.sortedJobs,
                  );
                },
              ),
            ),
          ),

          // Quick actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ServiceTile(
                        icon: Icons.directions_car_rounded,
                        label: 'Driveway',
                        onTap: () {
                          Navigator.pushNamed(context, BookingScreen.route);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ServiceTile(
                        icon: Icons.snowing,
                        label: 'Salting',
                        onTap: () {
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
              ],
            ),
          ),
          const SizedBox(height: 10),
          Consumer<AtomicJobsProvider>(
            builder: (context, jobsProvider, child) {
              if (jobsProvider.isLoading) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (jobsProvider.error != null) {
                return SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'Error: ${jobsProvider.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              final upcomingJobs = jobsProvider.jobs
                  .where((job) => job.scheduledAt.isAfter(DateTime.now()))
                  .take(3)
                  .toList();

              if (upcomingJobs.isEmpty) {
                return const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text('No upcoming jobs'),
                  ),
                );
              }

              return SizedBox(
                height: 180,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: upcomingJobs.length,
                  itemBuilder: (context, index) {
                    final job = upcomingJobs[index];
                    return Container(
                      width: 260,
                      margin: EdgeInsets.only(right: index < upcomingJobs.length - 1 ? 12 : 0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: AtomicJobCard(
                          job: job,
                          showActions: false,
                          compact: true,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 18),
        ],
      );
  }

  Widget _buildProviderView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Provider Dashboard Summary
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Provider Dashboard',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Available Jobs',
                      value: '12',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Completed',
                      value: '45',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Quick Actions for Providers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ServiceTile(
                      icon: Icons.work_outline,
                      label: 'View Jobs',
                      onTap: () {
                        Navigator.pushNamed(context, ProviderDashboardScreen.route);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ServiceTile(
                      icon: Icons.attach_money,
                      label: 'Earnings',
                      onTap: () {
                        Navigator.pushNamed(context, '/provider-earnings');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  void _showRoleSwitchDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Switch to ${authProvider.isProvider ? 'Customer' : 'Provider'}?'),
        content: Text(
          'You are currently a ${authProvider.isProvider ? 'Provider' : 'Customer'}. '
          'Would you like to switch to ${authProvider.isProvider ? 'Customer' : 'Provider'} mode?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newRole = authProvider.isProvider ? UserRole.customer : UserRole.provider;
              authProvider.updateUserRole(newRole);
              Navigator.pop(context);
            },
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
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
