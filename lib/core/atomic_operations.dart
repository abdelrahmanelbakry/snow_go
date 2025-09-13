import 'dart:async';
import 'package:flutter/foundation.dart';
import 'atomic_state.dart';

/// Atomic operation types
enum AtomicOperationType {
  create,
  update,
  delete,
  statusChange,
  batch
}

/// Atomic operation metadata
class AtomicOperation {
  final String id;
  final AtomicOperationType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final String? entityId;

  AtomicOperation({
    required this.id,
    required this.type,
    required this.data,
    this.entityId,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'data': data,
    'entityId': entityId,
  };

  factory AtomicOperation.fromJson(Map<String, dynamic> json) => AtomicOperation(
    id: json['id'],
    type: AtomicOperationType.values.byName(json['type']),
    data: json['data'],
    entityId: json['entityId'],
  );
}

/// Atomic operation executor
class AtomicOperationExecutor {
  final List<AtomicOperation> _pendingOperations = [];
  final List<AtomicOperation> _completedOperations = [];
  bool _isExecuting = false;

  /// Add operation to queue
  void queueOperation(AtomicOperation operation) {
    if (_isExecuting) {
      throw StateError('Cannot queue operations during execution');
    }
    _pendingOperations.add(operation);
  }

  /// Execute all pending operations atomically
  Future<AtomicResult<List<AtomicOperation>>> executeAll() async {
    if (_isExecuting) {
      return const AtomicResult.failure('Execution already in progress');
    }

    _isExecuting = true;
    final transaction = AtomicTransaction();
    
    try {
      final executed = <AtomicOperation>[];
      
      for (final operation in _pendingOperations) {
        // Execute operation
        await _executeOperation(operation, transaction);
        executed.add(operation);
        
        // Add rollback for this operation
        transaction.addRollback(() => _rollbackOperation(operation));
      }
      
      // All operations successful, commit
      transaction.commit();
      _completedOperations.addAll(executed);
      _pendingOperations.clear();
      
      return AtomicResult.success(executed);
    } catch (e) {
      // Rollback all operations
      transaction.rollback();
      return AtomicResult.failure('Atomic execution failed: $e');
    } finally {
      _isExecuting = false;
    }
  }

  /// Execute single operation
  Future<void> _executeOperation(AtomicOperation operation, AtomicTransaction transaction) async {
    switch (operation.type) {
      case AtomicOperationType.create:
        await _executeCreate(operation, transaction);
        break;
      case AtomicOperationType.update:
        await _executeUpdate(operation, transaction);
        break;
      case AtomicOperationType.delete:
        await _executeDelete(operation, transaction);
        break;
      case AtomicOperationType.statusChange:
        await _executeStatusChange(operation, transaction);
        break;
      case AtomicOperationType.batch:
        await _executeBatch(operation, transaction);
        break;
    }
  }

  Future<void> _executeCreate(AtomicOperation operation, AtomicTransaction transaction) async {
    // Implementation will be provided by specific providers
    debugPrint('Executing CREATE operation: ${operation.id}');
  }

  Future<void> _executeUpdate(AtomicOperation operation, AtomicTransaction transaction) async {
    // Implementation will be provided by specific providers
    debugPrint('Executing UPDATE operation: ${operation.id}');
  }

  Future<void> _executeDelete(AtomicOperation operation, AtomicTransaction transaction) async {
    // Implementation will be provided by specific providers
    debugPrint('Executing DELETE operation: ${operation.id}');
  }

  Future<void> _executeStatusChange(AtomicOperation operation, AtomicTransaction transaction) async {
    // Implementation will be provided by specific providers
    debugPrint('Executing STATUS_CHANGE operation: ${operation.id}');
  }

  Future<void> _executeBatch(AtomicOperation operation, AtomicTransaction transaction) async {
    // Implementation will be provided by specific providers
    debugPrint('Executing BATCH operation: ${operation.id}');
  }

  void _rollbackOperation(AtomicOperation operation) {
    debugPrint('Rolling back operation: ${operation.id}');
    // Rollback logic will be implemented by specific providers
  }

  /// Clear all operations
  void clear() {
    if (_isExecuting) {
      throw StateError('Cannot clear operations during execution');
    }
    _pendingOperations.clear();
  }

  /// Get pending operations count
  int get pendingCount => _pendingOperations.length;

  /// Get completed operations count
  int get completedCount => _completedOperations.length;
}

/// Mixin for atomic operations support
mixin AtomicOperationsMixin<T> on AtomicState<T> {
  final AtomicOperationExecutor _executor = AtomicOperationExecutor();

  /// Queue an atomic operation
  void queueAtomicOperation(AtomicOperation operation) {
    _executor.queueOperation(operation);
  }

  /// Execute all queued operations
  Future<AtomicResult<List<AtomicOperation>>> executeQueuedOperations() async {
    return await _executor.executeAll();
  }

  /// Get pending operations count
  int get pendingOperationsCount => _executor.pendingCount;

  /// Clear all queued operations
  void clearQueuedOperations() {
    _executor.clear();
  }
}
