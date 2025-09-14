import 'package:flutter/foundation.dart';

/// Base class for atomic state operations
abstract class AtomicState<T> extends ChangeNotifier {
  T _state;
  bool _isLoading = false;
  String? _error;

  AtomicState(this._state);

  /// Current state value
  T get state => _state;

  /// Loading indicator
  bool get isLoading => _isLoading;

  /// Error message if any
  String? get error => _error;

  /// Atomically update the state
  Future<void> atomicUpdate(Future<T> Function(T currentState) updater) async {
    if (_isLoading) return; // Prevent concurrent updates

    _setLoading(true);
    _clearError();

    try {
      final newState = await updater(_state);
      _setState(newState);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Atomically update state synchronously
  void atomicUpdateSync(T Function(T currentState) updater) {
    if (_isLoading) return; // Prevent concurrent updates

    try {
      final newState = updater(_state);
      _setState(newState);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Set state atomically
  void _setState(T newState) {
    _state = newState;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error state
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset to initial state
  void reset(T initialState) {
    _state = initialState;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}

/// Atomic operation result
class AtomicResult<T> {
  final bool success;
  final T? data;
  final String? error;

  const AtomicResult.success(this.data) : success = true, error = null;
  const AtomicResult.failure(this.error) : success = false, data = null;

  bool get isSuccess => success;
  bool get isFailure => !success;
}

/// Atomic transaction manager
class AtomicTransaction {
  final List<VoidCallback> _rollbackActions = [];
  bool _committed = false;

  /// Add a rollback action
  void addRollback(VoidCallback rollback) {
    if (_committed) throw StateError('Transaction already committed');
    _rollbackActions.add(rollback);
  }

  /// Commit the transaction
  void commit() {
    _committed = true;
    _rollbackActions.clear();
  }

  /// Rollback all operations
  void rollback() {
    if (_committed) return;
    
    for (final action in _rollbackActions.reversed) {
      try {
        action();
      } catch (e) {
        debugPrint('Rollback action failed: $e');
      }
    }
    _rollbackActions.clear();
  }
}
