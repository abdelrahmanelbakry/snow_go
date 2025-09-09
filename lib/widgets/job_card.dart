import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:snow_go/models/service_type.dart';
import '../models/job.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback? onTap;
  const JobCard({super.key, required this.job, this.onTap});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, MMM d • h:mm a');

    Widget statusPill(JobStatus s) {
      late Color bg, fg; late String label;
      switch (s) {
        case JobStatus.newRequest:
          label = 'New';        bg = const Color(0xFFE8F0FE); fg = const Color(0xFF1A73E8); break;
        case JobStatus.assigned:
          label = 'Assigned';   bg = const Color(0xFFEFF6FF); fg = const Color(0xFF2563EB); break;
        case JobStatus.inProgress:
          label = 'In progress';bg = const Color(0xFFFFF7ED); fg = const Color(0xFF9A3412); break;
        case JobStatus.completed:
          label = 'Done';       bg = const Color(0xFFDCFCE7); fg = const Color(0xFF14532D); break;
        case JobStatus.cancelled:
          label = 'Cancelled';  bg = const Color(0xFFFEE2E2); fg = const Color(0xFF7F1D1D); break;
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
        ),
      );
    }


    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Text(
                  '${job.customerName} · ${job.service.label}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              statusPill(job.status),
              const SizedBox(width: 10),
              Text(
                'CA\$ ${job.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0E63F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  job.address,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18),
              const SizedBox(width: 6),
              Text(df.format(job.scheduledAt), style: const TextStyle(fontSize: 16)),
            ],
          ),
        ]),
      ),
    );
  }
}
