import 'dart:math' show Random, max;

/// Retries an async operation with exponential backoff and jitter.
///
/// Used for network operations that may fail transiently — server hiccup,
/// temporary connection drop, rate limit. The caller decides via
/// [shouldRetry] whether a particular error is worth retrying (don't retry
/// auth errors, validation errors, etc.).
///
/// Backoff schedule: initialDelay, ×2, ×2, ... up to maxDelay.
/// Jitter (±25%) is added to prevent thundering herd when many clients
/// retry simultaneously after an outage.
class RetryHelper {
  RetryHelper._();

  static final Random _rng = Random();

  static Future<T> run<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    Duration maxDelay = const Duration(seconds: 8),
    bool Function(Object error)? shouldRetry,
    void Function(int attempt, Object error)? onRetry,
  }) async {
    assert(maxAttempts >= 1);

    Object? lastError;
    StackTrace? lastStack;
    var delay = initialDelay;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (e, st) {
        lastError = e;
        lastStack = st;

        if (attempt >= maxAttempts) break;
        if (shouldRetry != null && !shouldRetry(e)) break;

        onRetry?.call(attempt, e);

        await Future.delayed(_jittered(delay));
        delay = _nextDelay(delay, maxDelay);
      }
    }

    Error.throwWithStackTrace(lastError!, lastStack ?? StackTrace.current);
  }

  static Duration _jittered(Duration base) {
    final ms = base.inMilliseconds;
    final jitter = (ms * 0.25 * (_rng.nextDouble() * 2 - 1)).round();
    return Duration(milliseconds: max(0, ms + jitter));
  }

  static Duration _nextDelay(Duration current, Duration max) {
    final doubled = current * 2;
    return doubled > max ? max : doubled;
  }
}
