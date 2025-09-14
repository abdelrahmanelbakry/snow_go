import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/atomic_job.dart';
import '../models/service_type.dart';
import '../core/atomic_state.dart';

class HttpClientService {
  static const String _baseUrl = 'http://localhost:3000/api'; // Update for production
  static const Duration _timeout = Duration(seconds: 30);
  
  final http.Client _client = http.Client();
  
  // Singleton pattern
  static final HttpClientService _instance = HttpClientService._internal();
  factory HttpClientService() => _instance;
  HttpClientService._internal();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<AtomicResult<T>> _makeRequest<T>(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      late http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: _headers).timeout(_timeout);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(_timeout);
          break;
        case 'PUT':
          response = await _client.put(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(_timeout);
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: _headers).timeout(_timeout);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return AtomicResult.success(null as T);
        }
        
        final data = jsonDecode(response.body);
        if (fromJson != null && data != null) {
          return AtomicResult.success(fromJson(data));
        }
        return AtomicResult.success(data as T);
      } else {
        final errorData = jsonDecode(response.body);
        return AtomicResult.failure(
          errorData['error'] ?? 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } on SocketException {
      return AtomicResult.failure('No internet connection');
    } on HttpException catch (e) {
      return AtomicResult.failure('HTTP error: ${e.message}');
    } on FormatException {
      return AtomicResult.failure('Invalid response format');
    } catch (e) {
      return AtomicResult.failure('Network error: $e');
    }
  }

  // Job API methods
  Future<AtomicResult<AtomicJob>> createJob({
    required String customerName,
    required String customerId,
    required String address,
    required ServiceType service,
    required double price,
    required DateTime scheduledAt,
    bool addonSalting = false,
    String? notes,
  }) async {
    final body = {
      'customerName': customerName,
      'customerId': customerId,
      'address': address,
      'service': service.name,
      'price': price,
      'scheduledAt': scheduledAt.toIso8601String(),
      'addonSalting': addonSalting,
      if (notes != null) 'notes': notes,
    };

    final result = await _makeRequest<Map<String, dynamic>>(
      'POST',
      '/jobs',
      body: body,
    );

    if (result.isSuccess && result.data != null) {
      final jobData = result.data!['job'] as Map<String, dynamic>;
      return AtomicResult.success(_mapToAtomicJob(jobData));
    }
    
    return AtomicResult.failure(result.error ?? 'Failed to create job');
  }

  Future<AtomicResult<AtomicJob?>> getJob(String jobId) async {
    final result = await _makeRequest<Map<String, dynamic>>(
      'GET',
      '/jobs/$jobId',
    );

    if (result.isSuccess && result.data != null) {
      final jobData = result.data!['job'] as Map<String, dynamic>;
      return AtomicResult.success(_mapToAtomicJob(jobData));
    }
    
    if (result.error?.contains('not found') == true) {
      return AtomicResult.success(null);
    }
    
    return AtomicResult.failure(result.error ?? 'Failed to get job');
  }

  Future<AtomicResult<List<AtomicJob>>> getJobsByStatus(JobStatus status) async {
    final result = await _makeRequest<Map<String, dynamic>>(
      'GET',
      '/jobs?status=${status.name}',
    );

    if (result.isSuccess && result.data != null) {
      final jobsData = result.data!['jobs'] as List<dynamic>;
      final jobs = jobsData.map((data) => _mapToAtomicJob(data)).toList();
      return AtomicResult.success(jobs);
    }
    
    return AtomicResult.failure(result.error ?? 'Failed to get jobs');
  }

  Future<AtomicResult<List<AtomicJob>>> getJobsByCustomer(String customerId) async {
    final result = await _makeRequest<Map<String, dynamic>>(
      'GET',
      '/jobs?customerId=$customerId',
    );

    if (result.isSuccess && result.data != null) {
      final jobsData = result.data!['jobs'] as List<dynamic>;
      final jobs = jobsData.map((data) => _mapToAtomicJob(data)).toList();
      return AtomicResult.success(jobs);
    }
    
    return AtomicResult.failure(result.error ?? 'Failed to get customer jobs');
  }

  Future<AtomicResult<List<AtomicJob>>> getJobsByProvider(String providerId) async {
    final result = await _makeRequest<Map<String, dynamic>>(
      'GET',
      '/jobs?providerId=$providerId',
    );

    if (result.isSuccess && result.data != null) {
      final jobsData = result.data!['jobs'] as List<dynamic>;
      final jobs = jobsData.map((data) => _mapToAtomicJob(data)).toList();
      return AtomicResult.success(jobs);
    }
    
    return AtomicResult.failure(result.error ?? 'Failed to get provider jobs');
  }

  Future<AtomicResult<AtomicJob>> updateJob(
    String jobId,
    Map<String, dynamic> updates,
  ) async {
    final result = await _makeRequest<Map<String, dynamic>>(
      'PUT',
      '/jobs/$jobId',
      body: updates,
    );

    if (result.isSuccess && result.data != null) {
      final jobData = result.data!['job'] as Map<String, dynamic>;
      return AtomicResult.success(_mapToAtomicJob(jobData));
    }
    
    return AtomicResult.failure(result.error ?? 'Failed to update job');
  }

  Future<AtomicResult<AtomicJob>> changeJobStatus(
    String jobId,
    JobStatus newStatus, {
    String? reason,
    String? userId,
  }) async {
    final body = {
      'status': newStatus.name,
      if (reason != null) 'reason': reason,
      if (userId != null) 'userId': userId,
    };

    final result = await _makeRequest<Map<String, dynamic>>(
      'POST',
      '/jobs/$jobId/status',
      body: body,
    );

    if (result.isSuccess && result.data != null) {
      final jobData = result.data!['job'] as Map<String, dynamic>;
      return AtomicResult.success(_mapToAtomicJob(jobData));
    }
    
    return AtomicResult.failure(result.error ?? 'Failed to change job status');
  }

  Future<AtomicResult<AtomicJob>> assignProvider(
    String jobId,
    String providerId, {
    String? reason,
  }) async {
    final body = {
      'providerId': providerId,
      if (reason != null) 'reason': reason,
    };

    final result = await _makeRequest<Map<String, dynamic>>(
      'POST',
      '/jobs/$jobId/assign',
      body: body,
    );

    if (result.isSuccess && result.data != null) {
      final jobData = result.data!['job'] as Map<String, dynamic>;
      return AtomicResult.success(_mapToAtomicJob(jobData));
    }
    
    return AtomicResult.failure(result.error ?? 'Failed to assign provider');
  }

  Future<AtomicResult<void>> deleteJob(String jobId) async {
    final result = await _makeRequest<void>(
      'DELETE',
      '/jobs/$jobId',
    );

    if (result.isSuccess) {
      return AtomicResult.success(null);
    }
    
    return AtomicResult.failure(result.error ?? 'Failed to delete job');
  }

  // Atomic operations API
  Future<AtomicResult<Map<String, dynamic>>> executeAtomicOperations(
    List<Map<String, dynamic>> operations,
  ) async {
    final body = {'operations': operations};

    final result = await _makeRequest<Map<String, dynamic>>(
      'POST',
      '/atomic/execute',
      body: body,
    );

    if (result.isSuccess) {
      return result;
    }
    
    return AtomicResult.failure(result.error ?? 'Failed to execute atomic operations');
  }

  Future<AtomicResult<List<Map<String, dynamic>>>> getOperationHistory(String jobId) async {
    final result = await _makeRequest<Map<String, dynamic>>(
      'GET',
      '/atomic/history/$jobId',
    );

    if (result.isSuccess && result.data != null) {
      final operations = result.data!['operations'] as List<dynamic>;
      return AtomicResult.success(operations.cast<Map<String, dynamic>>());
    }
    
    return AtomicResult.failure(result.error ?? 'Failed to get operation history');
  }

  // Helper method to convert API response to AtomicJob
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
    _client.close();
  }
}
