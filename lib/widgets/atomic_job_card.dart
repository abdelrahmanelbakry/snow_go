import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/atomic_job.dart';
import '../models/service_type.dart';
import '../providers/jobs_provider.dart';
import '../providers/auth_provider.dart';

/// Atomic job card widget with optimistic updates
class AtomicJobCard extends StatefulWidget {
  final AtomicJob job;
  final VoidCallback? onTap;
  final bool showActions;
  final bool compact;

  const AtomicJobCard({
    super.key,
    required this.job,
    this.onTap,
    this.showActions = true,
    this.compact = false,
  });

  @override
  State<AtomicJobCard> createState() => _AtomicJobCardState();
}

class _AtomicJobCardState extends State<AtomicJobCard> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0E63F6);
    const navy = Color(0xFF0E2B4D);

    if (widget.compact) {
      return _buildCompactCard(context, blue, navy);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              Row(
                children: [
                  _StatusChip(status: widget.job.status),
                  const Spacer(),
                  if (_isUpdating)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  Text(
                    'v${widget.job.version}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer info
              Row(
                children: [
                  const Icon(Icons.person_outline, color: navy, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.job.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Address
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: navy, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.job.address,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Service and price
              Row(
                children: [
                  Icon(
                    widget.job.service == ServiceType.driveway
                        ? Icons.directions_car_rounded
                        : Icons.snowing,
                    color: navy,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.job.service.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.job.addonSalting) ...[
                    const Text(' + '),
                    const Icon(Icons.snowing, size: 16, color: navy),
                    const Text('Salting'),
                  ],
                  const Spacer(),
                  Text(
                    'CA\$${widget.job.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: blue,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Schedule
              Row(
                children: [
                  const Icon(Icons.schedule, color: navy, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatSchedule(widget.job.scheduledAt),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),

              // Notes
              if (widget.job.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_outlined, color: navy, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.job.notes!,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ],

              // Actions
              if (widget.showActions) ...[
                const SizedBox(height: 16),
                _buildActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, Color blue, Color navy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status and price row
              Row(
                children: [
                  _StatusChip(status: widget.job.status),
                  const Spacer(),
                  Text(
                    'CA\$${widget.job.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: blue,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Customer name
              Text(
                widget.job.customerName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),

              // Service and address
              Row(
                children: [
                  Icon(
                    widget.job.service == ServiceType.driveway
                        ? Icons.directions_car_rounded
                        : Icons.snowing,
                    color: navy,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.job.address,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    switch (widget.job.status) {
      case JobStatus.newRequest:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isUpdating ? null : () => _cancelJob(context),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isUpdating ? null : () => _assignJob(context),
                child: const Text('Assign'),
              ),
            ),
          ],
        );

      case JobStatus.assigned:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isUpdating ? null : () => _cancelJob(context),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isUpdating ? null : () => _startJob(context),
                child: const Text('Start'),
              ),
            ),
          ],
        );

      case JobStatus.inProgress:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isUpdating ? null : () => _completeJob(context),
            child: const Text('Complete'),
          ),
        );

      case JobStatus.completed:
      case JobStatus.cancelled:
        return const SizedBox.shrink();
    }
  }

  Future<void> _assignJob(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to accept jobs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    await _performAtomicOperation(
      context,
      () => Provider.of<AtomicJobsProvider>(context, listen: false).assignProvider(
        widget.job.id,
        currentUser.uid,
        reason: 'Accepted by provider',
      ),
      'Job accepted successfully',
      'Failed to accept job',
    );
  }

  Future<void> _startJob(BuildContext context) async {
    await _performAtomicOperation(
      context,
      () => Provider.of<AtomicJobsProvider>(context, listen: false).startJob(
        widget.job.id,
        reason: 'Started via UI',
      ),
      'Job started successfully',
      'Failed to start job',
    );
  }

  Future<void> _completeJob(BuildContext context) async {
    await _performAtomicOperation(
      context,
      () => Provider.of<AtomicJobsProvider>(context, listen: false).completeJob(
        widget.job.id,
        reason: 'Completed via UI',
      ),
      'Job completed successfully',
      'Failed to complete job',
    );
  }

  Future<void> _cancelJob(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Job'),
        content: const Text('Are you sure you want to cancel this job?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;
      
      await _performAtomicOperation(
        context,
        () => Provider.of<AtomicJobsProvider>(context, listen: false).cancelJob(
          widget.job.id,
          reason: 'Cancelled via UI',
          userId: currentUser?.uid ?? 'unknown',
        ),
        'Job cancelled successfully',
        'Failed to cancel job',
      );
    }
  }

  Future<void> _performAtomicOperation(
    BuildContext context,
    Future<dynamic> Function() operation,
    String successMessage,
    String errorMessage,
  ) async {
    setState(() => _isUpdating = true);

    try {
      final result = await operation();
      
      if (result != null && result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$errorMessage: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  String _formatSchedule(DateTime scheduledAt) {
    final now = DateTime.now();
    final difference = scheduledAt.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} days from now';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours from now';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes from now';
    } else {
      return 'Now';
    }
  }
}

class _StatusChip extends StatelessWidget {
  final JobStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case JobStatus.newRequest:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        label = 'New Request';
        break;
      case JobStatus.assigned:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        label = 'Assigned';
        break;
      case JobStatus.inProgress:
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade700;
        label = 'In Progress';
        break;
      case JobStatus.completed:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        label = 'Completed';
        break;
      case JobStatus.cancelled:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
