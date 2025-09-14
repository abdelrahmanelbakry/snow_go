import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/atomic_job.dart';
import '../models/service_type.dart';
import '../core/atomic_state.dart';
import '../core/atomic_operations.dart';
import '../services/atomic_backend_service.dart';

/// Atomic jobs state
class JobsState {
  final Map<String, AtomicJob> jobs;
  final List<String> jobOrder;

  const JobsState({
    this.jobs = const {},
    this.jobOrder = const [],
  });

  JobsState copyWith({
    Map<String, AtomicJob>? jobs,
    List<String>? jobOrder,
  }) {
    return JobsState(
      jobs: jobs ?? this.jobs,
      jobOrder: jobOrder ?? this.jobOrder,
    );
  }

  List<AtomicJob> get sortedJobs {
    return jobOrder
        .map((id) => jobs[id])
        .where((job) => job != null)
        .cast<AtomicJob>()
        .toList();
  }
}

/// Atomic jobs provider with atomic operations
class AtomicJobsProvider extends AtomicState<JobsState> with AtomicOperationsMixin<JobsState> {
  final _uuid = const Uuid();
  final AtomicBackendService _backendService = AtomicBackendService();

  AtomicJobsProvider() : super(const JobsState()) {
    _initializeWithSeedData();
  }

  /// Initialize with seed data
  void _initializeWithSeedData() {
    final now = DateTime.now();
    final seedJobs = [
      AtomicJob.create(
        id: _uuid.v4(),
        customerName: 'Sarah Nolan',
        customerId: 'customer_1',
        address: '24 Winterberry Ave',
        service: ServiceType.driveway,
        price: 45.00,
        scheduledAt: now.add(const Duration(hours: 2)),
        notes: 'Driveway is steep; bring extra salt.',
      ),
      AtomicJob.create(
        id: _uuid.v4(),
        customerName: 'Mike Turner',
        customerId: 'customer_2',
        address: '17 Frost Lane',
        service: ServiceType.salting,
        price: 25.50,
        scheduledAt: now.add(const Duration(hours: 4, minutes: 30)),
      ).assignProvider('provider_1', reason: 'Auto-assigned for demo'),
    ];

    final jobsMap = {for (var job in seedJobs) job.id: job};
    final jobOrder = seedJobs
        .map((j) => j.id)
        .toList()
      ..sort((a, b) => jobsMap[a]!.scheduledAt.compareTo(jobsMap[b]!.scheduledAt));

    atomicUpdateSync((currentState) => JobsState(
      jobs: jobsMap,
      jobOrder: jobOrder,
    ));
  }

  /// Get all jobs sorted by schedule
  List<AtomicJob> get jobs => state.sortedJobs;

  /// Get job by ID
  AtomicJob? getJobById(String id) => state.jobs[id];

  /// Add job atomically via backend API
  Future<AtomicResult<AtomicJob>> addJob({
    required String customerName,
    required String customerId,
    required String address,
    required ServiceType service,
    required double price,
    required DateTime scheduledAt,
    bool addonSalting = false,
    String? notes,
  }) async {
    // Create job via backend API
    final result = await _backendService.createJobAtomic(
      customerName: customerName,
      customerId: customerId,
      address: address,
      service: service,
      price: price,
      scheduledAt: scheduledAt,
      addonSalting: addonSalting,
      notes: notes,
    );

    if (result.isSuccess && result.data != null) {
      // Update local state with the created job
      await atomicUpdate((currentState) async {
        final job = result.data!;
        final newJobs = Map<String, AtomicJob>.from(currentState.jobs);
        newJobs[job.id] = job;

        final newOrder = List<String>.from(currentState.jobOrder);
        newOrder.add(job.id);
        newOrder.sort((a, b) => newJobs[a]!.scheduledAt.compareTo(newJobs[b]!.scheduledAt));

        return currentState.copyWith(
          jobs: newJobs,
          jobOrder: newOrder,
        );
      });
    }

    return result;
  }

  /// Update job status atomically via backend API
  Future<AtomicResult<AtomicJob>> updateJobStatus(
    String jobId,
    JobStatus newStatus, {
    String? reason,
    String? userId,
  }) async {
    // Update status via backend API
    final result = await _backendService.changeJobStatusAtomic(
      jobId,
      newStatus,
      reason: reason,
      userId: userId,
    );

    if (result.isSuccess && result.data != null) {
      // Update local state with the updated job
      await atomicUpdate((currentState) async {
        final job = result.data!;
        final newJobs = Map<String, AtomicJob>.from(currentState.jobs);
        newJobs[jobId] = job;

        return currentState.copyWith(jobs: newJobs);
      });
    }

    return result;
  }

  /// Assign provider to job atomically via backend API
  Future<AtomicResult<AtomicJob>> assignProvider(
    String jobId,
    String providerId, {
    String? reason,
  }) async {
    // Assign provider via backend API
    final result = await _backendService.assignProviderAtomic(
      jobId,
      providerId,
      reason: reason,
    );

    if (result.isSuccess && result.data != null) {
      // Update local state with the updated job
      await atomicUpdate((currentState) async {
        final job = result.data!;
        final newJobs = Map<String, AtomicJob>.from(currentState.jobs);
        newJobs[jobId] = job;

        return currentState.copyWith(jobs: newJobs);
      });
    }

    return result;
  }

  /// Start job atomically
  Future<AtomicResult<AtomicJob>> startJob(String jobId, {String? reason}) async {
    return await updateJobStatus(jobId, JobStatus.inProgress, reason: reason);
  }

  /// Complete job atomically
  Future<AtomicResult<AtomicJob>> completeJob(String jobId, {String? reason}) async {
    return await updateJobStatus(jobId, JobStatus.completed, reason: reason);
  }

  /// Cancel job atomically
  Future<AtomicResult<AtomicJob>> cancelJob(
    String jobId, {
    String? reason,
    String? userId,
  }) async {
    return await updateJobStatus(
      jobId,
      JobStatus.cancelled,
      reason: reason,
      userId: userId,
    );
  }

  /// Update job details atomically via backend API
  Future<AtomicResult<AtomicJob>> updateJob(
    String jobId, {
    String? address,
    ServiceType? service,
    double? price,
    DateTime? scheduledAt,
    String? notes,
    bool? addonSalting,
  }) async {
    final updates = <String, dynamic>{};
    if (address != null) updates['address'] = address;
    if (service != null) updates['service'] = service.name;
    if (price != null) updates['price'] = price;
    if (scheduledAt != null) updates['scheduledAt'] = scheduledAt.toIso8601String();
    if (notes != null) updates['notes'] = notes;
    if (addonSalting != null) updates['addonSalting'] = addonSalting;

    if (updates.isEmpty) {
      return AtomicResult.failure('No updates provided');
    }

    // Update job via backend API
    final result = await _backendService.updateJobAtomic(jobId, updates);

    if (result.isSuccess && result.data != null) {
      // Update local state with the updated job
      await atomicUpdate((currentState) async {
        final job = result.data!;
        final newJobs = Map<String, AtomicJob>.from(currentState.jobs);
        newJobs[jobId] = job;

        // Resort if schedule changed
        List<String> newOrder = currentState.jobOrder;
        if (scheduledAt != null) {
          newOrder = List<String>.from(currentState.jobOrder);
          newOrder.sort((a, b) => newJobs[a]!.scheduledAt.compareTo(newJobs[b]!.scheduledAt));
        }

        return currentState.copyWith(
          jobs: newJobs,
          jobOrder: newOrder,
        );
      });
    }

    return result;
  }

  /// Load jobs from backend by status
  Future<AtomicResult<List<AtomicJob>>> loadJobsByStatus(JobStatus status) async {
    final result = await _backendService.getJobsByStatusAtomic(status);
    
    if (result.isSuccess && result.data != null) {
      // Update local state with loaded jobs
      await atomicUpdate((currentState) async {
        final newJobs = Map<String, AtomicJob>.from(currentState.jobs);
        final newOrder = List<String>.from(currentState.jobOrder);
        
        for (final job in result.data!) {
          newJobs[job.id] = job;
          if (!newOrder.contains(job.id)) {
            newOrder.add(job.id);
          }
        }
        
        newOrder.sort((a, b) => newJobs[a]!.scheduledAt.compareTo(newJobs[b]!.scheduledAt));
        
        return currentState.copyWith(
          jobs: newJobs,
          jobOrder: newOrder,
        );
      });
    }
    
    return result;
  }

  /// Load jobs from backend by customer
  Future<AtomicResult<List<AtomicJob>>> loadJobsByCustomer(String customerId) async {
    final result = await _backendService.getJobsByCustomerAtomic(customerId);
    
    if (result.isSuccess && result.data != null) {
      // Update local state with loaded jobs
      await atomicUpdate((currentState) async {
        final newJobs = Map<String, AtomicJob>.from(currentState.jobs);
        final newOrder = List<String>.from(currentState.jobOrder);
        
        for (final job in result.data!) {
          newJobs[job.id] = job;
          if (!newOrder.contains(job.id)) {
            newOrder.add(job.id);
          }
        }
        
        newOrder.sort((a, b) => newJobs[a]!.scheduledAt.compareTo(newJobs[b]!.scheduledAt));
        
        return currentState.copyWith(
          jobs: newJobs,
          jobOrder: newOrder,
        );
      });
    }
    
    return result;
  }

  /// Load jobs from backend by provider
  Future<AtomicResult<List<AtomicJob>>> loadJobsByProvider(String providerId) async {
    final result = await _backendService.getJobsByProviderAtomic(providerId);
    
    if (result.isSuccess && result.data != null) {
      // Update local state with loaded jobs
      await atomicUpdate((currentState) async {
        final newJobs = Map<String, AtomicJob>.from(currentState.jobs);
        final newOrder = List<String>.from(currentState.jobOrder);
        
        for (final job in result.data!) {
          newJobs[job.id] = job;
          if (!newOrder.contains(job.id)) {
            newOrder.add(job.id);
          }
        }
        
        newOrder.sort((a, b) => newJobs[a]!.scheduledAt.compareTo(newJobs[b]!.scheduledAt));
        
        return currentState.copyWith(
          jobs: newJobs,
          jobOrder: newOrder,
        );
      });
    }
    
    return result;
  }

  /// Delete job atomically via backend API
  Future<AtomicResult<void>> deleteJob(String jobId) async {
    final result = await _backendService.deleteJobAtomic(jobId);
    
    if (result.isSuccess) {
      // Remove from local state
      await atomicUpdate((currentState) async {
        final newJobs = Map<String, AtomicJob>.from(currentState.jobs);
        newJobs.remove(jobId);
        
        final newOrder = List<String>.from(currentState.jobOrder);
        newOrder.remove(jobId);
        
        return currentState.copyWith(
          jobs: newJobs,
          jobOrder: newOrder,
        );
      });
    }
    
    return result;
  }

  /// Get jobs by status
  List<AtomicJob> getJobsByStatus(JobStatus status) {
    return jobs.where((job) => job.status == status).toList();
  }

  /// Get jobs by provider
  List<AtomicJob> getJobsByProvider(String providerId) {
    return jobs.where((job) => job.providerId == providerId).toList();
  }

  /// Get jobs by customer
  List<AtomicJob> getJobsByCustomer(String customerId) {
    return jobs.where((job) => job.customerId == customerId).toList();
  }

  /// Execute all queued atomic operations
  Future<AtomicResult<List<AtomicOperation>>> commitPendingOperations() async {
    return await executeQueuedOperations();
  }

  /// Clear all jobs (for testing)
  void clearAllJobs() {
    atomicUpdateSync((currentState) => const JobsState());
  }
}
