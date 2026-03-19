import 'package:flutter/material.dart';
import '../core/atomic_state.dart';

/// Widget for handling atomic operation errors
class AtomicErrorHandler extends StatelessWidget {
  final String? error;
  final VoidCallback? onRetry;
  final Widget? child;

  const AtomicErrorHandler({
    super.key,
    this.error,
    this.onRetry,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Operation Failed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      );
    }

    return child ?? const SizedBox.shrink();
  }
}

/// Mixin for handling atomic results in widgets
mixin AtomicResultHandler<T extends StatefulWidget> on State<T> {
  void handleAtomicResult<R>(
    AtomicResult<R> result, {
    String? successMessage,
    String? errorPrefix,
    void Function(R data)? onSuccess,
    void Function(String error)? onError,
  }) {
    if (result.isSuccess) {
      if (successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
      onSuccess?.call(result.data as R);
    } else {
      final errorMessage = errorPrefix != null
          ? '$errorPrefix: ${result.error}'
          : result.error!;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      onError?.call(result.error!);
    }
  }

  void showAtomicError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
      ),
    );
  }

  void showAtomicSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
