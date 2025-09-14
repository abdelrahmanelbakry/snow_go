import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:snow_go/models/service_type.dart';
import '../providers/jobs_provider.dart';
import '../models/job.dart';
import '../widgets/status_pill.dart';
import '../widgets/section_title.dart';

class JobDetailsScreen extends StatelessWidget {
  static const route = '/job';
  const JobDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jobId = ModalRoute.of(context)!.settings.arguments as String;
    final provider = context.watch<JobsProvider>();
    final job = provider.byId(jobId)!;
    final df = DateFormat('EEE, MMM d • h:mm a');

    Widget infoRow(IconData icon, String text) => Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E63F6),
        elevation: 0,
        title: const Text('Job details', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            color: const Color(0xFFF7F7F9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${job.customerName} · ${job.service.label}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      StatusPill(status: job.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  infoRow(Icons.location_on_outlined, job.address),
                  const SizedBox(height: 6),
                  infoRow(Icons.schedule, df.format(job.scheduledAt)),
                  const SizedBox(height: 6),
                  infoRow(Icons.attach_money, 'CA\$ ${job.price.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),

          const SectionTitle('Notes'),
          if ((job.notes ?? '').isEmpty)
            const Text('—', style: TextStyle(color: Colors.black54))
          else
            Text(job.notes!),

          const SizedBox(height: 24),
          const SectionTitle('Actions'),
          _ActionButtons(job: job),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Job job;
  const _ActionButtons({required this.job});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<JobsProvider>();

    switch (job.status) {
      case JobStatus.newRequest:
        return Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => provider.updateStatus(job.id, JobStatus.assigned),
                child: const Text('Assign'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => provider.updateStatus(job.id, JobStatus.cancelled),
                child: const Text('Cancel'),
              ),
            ),
          ],
        );
      case JobStatus.assigned:
        return Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => provider.updateStatus(job.id, JobStatus.inProgress),
                child: const Text('Start job'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => provider.updateStatus(job.id, JobStatus.cancelled),
                child: const Text('Cancel'),
              ),
            ),
          ],
        );
      case JobStatus.inProgress:
        return Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => provider.updateStatus(job.id, JobStatus.completed),
                child: const Text('Mark complete'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => provider.updateStatus(job.id, JobStatus.cancelled),
                child: const Text('Cancel'),
              ),
            ),
          ],
        );
      case JobStatus.completed:
        return const Text('This job is completed.', style: TextStyle(color: Colors.black54));
      case JobStatus.cancelled:
        return const Text('This job is cancelled.', style: TextStyle(color: Colors.black54));
    }
  }
}
