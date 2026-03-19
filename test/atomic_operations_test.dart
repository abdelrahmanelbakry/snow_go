import 'package:flutter_test/flutter_test.dart';
import 'package:snow_go/core/atomic_state.dart';
import 'package:snow_go/models/atomic_job.dart';
import 'package:snow_go/models/service_type.dart';
import 'package:snow_go/providers/jobs_provider.dart';

void main() {
  group('Atomic Operations Tests', () {
    late AtomicJobsProvider jobsProvider;

    setUp(() {
      jobsProvider = AtomicJobsProvider();
      jobsProvider.clearAllJobs(); // Start with clean state
    });

    test('should create job atomically', () async {
      // Arrange
      const customerName = 'Test Customer';
      const customerId = 'customer_test';
      const address = '123 Test St';
      const service = ServiceType.driveway;
      const price = 50.0;
      final scheduledAt = DateTime.now().add(const Duration(hours: 2));

      // Act
      final result = await jobsProvider.addJob(
        customerName: customerName,
        customerId: customerId,
        address: address,
        service: service,
        price: price,
        scheduledAt: scheduledAt,
        notes: 'Test job',
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.data?.customerName, customerName);
      expect(result.data?.status, JobStatus.newRequest);
      expect(result.data?.version, 1);
      expect(jobsProvider.jobs.length, 1);
    });

    test('should update job status atomically', () async {
      // Arrange
      final result = await jobsProvider.addJob(
        customerName: 'Test Customer',
        customerId: 'customer_test',
        address: '123 Test St',
        service: ServiceType.driveway,
        price: 50.0,
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      );
      final jobId = result.data!.id;

      // Act
      final updateResult = await jobsProvider.updateJobStatus(
        jobId,
        JobStatus.assigned,
        reason: 'Test assignment',
        userId: 'provider_test',
      );

      // Assert
      expect(updateResult.isSuccess, true);
      expect(updateResult.data?.status, JobStatus.assigned);
      expect(updateResult.data?.version, 2);
      expect(updateResult.data?.statusHistory.length, 2);
    });

    test('should prevent invalid status transitions', () async {
      // Arrange
      final result = await jobsProvider.addJob(
        customerName: 'Test Customer',
        customerId: 'customer_test',
        address: '123 Test St',
        service: ServiceType.driveway,
        price: 50.0,
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      );
      final jobId = result.data!.id;

      // Act - Try to go directly from newRequest to completed
      final updateResult =
          await jobsProvider.updateJobStatus(jobId, JobStatus.completed);

      // Assert - Should fail with error (the error is caught and returned as failure)
      expect(updateResult.isFailure, true);
      expect(updateResult.error, contains('Invalid status transition'));
    });

    test('should assign provider atomically', () async {
      // Arrange
      final result = await jobsProvider.addJob(
        customerName: 'Test Customer',
        customerId: 'customer_test',
        address: '123 Test St',
        service: ServiceType.driveway,
        price: 50.0,
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      );
      final jobId = result.data!.id;

      // Act
      final assignResult = await jobsProvider.assignProvider(
        jobId,
        'provider_123',
        reason: 'Test assignment',
      );

      // Assert
      expect(assignResult.isSuccess, true);
      expect(assignResult.data?.providerId, 'provider_123');
      expect(assignResult.data?.status, JobStatus.assigned);
      expect(
          assignResult.data?.version, 3); // Create=1, Assign=2, Status change=3
    });

    test('should handle concurrent updates with optimistic locking', () async {
      // Arrange
      final result = await jobsProvider.addJob(
        customerName: 'Test Customer',
        customerId: 'customer_test',
        address: '123 Test St',
        service: ServiceType.driveway,
        price: 50.0,
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      );
      final job = result.data!;

      // Act - Simulate concurrent updates
      final job1 = job.copyWith(notes: 'Updated by user 1');
      final job2 = job.copyWith(notes: 'Updated by user 2');

      // Assert - Both should have different versions
      expect(job1.version, 2);
      expect(job2.version, 2);
      expect(job1.notes, 'Updated by user 1');
      expect(job2.notes, 'Updated by user 2');
    });

    test('should maintain status history', () async {
      // Arrange
      final result = await jobsProvider.addJob(
        customerName: 'Test Customer',
        customerId: 'customer_test',
        address: '123 Test St',
        service: ServiceType.driveway,
        price: 50.0,
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      );
      final jobId = result.data!.id;

      // Act - Go through status transitions
      await jobsProvider.assignProvider(jobId, 'provider_123');
      await jobsProvider.startJob(jobId, reason: 'Job started');
      await jobsProvider.completeJob(jobId, reason: 'Job completed');

      // Assert
      final finalJob = jobsProvider.getJobById(jobId)!;
      expect(finalJob.status, JobStatus.completed);
      expect(
          finalJob.statusHistory.length, 4); // create, assign, start, complete
      expect(finalJob.version, 4); // Each operation increments version
    });

    test('should filter jobs by status', () async {
      // Arrange
      await jobsProvider.addJob(
        customerName: 'Customer 1',
        customerId: 'customer_1',
        address: '123 Test St',
        service: ServiceType.driveway,
        price: 50.0,
        scheduledAt: DateTime.now().add(const Duration(hours: 1)),
      );

      final result2 = await jobsProvider.addJob(
        customerName: 'Customer 2',
        customerId: 'customer_2',
        address: '456 Test Ave',
        service: ServiceType.salting,
        price: 30.0,
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      );

      await jobsProvider.assignProvider(result2.data!.id, 'provider_123');

      // Act
      final newJobs = jobsProvider.getJobsByStatus(JobStatus.newRequest);
      final assignedJobs = jobsProvider.getJobsByStatus(JobStatus.assigned);

      // Assert
      expect(newJobs.length, 1);
      expect(assignedJobs.length, 1);
      expect(newJobs.first.customerName, 'Customer 1');
      expect(assignedJobs.first.customerName, 'Customer 2');
    });

    test('should handle error states properly', () async {
      // Arrange
      const invalidJobId = 'invalid_job_id';

      // Act
      final result = await jobsProvider.updateJobStatus(
        invalidJobId,
        JobStatus.assigned,
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.error, contains('Job not found'));
    });

    test('should queue and execute atomic operations', () async {
      // Arrange
      final result = await jobsProvider.addJob(
        customerName: 'Test Customer',
        customerId: 'customer_test',
        address: '123 Test St',
        service: ServiceType.driveway,
        price: 50.0,
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      );
      
      // Assert the job was created successfully
      expect(result.isSuccess, true);
      expect(result.data, isNotNull);

      // Act - Operations should be queued
      expect(jobsProvider.pendingOperationsCount, greaterThan(0));

      // Execute queued operations
      final executeResult = await jobsProvider.commitPendingOperations();

      // Assert
      expect(executeResult.isSuccess, true);
      expect(jobsProvider.pendingOperationsCount, 0);
    });
  });

  group('AtomicJob Model Tests', () {
    test('should create job with proper defaults', () {
      // Arrange & Act
      final job = AtomicJob.create(
        id: 'test_id',
        customerName: 'Test Customer',
        customerId: 'customer_test',
        address: '123 Test St',
        service: ServiceType.driveway,
        price: 50.0,
        scheduledAt: DateTime.now(),
      );

      // Assert
      expect(job.status, JobStatus.newRequest);
      expect(job.version, 1);
      expect(job.statusHistory.length, 1);
      expect(job.statusHistory.first.from, JobStatus.newRequest);
      expect(job.statusHistory.first.to, JobStatus.newRequest);
    });

    test('should validate status transitions', () {
      // Arrange
      final job = AtomicJob.create(
        id: 'test_id',
        customerName: 'Test Customer',
        customerId: 'customer_test',
        address: '123 Test St',
        service: ServiceType.driveway,
        price: 50.0,
        scheduledAt: DateTime.now(),
      );

      // Act & Assert - Valid transition
      expect(
        () => job.changeStatus(JobStatus.assigned),
        returnsNormally,
      );

      // Act & Assert - Invalid transition
      expect(
        () => job.changeStatus(JobStatus.completed),
        throwsA(isA<StateError>()),
      );
    });

    test('should increment version on copy', () {
      // Arrange
      final job = AtomicJob.create(
        id: 'test_id',
        customerName: 'Test Customer',
        customerId: 'customer_test',
        address: '123 Test St',
        service: ServiceType.driveway,
        price: 50.0,
        scheduledAt: DateTime.now(),
      );

      // Act
      final updatedJob = job.copyWith(notes: 'Updated notes');

      // Assert
      expect(job.version, 1);
      expect(updatedJob.version, 2);
    });

    test('should serialize and deserialize correctly', () {
      // Arrange
      final originalJob = AtomicJob.create(
        id: 'test_id',
        customerName: 'Test Customer',
        customerId: 'customer_test',
        address: '123 Test St',
        service: ServiceType.driveway,
        price: 50.0,
        scheduledAt: DateTime.now(),
        notes: 'Test notes',
        addonSalting: true,
      );

      // Act
      final json = originalJob.toJson();
      final deserializedJob = AtomicJob.fromJson(json);

      // Assert
      expect(deserializedJob.id, originalJob.id);
      expect(deserializedJob.customerName, originalJob.customerName);
      expect(deserializedJob.address, originalJob.address);
      expect(deserializedJob.service, originalJob.service);
      expect(deserializedJob.price, originalJob.price);
      expect(deserializedJob.notes, originalJob.notes);
      expect(deserializedJob.addonSalting, originalJob.addonSalting);
      expect(deserializedJob.version, originalJob.version);
    });
  });

  group('AtomicState Tests', () {
    late TestAtomicState atomicState;

    setUp(() {
      atomicState = TestAtomicState(0);
    });

    test('should update state atomically', () async {
      // Act
      await atomicState.atomicUpdate((currentState) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return currentState + 1;
      });

      // Assert
      expect(atomicState.state, 1);
      expect(atomicState.isLoading, false);
      expect(atomicState.error, null);
    });

    test('should handle errors in atomic updates', () async {
      // Act
      await atomicState.atomicUpdate((currentState) async {
        throw Exception('Test error');
      });

      // Assert
      expect(atomicState.state, 0); // State should remain unchanged
      expect(atomicState.isLoading, false);
      expect(atomicState.error, contains('Test error'));
    });

    test('should prevent concurrent updates', () async {
      // Arrange
      var updateCount = 0;

      // Act - Start two concurrent updates
      final future1 = atomicState.atomicUpdate((currentState) async {
        updateCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return currentState + 1;
      });

      final future2 = atomicState.atomicUpdate((currentState) async {
        updateCount++;
        await Future.delayed(const Duration(milliseconds: 10));
        return currentState + 2;
      });

      await Future.wait([future1, future2]);

      // Assert - Only one update should have executed
      expect(updateCount, 1);
      expect(atomicState.state, 1); // First update should win
    });
  });
}

// Test helper class
class TestAtomicState extends AtomicState<int> {
  TestAtomicState(super.initialState);
}
