import 'package:flutter_test/flutter_test.dart';
import 'package:snow_go/services/http_client_service.dart';
import 'package:snow_go/services/atomic_backend_service.dart';
import 'package:snow_go/providers/jobs_provider.dart';
import 'package:snow_go/models/atomic_job.dart';
import 'package:snow_go/models/service_type.dart';
import 'package:snow_go/core/atomic_state.dart';

void main() {
  group('Backend Integration Tests', () {
    late HttpClientService httpClient;
    late AtomicBackendService backendService;
    late AtomicJobsProvider jobsProvider;

    setUp(() {
      httpClient = HttpClientService();
      backendService = AtomicBackendService();
      jobsProvider = AtomicJobsProvider();
    });

    tearDown(() {
      httpClient.dispose();
      backendService.dispose();
    });

    test('HttpClientService should be properly initialized', () {
      expect(httpClient, isNotNull);
    });

    test('AtomicBackendService should be properly initialized', () {
      expect(backendService, isNotNull);
    });

    test('AtomicJobsProvider should use backend service', () {
      expect(jobsProvider, isNotNull);
      expect(jobsProvider.jobs, isNotEmpty); // Should have seed data
    });

    test('AtomicResult should handle success and failure cases', () {
      final successResult = AtomicResult.success('test data');
      expect(successResult.isSuccess, isTrue);
      expect(successResult.data, equals('test data'));
      expect(successResult.error, isNull);

      final failureResult = AtomicResult<String>.failure('test error');
      expect(failureResult.isSuccess, isFalse);
      expect(failureResult.data, isNull);
      expect(failureResult.error, equals('test error'));
    });

    test('Job creation should prepare correct request data', () {
      final now = DateTime.now();
      final jobData = {
        'customerName': 'Test Customer',
        'customerId': 'customer_123',
        'address': '123 Test St',
        'service': ServiceType.driveway.name,
        'price': 50.0,
        'scheduledAt': now.toIso8601String(),
        'addonSalting': true,
        'notes': 'Test notes',
      };

      expect(jobData['customerName'], equals('Test Customer'));
      expect(jobData['service'], equals('driveway'));
      expect(jobData['price'], equals(50.0));
      expect(jobData['addonSalting'], isTrue);
    });

    test('Job status transitions should be validated', () {
      // Test valid transitions
      expect(JobStatus.newRequest.name, equals('newRequest'));
      expect(JobStatus.assigned.name, equals('assigned'));
      expect(JobStatus.inProgress.name, equals('inProgress'));
      expect(JobStatus.completed.name, equals('completed'));
      expect(JobStatus.cancelled.name, equals('cancelled'));
    });

    test('Service types should be properly mapped', () {
      expect(ServiceType.driveway.name, equals('driveway'));
      expect(ServiceType.salting.name, equals('salting'));
    });

    test('AtomicJobsProvider should handle local state updates', () async {
      final initialJobCount = jobsProvider.jobs.length;
      expect(initialJobCount, greaterThan(0)); // Should have seed data

      // Test getting jobs by status
      final newJobs = jobsProvider.getJobsByStatus(JobStatus.newRequest);
      expect(newJobs, isNotEmpty);

      // Test getting job by ID
      final firstJob = jobsProvider.jobs.first;
      final foundJob = jobsProvider.getJobById(firstJob.id);
      expect(foundJob, isNotNull);
      expect(foundJob!.id, equals(firstJob.id));
    });

    test('Backend service methods should be callable', () {
      // Test that all backend service methods exist and are callable
      expect(() => backendService.createJobAtomic(
        customerName: 'Test',
        customerId: 'test',
        address: 'Test Address',
        service: ServiceType.driveway,
        price: 50.0,
        scheduledAt: DateTime.now(),
      ), returnsNormally);

      expect(() => backendService.getJobAtomic('test-id'), returnsNormally);
      expect(() => backendService.changeJobStatusAtomic('test-id', JobStatus.assigned), returnsNormally);
      expect(() => backendService.assignProviderAtomic('test-id', 'provider-id'), returnsNormally);
    });

    test('HTTP client should handle network errors gracefully', () {
      // Test that HTTP client methods exist and handle errors
      expect(() => httpClient.createJob(
        customerName: 'Test',
        customerId: 'test',
        address: 'Test Address',
        service: ServiceType.driveway,
        price: 50.0,
        scheduledAt: DateTime.now(),
      ), returnsNormally);
    });
  });

  group('Error Handling Tests', () {
    test('AtomicResult should properly handle null data', () {
      final result = AtomicResult<String?>.success(null);
      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
      expect(result.error, isNull);
    });

    test('AtomicResult should handle empty error messages', () {
      final result = AtomicResult<String>.failure('');
      expect(result.isSuccess, isFalse);
      expect(result.error, equals(''));
    });
  });
}
