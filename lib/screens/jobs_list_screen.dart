import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jobs_provider.dart';
import '../widgets/job_card.dart';
import 'job_details_screen.dart';
import 'job_form_screen.dart';

class JobsListScreen extends StatelessWidget {
  static const route = '/jobslist';
  const JobsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobsProvider>().jobs;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E63F6),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'SnowGo',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, JobFormScreen.route),
        icon: const Icon(Icons.add),
        label: const Text('New Job'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: jobs.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.ac_unit_outlined, size: 64, color: Color(0xFF0E63F6)),
                  SizedBox(height: 12),
                  Text('No jobs yet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text('Create your first Driveway or Salting job.', style: TextStyle(color: Color(0xFF6B7280))),
                ],
              ),
            ),
          )
              : ListView.separated(
            itemBuilder: (_, i) => JobCard(
              job: jobs[i],
              onTap: () => Navigator.pushNamed(
                  context, JobDetailsScreen.route, arguments: jobs[i].id),
            ),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: jobs.length,
          ),
        ),
      ),
    );
  }
}
