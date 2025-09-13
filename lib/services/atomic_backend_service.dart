import '../models/atomic_job.dart';
import '../models/service_type.dart';
import '../core/atomic_state.dart';
import 'http_client_service.dart';

/// Service that handles atomic operations through the backend API
/// Replaces direct Firebase operations with HTTP API calls
class AtomicBackendService {
  final HttpClientService _httpClient = HttpClientService();

  // Singleton pattern
  static final AtomicBackendService _instance = AtomicBackendService._internal();
  factory AtomicBackendService() => _instance;
  AtomicBackendService._internal();

  /// Create a new job atomically
  Future<AtomicResult<AtomicJob>> createJobAtomic({
    required String customerName,
    required String customerId,
    required String address,
    required ServiceType service,
    required double price,
    required DateTime scheduledAt,
    bool addonSalting = false,
    String? notes,
  }) async {
    return await _httpClient.createJob(
      customerName: customerName,
      customerId: customerId,
      address: address,
      service: service,
      price: price,
      scheduledAt: scheduledAt,
      addonSalting: addonSalting,
      notes: notes,
    );
  }

  /// Update job atomically with optimistic locking
  Future<AtomicResult<AtomicJob>> updateJobAtomic(
    String jobId,
    Map<String, dynamic> updates,
  ) async {
    return await _httpClient.updateJob(jobId, updates);
  }

  /// Change job status atomically with validation
  Future<AtomicResult<AtomicJob>> changeJobStatusAtomic(
    String jobId,
    JobStatus newStatus, {
    String? reason,
    String? userId,
  }) async {
    return await _httpClient.changeJobStatus(
      jobId,
      newStatus,
      reason: reason,
      userId: userId,
    );
  }

  /// Assign provider to job atomically
  Future<AtomicResult<AtomicJob>> assignProviderAtomic(
    String jobId,
    String providerId, {
    String? reason,
  }) async {
    return await _httpClient.assignProvider(
      jobId,
      providerId,
      reason: reason,
    );
  }

  /// Get job by ID
  Future<AtomicResult<AtomicJob?>> getJobAtomic(String jobId) async {
    return await _httpClient.getJob(jobId);
  }

  /// Get jobs by status
  Future<AtomicResult<List<AtomicJob>>> getJobsByStatusAtomic(JobStatus status) async {
    return await _httpClient.getJobsByStatus(status);
  }

  /// Get jobs by customer
  Future<AtomicResult<List<AtomicJob>>> getJobsByCustomerAtomic(String customerId) async {
    return await _httpClient.getJobsByCustomer(customerId);
  }

  /// Get jobs by provider
  Future<AtomicResult<List<AtomicJob>>> getJobsByProviderAtomic(String providerId) async {
    return await _httpClient.getJobsByProvider(providerId);
  }

  /// Delete job atomically
  Future<AtomicResult<void>> deleteJobAtomic(String jobId) async {
    return await _httpClient.deleteJob(jobId);
  }

  /// Execute batch of atomic operations
  Future<AtomicResult<Map<String, dynamic>>> executeBatchOperations(
    List<Map<String, dynamic>> operations,
  ) async {
    return await _httpClient.executeAtomicOperations(operations);
  }

  /// Get operation history for a job
  Future<AtomicResult<List<Map<String, dynamic>>>> getOperationHistory(String jobId) async {
    return await _httpClient.getOperationHistory(jobId);
  }

  /// Batch create multiple jobs atomically
  Future<AtomicResult<List<AtomicJob>>> createJobsBatch(
    List<Map<String, dynamic>> jobsData,
  ) async {
    final operations = jobsData.map((jobData) => {
      'id': 'create_job_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'create',
      'data': jobData,
    }).toList();

    final result = await executeBatchOperations(operations);
    
    if (result.isSuccess && result.data != null) {
      final results = result.data!['results'] as List<dynamic>;
      final jobs = results
          .where((r) => r['success'] == true)
          .map((r) => _mapToAtomicJob(r['data']))
          .toList();
      
      return AtomicResult.success(jobs.cast<AtomicJob>());
    }
    
    return AtomicResult.failure(result.error ?? 'Failed to create jobs batch');
  }

  /// Batch update job statuses atomically
  Future<AtomicResult<List<AtomicJob>>> updateJobStatusesBatch(
    List<Map<String, dynamic>> statusUpdates,
  ) async {
    final operations = statusUpdates.map((update) => {
      'id': 'status_update_${update['jobId']}_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'statusChange',
      'entityId': update['jobId'],
      'data': {
        'status': update['status'],
        'reason': update['reason'],
        'userId': update['userId'],
      },
    }).toList();

    final result = await executeBatchOperations(operations);
    
    if (result.isSuccess && result.data != null) {
      final results = result.data!['results'] as List<dynamic>;
      final jobs = results
          .where((r) => r['success'] == true)
          .map((r) => _mapToAtomicJob(r['data']))
          .toList();
      
      return AtomicResult.success(jobs.cast<AtomicJob>());
    }
    
    return AtomicResult.failure(result.error ?? 'Failed to update job statuses batch');
  }

  /// Helper method to convert API response to AtomicJob
  AtomicJob _mapToAtomicJob(Map<String, dynamic> data) {
    return AtomicJob(
      id: data['id'],
      customerName: data['customerName'],
      customerId: data['customerId'],
      address: data['address'],
      service: ServiceType.values.firstWhere(
        (e) => e.name == data['service'],
        orElse: () => ServiceType.driveway,
      ),
      price: (data['price'] as num).toDouble(),
      scheduledAt: DateTime.parse(data['scheduledAt']),
      createdAt: DateTime.parse(data['createdAt']),
      updatedAt: DateTime.parse(data['updatedAt']),
      notes: data['notes'],
      status: JobStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => JobStatus.newRequest,
      ),
      addonSalting: data['addonSalting'] ?? false,
      providerId: data['providerId'],
      statusHistory: (data['statusHistory'] as List<dynamic>?)
          ?.map((h) => JobStatusTransition(
                from: JobStatus.values.firstWhere(
                  (e) => e.name == h['from'],
                  orElse: () => JobStatus.newRequest,
                ),
                to: JobStatus.values.firstWhere(
                  (e) => e.name == h['to'],
                  orElse: () => JobStatus.newRequest,
                ),
                timestamp: DateTime.parse(h['timestamp']),
                reason: h['reason'],
                userId: h['userId'],
              ))
          .toList() ?? [],
      version: data['version'] ?? 1,
    );
  }

  void dispose() {
    _httpClient.dispose();
  }
}
