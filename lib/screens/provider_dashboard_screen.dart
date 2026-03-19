import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jobs_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/atomic_job_card.dart';
import '../models/atomic_job.dart';

class ProviderDashboardScreen extends StatefulWidget {
  static const route = '/provider-dashboard';
  
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProviderJobs();
  }

  Future<void> _loadProviderJobs() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final jobsProvider = Provider.of<AtomicJobsProvider>(context, listen: false);
    
    if (authProvider.user != null && authProvider.isProvider) {
      // Load jobs for this provider
      await jobsProvider.loadJobsByProvider(authProvider.user!.uid);
    } else {
      // Load all available jobs for providers to accept
      await jobsProvider.loadJobsByStatus(JobStatus.newRequest);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0E63F6);
    const navy = Color(0xFF0E2B4D);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: blue,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/snowgo_mark_white.png', height: 28),
            const SizedBox(width: 8),
            const Text('Provider Dashboard',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'New'),
            Tab(text: 'Assigned'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats Overview
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Consumer<AtomicJobsProvider>(
              builder: (context, provider, child) {
                final jobs = provider.state.sortedJobs;
                final filteredJobs = jobs.where((job) => 
                  job.scheduledAt.day == DateTime.now().day &&
                  job.scheduledAt.month == DateTime.now().month &&
                  job.scheduledAt.year == DateTime.now().year
                ).length;
                
                final completedToday = jobs.where((job) => 
                  job.status == JobStatus.completed &&
                  job.updatedAt.day == DateTime.now().day &&
                  job.updatedAt.month == DateTime.now().month &&
                  job.updatedAt.year == DateTime.now().year
                ).length;

                final totalEarnings = jobs
                  .where((job) => job.status == JobStatus.completed)
                  .fold(0.0, (sum, job) => sum + job.price);

                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Today\'s Jobs',
                        filteredJobs.toString(),
                        Icons.today,
                        blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Completed',
                        completedToday.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Earnings',
                        'CA\$${totalEarnings.toStringAsFixed(0)}',
                        Icons.attach_money,
                        Colors.orange,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Job Lists by Status
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildJobsList(JobStatus.newRequest),
                _buildJobsList(JobStatus.assigned),
                _buildJobsList(JobStatus.inProgress),
                _buildJobsList(JobStatus.completed),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/provider-earnings'),
        backgroundColor: blue,
        icon: const Icon(Icons.analytics, color: Colors.white),
        label: const Text('Earnings', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList(JobStatus filterStatus) {
    return Consumer<AtomicJobsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Error: ${provider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadProviderJobs(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final jobs = provider.state.sortedJobs.where((job) => job.status == filterStatus).toList();

        if (jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStatusIcon(filterStatus),
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${_getStatusText(filterStatus).toLowerCase()} jobs',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return Column(
              children: [
                AtomicJobCard(
                  job: job,
                  showActions: true,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/job-details',
                    arguments: job.id,
                  ),
                ),
                if (index < jobs.length - 1) const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getStatusIcon(JobStatus status) {
    switch (status) {
      case JobStatus.newRequest:
        return Icons.new_releases;
      case JobStatus.assigned:
        return Icons.assignment;
      case JobStatus.inProgress:
        return Icons.work;
      case JobStatus.completed:
        return Icons.check_circle;
      case JobStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(JobStatus status) {
    switch (status) {
      case JobStatus.newRequest:
        return 'New Request';
      case JobStatus.assigned:
        return 'Assigned';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }
}
