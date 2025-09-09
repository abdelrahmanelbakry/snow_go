import 'package:flutter/material.dart';
import '../models/job.dart';

class StatusPill extends StatelessWidget {
  final JobStatus status;
  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;
    switch (status) {
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
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
