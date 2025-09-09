import 'package:flutter/foundation.dart';
import 'service_type.dart';

enum JobStatus { newRequest, assigned, inProgress, completed, cancelled }

@immutable
class Job {
  final String id;
  final String customerName;
  final String address;
  final ServiceType service;
  final double price; // store numeric value
  final DateTime scheduledAt;
  final String? notes;
  final JobStatus status;

  const Job({
    required this.id,
    required this.customerName,
    required this.address,
    required this.service,
    required this.price,
    required this.scheduledAt,
    this.notes,
    this.status = JobStatus.newRequest,
  });

  Job copyWith({
    String? id,
    String? customerName,
    String? address,
    ServiceType? service,
    double? price,
    DateTime? scheduledAt,
    String? notes,
    JobStatus? status,
  }) {
    return Job(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      service: service ?? this.service,
      price: price ?? this.price,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
}
