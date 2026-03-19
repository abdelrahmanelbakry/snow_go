import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jobs_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/atomic_job_card.dart';
import '../models/atomic_job.dart';
import '../models/service_type.dart';

class CustomerHistoryScreen extends StatefulWidget {
  static const route = '/customer-history';
  
  const CustomerHistoryScreen({super.key});

  @override
  State<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCustomerJobs();
  }

  Future<void> _loadCustomerJobs() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final jobsProvider = Provider.of<AtomicJobsProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await jobsProvider.loadJobsByCustomer(authProvider.user!.uid);
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
            const Text('Service History',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by address or service...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Job History List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildJobsList(null), // All jobs
                _buildJobsList(JobStatus.completed),
                _buildJobsList(JobStatus.cancelled),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsList(JobStatus? filterStatus) {
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
                  onPressed: () => _loadCustomerJobs(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        var jobs = provider.state.sortedJobs;

        // Filter by status if specified
        if (filterStatus != null) {
          jobs = jobs.where((job) => job.status == filterStatus).toList();
        }

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          jobs = jobs.where((job) =>
              job.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              job.service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              job.customerName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        }

        // Sort by date (newest first)
        jobs.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

        if (jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  filterStatus == JobStatus.completed ? Icons.check_circle_outline :
                  filterStatus == JobStatus.cancelled ? Icons.cancel_outlined :
                  Icons.history,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty ? 'No jobs match your search' :
                  filterStatus == JobStatus.completed ? 'No completed jobs yet' :
                  filterStatus == JobStatus.cancelled ? 'No cancelled jobs' :
                  'No service history yet',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                if (_searchQuery.isEmpty && filterStatus == null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Book your first snow clearing service!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
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
              key: ValueKey(job.id),
              children: [
                AtomicJobCard(
                  job: job,
                  showActions: false,
                  onTap: () => _showJobDetails(job),
                ),
                if (index < jobs.length - 1) const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }

  void _showJobDetails(AtomicJob job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _buildJobDetailsSheet(job, scrollController),
      ),
    );
  }

  Widget _buildJobDetailsSheet(AtomicJob job, ScrollController scrollController) {
    const blue = Color(0xFF0E63F6);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Job Details',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                _buildDetailRow(Icons.person, 'Customer', job.customerName),
                _buildDetailRow(Icons.location_on, 'Address', job.address),
                _buildDetailRow(
                  job.service == ServiceType.driveway ? Icons.directions_car : Icons.snowing,
                  'Service',
                  '${job.service.name}${job.addonSalting ? ' + Salting' : ''}',
                ),
                _buildDetailRow(Icons.attach_money, 'Price', 'CA\$${job.price.toStringAsFixed(2)}'),
                _buildDetailRow(Icons.schedule, 'Scheduled', _formatDateTime(job.scheduledAt)),
                _buildDetailRow(Icons.info_outline, 'Status', _getStatusText(job.status)),
                if (job.notes?.isNotEmpty == true)
                  _buildDetailRow(Icons.notes, 'Notes', job.notes!),
                _buildDetailRow(Icons.update, 'Last Updated', _formatDateTime(job.updatedAt)),
                _buildDetailRow(Icons.tag, 'Job ID', job.id),
              ],
            ),
          ),

          // Actions
          if (job.status == JobStatus.completed) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to booking with same details
                  Navigator.pushNamed(context, '/booking', arguments: {
                    'initialAddress': job.address,
                    'repeatBooking': true,
                  });
                },
                icon: const Icon(Icons.repeat),
                label: const Text('Book Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
