import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/jobs_provider.dart';
import '../providers/auth_provider.dart';
import '../models/atomic_job.dart';
import '../models/service_type.dart';

class ProviderEarningsScreen extends StatefulWidget {
  static const route = '/provider-earnings';
  
  const ProviderEarningsScreen({super.key});

  @override
  State<ProviderEarningsScreen> createState() => _ProviderEarningsScreenState();
}

class _ProviderEarningsScreenState extends State<ProviderEarningsScreen> {
  String _selectedPeriod = 'This Week';
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'All Time'];

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
            const Text('Earnings',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
      body: Consumer2<AtomicJobsProvider, AuthProvider>(
        builder: (context, provider, authProvider, child) {
          final completedJobs = provider.state.sortedJobs.where((job) => 
            job.status == JobStatus.completed &&
            job.providerId == authProvider.user?.uid
          ).toList();

          final filteredJobs = _filterJobsByPeriod(completedJobs);
          final totalEarnings = filteredJobs.fold(0.0, (sum, job) => sum + job.price);
          final averageJobValue = filteredJobs.isEmpty ? 0.0 : totalEarnings / filteredJobs.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: _periods.map((period) {
                      final isSelected = period == _selectedPeriod;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPeriod = period),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: Text(
                              period,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? blue : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Earnings Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildEarningsCard(
                        'Total Earnings',
                        'CA\$${totalEarnings.toStringAsFixed(2)}',
                        Icons.attach_money,
                        blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEarningsCard(
                        'Jobs Completed',
                        filteredJobs.length.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildEarningsCard(
                        'Average Job',
                        'CA\$${averageJobValue.toStringAsFixed(2)}',
                        Icons.trending_up,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEarningsCard(
                        'Success Rate',
                        '${_calculateSuccessRate(provider.state.sortedJobs)}%',
                        Icons.star,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Recent Completed Jobs
                Text(
                  'Recent Completed Jobs',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                if (filteredJobs.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(
                          Icons.work_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No completed jobs in $_selectedPeriod',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredJobs.map((job) => _buildJobEarningCard(job)).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEarningsCard(String title, String value, IconData icon, Color color) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, color: color, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobEarningCard(AtomicJob job) {
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              job.service == ServiceType.driveway 
                  ? Icons.directions_car 
                  : Icons.snowing,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  job.address,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(job.updatedAt),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'CA\$${job.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
              Text(
                job.service.name,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<AtomicJob> _filterJobsByPeriod(List<AtomicJob> jobs) {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case 'Today':
        return jobs.where((job) =>
            job.updatedAt.day == now.day &&
            job.updatedAt.month == now.month &&
            job.updatedAt.year == now.year).toList();
      
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return jobs.where((job) =>
            job.updatedAt.isAfter(weekStart) &&
            job.updatedAt.isBefore(now.add(const Duration(days: 1)))).toList();
      
      case 'This Month':
        return jobs.where((job) =>
            job.updatedAt.month == now.month &&
            job.updatedAt.year == now.year).toList();
      
      case 'All Time':
      default:
        return jobs;
    }
  }

  int _calculateSuccessRate(List<AtomicJob> allJobs) {
    if (allJobs.isEmpty) return 0;
    
    final completedJobs = allJobs.where((job) => job.status == JobStatus.completed).length;
    final totalJobs = allJobs.where((job) => 
        job.status == JobStatus.completed || job.status == JobStatus.cancelled).length;
    
    if (totalJobs == 0) return 0;
    
    return ((completedJobs / totalJobs) * 100).round();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
