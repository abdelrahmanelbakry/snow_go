import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/atomic_job.dart';
import '../core/atomic_state.dart';
import '../core/atomic_operations.dart';

/// Atomic Firebase operations service
class AtomicFirebaseService {
  static const String _jobsCollection = 'jobs';
  static const String _operationsCollection = 'atomic_operations';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Execute atomic job creation
  Future<AtomicResult<AtomicJob>> createJobAtomic(AtomicJob job) async {
    final batch = _firestore.batch();
    
    try {
      // Create job document
      final jobRef = _firestore.collection(_jobsCollection).doc(job.id);
      batch.set(jobRef, job.toJson());
      
      // Create operation log
      final operationRef = _firestore.collection(_operationsCollection).doc();
      final operation = job.toCreateOperation();
      batch.set(operationRef, operation.toJson());
      
      // Execute atomic batch
      await batch.commit();
      
      return AtomicResult.success(job);
    } catch (e) {
      return AtomicResult.failure('Failed to create job atomically: $e');
    }
  }

  /// Execute atomic job update with optimistic locking
  Future<AtomicResult<AtomicJob>> updateJobAtomic(AtomicJob job) async {
    return await _firestore.runTransaction((transaction) async {
      try {
        final jobRef = _firestore.collection(_jobsCollection).doc(job.id);
        final jobDoc = await transaction.get(jobRef);
        
        if (!jobDoc.exists) {
          throw StateError('Job not found: ${job.id}');
        }
        
        final existingJob = AtomicJob.fromJson(jobDoc.data()!);
        
        // Optimistic locking check
        if (existingJob.version != job.version - 1) {
          throw StateError('Job version conflict. Expected ${job.version - 1}, got ${existingJob.version}');
        }
        
        // Update job
        transaction.update(jobRef, job.toJson());
        
        // Log operation
        final operationRef = _firestore.collection(_operationsCollection).doc();
        final operation = job.toUpdateOperation();
        transaction.set(operationRef, operation.toJson());
        
        return AtomicResult.success(job);
      } catch (e) {
        return AtomicResult.failure('Failed to update job atomically: $e');
      }
    });
  }

  /// Execute atomic status change
  Future<AtomicResult<AtomicJob>> changeJobStatusAtomic(
    String jobId,
    JobStatus newStatus, {
    String? reason,
    String? userId,
  }) async {
    return await _firestore.runTransaction((transaction) async {
      try {
        final jobRef = _firestore.collection(_jobsCollection).doc(jobId);
        final jobDoc = await transaction.get(jobRef);
        
        if (!jobDoc.exists) {
          throw StateError('Job not found: $jobId');
        }
        
        final existingJob = AtomicJob.fromJson(jobDoc.data()!);
        final updatedJob = existingJob.changeStatus(
          newStatus,
          reason: reason,
          userId: userId,
        );
        
        // Update job with new status
        transaction.update(jobRef, updatedJob.toJson());
        
        // Log status change operation
        final operationRef = _firestore.collection(_operationsCollection).doc();
        final operation = updatedJob.toStatusChangeOperation(
          newStatus,
          reason: reason,
          userId: userId,
        );
        transaction.set(operationRef, operation.toJson());
        
        return AtomicResult.success(updatedJob);
      } catch (e) {
        return AtomicResult.failure('Failed to change job status atomically: $e');
      }
    });
  }

  /// Execute batch atomic operations
  Future<AtomicResult<List<AtomicJob>>> executeBatchOperations(
    List<AtomicOperation> operations,
  ) async {
    final batch = _firestore.batch();
    final results = <AtomicJob>[];
    
    try {
      for (final operation in operations) {
        switch (operation.type) {
          case AtomicOperationType.create:
            final job = AtomicJob.fromJson(operation.data);
            final jobRef = _firestore.collection(_jobsCollection).doc(job.id);
            batch.set(jobRef, job.toJson());
            results.add(job);
            break;
            
          case AtomicOperationType.update:
            final job = AtomicJob.fromJson(operation.data);
            final jobRef = _firestore.collection(_jobsCollection).doc(job.id);
            batch.update(jobRef, job.toJson());
            results.add(job);
            break;
            
          case AtomicOperationType.statusChange:
            // Status changes need to be handled in transactions for optimistic locking
            throw StateError('Status changes must be executed individually with transactions');
            
          case AtomicOperationType.delete:
            final jobId = operation.entityId!;
            final jobRef = _firestore.collection(_jobsCollection).doc(jobId);
            batch.delete(jobRef);
            break;
            
          case AtomicOperationType.batch:
            throw StateError('Nested batch operations not supported');
        }
        
        // Log operation
        final operationRef = _firestore.collection(_operationsCollection).doc();
        batch.set(operationRef, operation.toJson());
      }
      
      await batch.commit();
      return AtomicResult.success(results);
    } catch (e) {
      return AtomicResult.failure('Failed to execute batch operations: $e');
    }
  }

  /// Get job by ID
  Future<AtomicResult<AtomicJob?>> getJob(String jobId) async {
    try {
      final doc = await _firestore.collection(_jobsCollection).doc(jobId).get();
      
      if (!doc.exists) {
        return const AtomicResult.success(null);
      }
      
      final job = AtomicJob.fromJson(doc.data()!);
      return AtomicResult.success(job);
    } catch (e) {
      return AtomicResult.failure('Failed to get job: $e');
    }
  }

  /// Get jobs by status
  Future<AtomicResult<List<AtomicJob>>> getJobsByStatus(JobStatus status) async {
    try {
      final query = await _firestore
          .collection(_jobsCollection)
          .where('status', isEqualTo: status.name)
          .orderBy('scheduledAt')
          .get();
      
      final jobs = query.docs
          .map((doc) => AtomicJob.fromJson(doc.data()))
          .toList();
      
      return AtomicResult.success(jobs);
    } catch (e) {
      return AtomicResult.failure('Failed to get jobs by status: $e');
    }
  }

  /// Get jobs by customer
  Future<AtomicResult<List<AtomicJob>>> getJobsByCustomer(String customerId) async {
    try {
      final query = await _firestore
          .collection(_jobsCollection)
          .where('customerId', isEqualTo: customerId)
          .orderBy('scheduledAt', descending: true)
          .get();
      
      final jobs = query.docs
          .map((doc) => AtomicJob.fromJson(doc.data()))
          .toList();
      
      return AtomicResult.success(jobs);
    } catch (e) {
      return AtomicResult.failure('Failed to get jobs by customer: $e');
    }
  }

  /// Get jobs by provider
  Future<AtomicResult<List<AtomicJob>>> getJobsByProvider(String providerId) async {
    try {
      final query = await _firestore
          .collection(_jobsCollection)
          .where('providerId', isEqualTo: providerId)
          .orderBy('scheduledAt', descending: true)
          .get();
      
      final jobs = query.docs
          .map((doc) => AtomicJob.fromJson(doc.data()))
          .toList();
      
      return AtomicResult.success(jobs);
    } catch (e) {
      return AtomicResult.failure('Failed to get jobs by provider: $e');
    }
  }

  /// Listen to job changes
  Stream<AtomicJob> listenToJob(String jobId) {
    return _firestore
        .collection(_jobsCollection)
        .doc(jobId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            throw StateError('Job not found: $jobId');
          }
          return AtomicJob.fromJson(doc.data()!);
        });
  }

  /// Listen to jobs by status
  Stream<List<AtomicJob>> listenToJobsByStatus(JobStatus status) {
    return _firestore
        .collection(_jobsCollection)
        .where('status', isEqualTo: status.name)
        .orderBy('scheduledAt')
        .snapshots()
        .map((query) => query.docs
            .map((doc) => AtomicJob.fromJson(doc.data()))
            .toList());
  }

  /// Delete job atomically
  Future<AtomicResult<void>> deleteJobAtomic(String jobId) async {
    return await _firestore.runTransaction((transaction) async {
      try {
        final jobRef = _firestore.collection(_jobsCollection).doc(jobId);
        final jobDoc = await transaction.get(jobRef);
        
        if (!jobDoc.exists) {
          throw StateError('Job not found: $jobId');
        }
        
        // Delete job
        transaction.delete(jobRef);
        
        // Log operation
        final operationRef = _firestore.collection(_operationsCollection).doc();
        final operation = AtomicOperation(
          id: 'delete_job_$jobId',
          type: AtomicOperationType.delete,
          entityId: jobId,
          data: {'deletedAt': DateTime.now().toIso8601String()},
        );
        transaction.set(operationRef, operation.toJson());
        
        return const AtomicResult.success(null);
      } catch (e) {
        return AtomicResult.failure('Failed to delete job atomically: $e');
      }
    });
  }

  /// Get operation history for a job
  Future<AtomicResult<List<AtomicOperation>>> getJobOperationHistory(String jobId) async {
    try {
      final query = await _firestore
          .collection(_operationsCollection)
          .where('entityId', isEqualTo: jobId)
          .orderBy('timestamp', descending: true)
          .get();
      
      final operations = query.docs
          .map((doc) => AtomicOperation.fromJson(doc.data()))
          .toList();
      
      return AtomicResult.success(operations);
    } catch (e) {
      return AtomicResult.failure('Failed to get operation history: $e');
    }
  }
}
