import 'package:flutter/foundation.dart' show kDebugMode;

/// Pluggable error reporter. App provides an implementation (Crashlytics,
/// Sentry, custom logger) and chat layer routes all caught exceptions to it
/// instead of swallowing them silently.
abstract class ChatErrorReporter {
  void report(
    Object error, {
    StackTrace? stackTrace,
    String? source,
    Map<String, Object?>? context,
  });
}

/// Default reporter — logs to debug console only. Suitable for dev builds.
/// Production apps should provide a real reporter via [RoomManager.init].
class DefaultChatErrorReporter implements ChatErrorReporter {
  const DefaultChatErrorReporter();

  @override
  void report(
    Object error, {
    StackTrace? stackTrace,
    String? source,
    Map<String, Object?>? context,
  }) {
    final src = source != null ? '[$source] ' : '';
    final ctx = context != null && context.isNotEmpty ? ' $context' : '';
    if (kDebugMode) {
      print('$src$error$ctx');
    }
    if (stackTrace != null) {
      if (kDebugMode) {
        print(stackTrace);
      }
    }
  }
}
