import 'package:flutter/material.dart';
import 'package:snow_go/models/service_type.dart';
import '../models/job.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // mock jobs for now
  List<Job> _mockJobs() {
    return [
      Job(
        id: '1',
        address: '24 Winterberry Ave',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 2)),
        service: ServiceType.driveway,
        price: 45.0,
        status: JobStatus.completed,
        customerName: 'Mark',
      ),
      Job(
        id: '2',
        address: '17 Frost Lane',
        scheduledAt: DateTime.now().add(const Duration(hours: 4)),
        service: ServiceType.salting,
        price: 25.5,
        status: JobStatus.assigned,
        customerName: 'Mark',

      ),
      Job(
        id: '3',
        address: '88 Maple Road',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        service: ServiceType.driveway,
        addonSalting: true,
        price: 60.0,
        status: JobStatus.newRequest,
        customerName: 'Mark',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _mockJobs();
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
            const Text('History',
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
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return _HistoryCard(job: job);
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Job job;
  const _HistoryCard({required this.job});

  Color _statusColor(JobStatus status) {
    switch (status) {
      case JobStatus.completed:
        return Colors.green;
      case JobStatus.assigned:
        return Colors.orange;
      case JobStatus.inProgress:
        return Colors.blue;
      case JobStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(JobStatus status) {
    switch (status) {
      case JobStatus.completed:
        return Icons.check_circle;
      case JobStatus.assigned:
        return Icons.hourglass_bottom;
      case JobStatus.inProgress:
        return Icons.directions_run;
      case JobStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(job.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          // Left status icon
          Icon(
            _statusIcon(job.status),
            color: color,
            size: 28,
          ),
          const SizedBox(width: 12),
          // Middle: address and service
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.address,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  job.service.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Right: status label
          Text(
            job.status.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}