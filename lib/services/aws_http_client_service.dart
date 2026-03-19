import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/atomic_job.dart';
import '../models/service_type.dart';
import '../core/atomic_state.dart';

class AWSHttpClientService {
  static const String _baseUrl =
      'https://your-api-gateway-url.execute-api.us-east-1.amazonaws.com/prod'; // Update with your API Gateway URL
  static const Duration _timeout = Duration(seconds: 30);

  final http.Client _client = http.Client();
  String? _authToken;

  // Singleton pattern
  static final AWSHttpClientService _instance =
      AWSHttpClientService._internal();
  factory AWSHttpClientService() => _instance;
  AWSHttpClientService._internal();

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
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
          response =
              await _client.get(uri, headers: _headers).timeout(_timeout);
          break;
        case 'POST':
          response = await _client
              .post(
                uri,
                headers: _headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await _client
              .put(
                uri,
                headers: _headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_timeout);
          break;
        case 'DELETE':
          response =
              await _client.delete(uri, headers: _headers).timeout(_timeout);
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
          errorData['error'] ??
              'HTTP ${response.statusCode}: ${response.reasonPhrase}',
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

  // Authentication methods
  Future<AtomicResult<Map<String, dynamic>>> login(
      String email, String password) async {
    final body = {
      'email': email,
      'password': password,
    };

    final result = await _makeRequest<Map<String, dynamic>>(
      'POST',
      '/users/login',
      body: body,
    );

    if (result.isSuccess && result.data != null) {
      final token = result.data!['token'];
      if (token != null) {
        setAuthToken(token);
      }
    }

    return result;
  }

  Future<AtomicResult<Map<String, dynamic>>> register({
    required String email,
    required String name,
    required String role,
    String? password,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final body = {
      'email': email,
      'name': name,
      'role': role,
      if (password != null) 'password': password,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };

    return _makeRequest<Map<String, dynamic>>(
      'POST',
      '/users',
      body: body,
    );
  }

  // Job API methods
  Future<AtomicResult<AtomicJob>> createJob({
    required String customerName,
    required String customerId,
    required String address,
    required double latitude,
    required double longitude,
    required ServiceType service,
    required double price,
    required DateTime scheduledAt,
    bool addonSalting = false,
    String? notes,
    String? imageUrl,
  }) async {
    final body = {
      'customerName': customerName,
      'customerId': customerId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'serviceType': service.name,
      'price': price,
      'scheduledAt': scheduledAt.toIso8601String(),
      'addonSalting': addonSalting,
      if (notes != null) 'notes': notes,
      if (imageUrl != null) 'imageUrl': imageUrl,
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

  Future<AtomicResult<List<AtomicJob>>> getJobs({
    String? status,
    String? customerId,
    String? providerId,
    String? serviceType,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (status != null) 'status': status,
      if (customerId != null) 'customerId': customerId,
      if (providerId != null) 'providerId': providerId,
      if (serviceType != null) 'serviceType': serviceType,
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final result = await _makeRequest<Map<String, dynamic>>(
      'GET',
      '/jobs?$queryString',
    );

    if (result.isSuccess && result.data != null) {
      final jobsData = result.data!['jobs'] as List<dynamic>;
      final jobs = jobsData.map((data) => _mapToAtomicJob(data)).toList();
      return AtomicResult.success(jobs);
    }

    return AtomicResult.failure(result.error ?? 'Failed to get jobs');
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

  // AI Scheduling methods
  Future<AtomicResult<Map<String, dynamic>>> newRequestAgent({
    required String serviceType,
    required String address,
    required double latitude,
    required double longitude,
    required String customerId,
    required String customerName,
    String? imageUrl,
  }) async {
    final body = {
      'serviceType': serviceType,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'customerId': customerId,
      'customerName': customerName,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };

    return _makeRequest<Map<String, dynamic>>(
      'POST',
      '/ai/new-request',
      body: body,
    );
  }

  Future<AtomicResult<Map<String, dynamic>>> providerScheduler({
    required String jobId,
    required String providerId,
    String? imageUrl,
    String? notes,
  }) async {
    final body = {
      'jobId': jobId,
      'providerId': providerId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (notes != null) 'notes': notes,
    };

    return _makeRequest<Map<String, dynamic>>(
      'POST',
      '/ai/provider-schedule',
      body: body,
    );
  }

  // Notification methods
  Future<AtomicResult<void>> registerDeviceToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    final body = {
      'userId': userId,
      'token': token,
      'platform': platform,
    };

    final result = await _makeRequest<void>(
      'POST',
      '/notifications/register-token',
      body: body,
    );

    if (result.isSuccess) {
      return AtomicResult.success(null);
    }

    return AtomicResult.failure(
        result.error ?? 'Failed to register device token');
  }

  Future<AtomicResult<Map<String, dynamic>>> getNotifications({
    required String userId,
    String? type,
    bool? isRead,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'userId': userId,
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (type != null) 'type': type,
      if (isRead != null) 'isRead': isRead.toString(),
    };

    final queryString = Uri(queryParameters: queryParams).query;
    return _makeRequest<Map<String, dynamic>>(
      'GET',
      '/notifications?$queryString',
    );
  }

  Future<AtomicResult<void>> markNotificationRead(String notificationId) async {
    final result = await _makeRequest<void>(
      'POST',
      '/notifications/$notificationId/read',
    );

    if (result.isSuccess) {
      return AtomicResult.success(null);
    }

    return AtomicResult.failure(
        result.error ?? 'Failed to mark notification as read');
  }

  // Atomic operations API
  Future<AtomicResult<Map<String, dynamic>>> executeAtomicOperations(
    List<Map<String, dynamic>> operations,
    String jobId,
    String? userId,
  ) async {
    final body = {
      'operations': operations,
      'jobId': jobId,
      if (userId != null) 'userId': userId,
    };

    return _makeRequest<Map<String, dynamic>>(
      'POST',
      '/atomic/execute',
      body: body,
    );
  }

  Future<AtomicResult<List<Map<String, dynamic>>>> getOperationHistory(
    String jobId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final result = await _makeRequest<Map<String, dynamic>>(
      'GET',
      '/atomic/history/$jobId?$queryString',
    );

    if (result.isSuccess && result.data != null) {
      final operations = result.data!['operations'] as List<dynamic>;
      return AtomicResult.success(operations.cast<Map<String, dynamic>>());
    }

    return AtomicResult.failure(
        result.error ?? 'Failed to get operation history');
  }

  // Helper method to convert API response to AtomicJob
  AtomicJob _mapToAtomicJob(Map<String, dynamic> data) {
    return AtomicJob(
      id: data['id'],
      customerName: data['customer_name'],
      customerId: data['customer_id'],
      address: data['address'],
      service: ServiceType.values.firstWhere(
        (e) => e.name == data['service_type'],
        orElse: () => ServiceType.driveway,
      ),
      price: (data['price'] as num).toDouble(),
      scheduledAt: DateTime.parse(data['scheduled_at']),
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      notes: data['notes'],
      status: JobStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => JobStatus.newRequest,
      ),
      addonSalting: data['addon_salting'] ?? false,
      providerId: data['provider_id'],
      statusHistory: [], // Would need separate API call to populate this
      version: data['version'] ?? 1,
    );
  }

  void dispose() {
    _client.close();
  }
}
