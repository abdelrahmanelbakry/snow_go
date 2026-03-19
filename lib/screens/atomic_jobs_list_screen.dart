import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jobs_provider.dart';
import '../models/atomic_job.dart';
import '../widgets/atomic_job_card.dart';

/// Atomic jobs list screen with filtering and sorting
class AtomicJobsListScreen extends StatefulWidget {
  static const route = '/atomic-jobs';
  
  const AtomicJobsListScreen({super.key});

  @override
  State<AtomicJobsListScreen> createState() => _AtomicJobsListScreenState();
}

class _AtomicJobsListScreenState extends State<AtomicJobsListScreen> {
  JobStatus? _selectedStatus;
  String _sortBy = 'schedule'; // 'schedule', 'price', 'status'
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0E63F6);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: blue,
        title: const Text('Jobs'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                if (value == _sortBy) {
                  _ascending = !_ascending;
                } else {
                  _sortBy = value;
                  _ascending = true;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'schedule',
                child: Text('Sort by Schedule'),
              ),
              const PopupMenuItem(
                value: 'price',
                child: Text('Sort by Price'),
              ),
              const PopupMenuItem(
                value: 'status',
                child: Text('Sort by Status'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _selectedStatus == null,
                  onSelected: () => setState(() => _selectedStatus = null),
                ),
                const SizedBox(width: 8),
                ...JobStatus.values.map((status) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: _getStatusLabel(status),
                    selected: _selectedStatus == status,
                    onSelected: () => setState(() => _selectedStatus = status),
                  ),
                )),
              ],
            ),
          ),
          
          // Jobs list
          Expanded(
            child: Consumer<AtomicJobsProvider>(
              builder: (context, jobsProvider, child) {
                if (jobsProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (jobsProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${jobsProvider.error}'),
                        ElevatedButton(
                          onPressed: () => jobsProvider.clearAllJobs(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                return _buildJobsList(jobsProvider);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: blue,
        onPressed: () => _showAddJobDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildJobsList(AtomicJobsProvider jobsProvider) {
    var jobs = jobsProvider.jobs;

    // Apply status filter
    if (_selectedStatus != null) {
      jobs = jobs.where((job) => job.status == _selectedStatus).toList();
    }

    // Apply sorting
    jobs.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'status':
          comparison = a.status.index.compareTo(b.status.index);
          break;
        case 'schedule':
        default:
          comparison = a.scheduledAt.compareTo(b.scheduledAt);
          break;
      }
      return _ascending ? comparison : -comparison;
    });

    if (jobs.isEmpty) {
      return const Center(
        child: Text('No jobs found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return AtomicJobCard(
          job: job,
          onTap: () => _showJobDetails(context, job),
        );
      },
    );
  }

  void _showJobDetails(BuildContext context, AtomicJob job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Job Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow('ID', job.id),
                      _DetailRow('Customer', job.customerName),
                      _DetailRow('Address', job.address),
                      _DetailRow('Service', job.service.name),
                      _DetailRow('Price', 'CA\$${job.price.toStringAsFixed(2)}'),
                      _DetailRow('Scheduled', job.scheduledAt.toString()),
                      _DetailRow('Status', _getStatusLabel(job.status)),
                      _DetailRow('Version', job.version.toString()),
                      if (job.notes?.isNotEmpty == true)
                        _DetailRow('Notes', job.notes!),
                      if (job.providerId != null)
                        _DetailRow('Provider', job.providerId!),
                      
                      const SizedBox(height: 24),
                      Text(
                        'Status History',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...job.statusHistory.map((transition) => Card(
                        child: ListTile(
                          title: Text('${_getStatusLabel(transition.from)} → ${_getStatusLabel(transition.to)}'),
                          subtitle: Text(transition.reason ?? 'No reason provided'),
                          trailing: Text(
                            transition.timestamp.toString().substring(0, 19),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _DetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showAddJobDialog(BuildContext context) {
    // This would open a form to add a new job
    // For now, just show a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Job'),
        content: const Text('Job creation form would go here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(JobStatus status) {
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0E63F6);
    
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: blue.withOpacity(0.2),
      checkmarkColor: blue,
      labelStyle: TextStyle(
        color: selected ? blue : null,
        fontWeight: selected ? FontWeight.w600 : null,
      ),
    );
  }
}
