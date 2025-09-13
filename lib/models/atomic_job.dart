import 'package:flutter/foundation.dart';
import 'service_type.dart';
import '../core/atomic_operations.dart';

enum JobStatus { newRequest, assigned, inProgress, completed, cancelled }

/// Atomic job status transitions
class JobStatusTransition {
  final JobStatus from;
  final JobStatus to;
  final DateTime timestamp;
  final String? reason;
  final String? userId;

  const JobStatusTransition({
    required this.from,
    required this.to,
    required this.timestamp,
    this.reason,
    this.userId,
  });

  Map<String, dynamic> toJson() => {
    'from': from.name,
    'to': to.name,
    'timestamp': timestamp.toIso8601String(),
    'reason': reason,
    'userId': userId,
  };

  factory JobStatusTransition.fromJson(Map<String, dynamic> json) => JobStatusTransition(
    from: JobStatus.values.byName(json['from']),
    to: JobStatus.values.byName(json['to']),
    timestamp: DateTime.parse(json['timestamp']),
    reason: json['reason'],
    userId: json['userId'],
  );
}

/// Atomic job model with immutable state and atomic operations
@immutable
class AtomicJob {
  final String id;
  final String customerName;
  final String customerId;
  final String address;
  final ServiceType service;
  final double price;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final JobStatus status;
  final bool addonSalting;
  final String? providerId;
  final List<JobStatusTransition> statusHistory;
  final int version; // For optimistic locking

  const AtomicJob({
    required this.id,
    required this.customerName,
    required this.customerId,
    required this.address,
    required this.service,
    required this.price,
    required this.scheduledAt,
    required this.createdAt,
    required this.updatedAt,
    this.addonSalting = false,
    this.notes,
    this.status = JobStatus.newRequest,
    this.providerId,
    this.statusHistory = const [],
    this.version = 1,
  });

  /// Create a new job atomically
  factory AtomicJob.create({
    required String id,
    required String customerName,
    required String customerId,
    required String address,
    required ServiceType service,
    required double price,
    required DateTime scheduledAt,
    bool addonSalting = false,
    String? notes,
  }) {
    final now = DateTime.now();
    return AtomicJob(
      id: id,
      customerName: customerName,
      customerId: customerId,
      address: address,
      service: service,
      price: price,
      scheduledAt: scheduledAt,
      createdAt: now,
      updatedAt: now,
      addonSalting: addonSalting,
      notes: notes,
      status: JobStatus.newRequest,
      statusHistory: [
        JobStatusTransition(
          from: JobStatus.newRequest,
          to: JobStatus.newRequest,
          timestamp: now,
          reason: 'Job created',
          userId: customerId,
        ),
      ],
    );
  }

  /// Atomic copy with validation
  AtomicJob copyWith({
    String? id,
    String? customerName,
    String? customerId,
    String? address,
    ServiceType? service,
    double? price,
    DateTime? scheduledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    JobStatus? status,
    bool? addonSalting,
    String? providerId,
    List<JobStatusTransition>? statusHistory,
    int? version,
  }) {
    return AtomicJob(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerId: customerId ?? this.customerId,
      address: address ?? this.address,
      service: service ?? this.service,
      price: price ?? this.price,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      notes: notes ?? this.notes,
      status: status ?? this.status,
      addonSalting: addonSalting ?? this.addonSalting,
      providerId: providerId ?? this.providerId,
      statusHistory: statusHistory ?? this.statusHistory,
      version: version ?? (this.version + 1),
    );
  }

  /// Atomic status change with validation
  AtomicJob changeStatus(
    JobStatus newStatus, {
    String? reason,
    String? userId,
  }) {
    if (!_isValidStatusTransition(status, newStatus)) {
      throw StateError('Invalid status transition from $status to $newStatus');
    }

    final transition = JobStatusTransition(
      from: status,
      to: newStatus,
      timestamp: DateTime.now(),
      reason: reason,
      userId: userId,
    );

    return copyWith(
      status: newStatus,
      statusHistory: [...statusHistory, transition],
    );
  }

  /// Assign provider atomically
  AtomicJob assignProvider(String providerId, {String? reason}) {
    if (status != JobStatus.newRequest) {
      throw StateError('Can only assign provider to new requests');
    }

    return changeStatus(
      JobStatus.assigned,
      reason: reason ?? 'Provider assigned',
      userId: providerId,
    ).copyWith(providerId: providerId);
  }

  /// Start job atomically
  AtomicJob startJob({String? reason}) {
    if (status != JobStatus.assigned) {
      throw StateError('Can only start assigned jobs');
    }

    return changeStatus(
      JobStatus.inProgress,
      reason: reason ?? 'Job started',
      userId: providerId,
    );
  }

  /// Complete job atomically
  AtomicJob completeJob({String? reason}) {
    if (status != JobStatus.inProgress) {
      throw StateError('Can only complete jobs in progress');
    }

    return changeStatus(
      JobStatus.completed,
      reason: reason ?? 'Job completed',
      userId: providerId,
    );
  }

  /// Cancel job atomically
  AtomicJob cancelJob({String? reason, String? userId}) {
    if (status == JobStatus.completed) {
      throw StateError('Cannot cancel completed jobs');
    }

    return changeStatus(
      JobStatus.cancelled,
      reason: reason ?? 'Job cancelled',
      userId: userId,
    );
  }

  /// Validate status transition
  static bool _isValidStatusTransition(JobStatus from, JobStatus to) {
    const validTransitions = {
      JobStatus.newRequest: [JobStatus.assigned, JobStatus.cancelled],
      JobStatus.assigned: [JobStatus.inProgress, JobStatus.cancelled],
      JobStatus.inProgress: [JobStatus.completed, JobStatus.cancelled],
      JobStatus.completed: [], // Terminal state
      JobStatus.cancelled: [], // Terminal state
    };

    return validTransitions[from]?.contains(to) ?? false;
  }

  /// Convert to atomic operation
  AtomicOperation toCreateOperation() {
    return AtomicOperation(
      id: 'create_job_$id',
      type: AtomicOperationType.create,
      entityId: id,
      data: toJson(),
    );
  }

  AtomicOperation toUpdateOperation() {
    return AtomicOperation(
      id: 'update_job_$id',
      type: AtomicOperationType.update,
      entityId: id,
      data: toJson(),
    );
  }

  AtomicOperation toStatusChangeOperation(JobStatus newStatus, {String? reason, String? userId}) {
    return AtomicOperation(
      id: 'status_change_${id}_${DateTime.now().millisecondsSinceEpoch}',
      type: AtomicOperationType.statusChange,
      entityId: id,
      data: {
        'from': status.name,
        'to': newStatus.name,
        'reason': reason,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'customerName': customerName,
    'customerId': customerId,
    'address': address,
    'service': service.name,
    'price': price,
    'scheduledAt': scheduledAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'notes': notes,
    'status': status.name,
    'addonSalting': addonSalting,
    'providerId': providerId,
    'statusHistory': statusHistory.map((t) => t.toJson()).toList(),
    'version': version,
  };

  factory AtomicJob.fromJson(Map<String, dynamic> json) => AtomicJob(
    id: json['id'],
    customerName: json['customerName'],
    customerId: json['customerId'],
    address: json['address'],
    service: ServiceType.values.byName(json['service']),
    price: json['price'].toDouble(),
    scheduledAt: DateTime.parse(json['scheduledAt']),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    notes: json['notes'],
    status: JobStatus.values.byName(json['status']),
    addonSalting: json['addonSalting'] ?? false,
    providerId: json['providerId'],
    statusHistory: (json['statusHistory'] as List<dynamic>?)
        ?.map((t) => JobStatusTransition.fromJson(t))
        .toList() ?? [],
    version: json['version'] ?? 1,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AtomicJob &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          version == other.version;

  @override
  int get hashCode => id.hashCode ^ version.hashCode;

  @override
  String toString() => 'AtomicJob(id: $id, status: $status, version: $version)';
}
