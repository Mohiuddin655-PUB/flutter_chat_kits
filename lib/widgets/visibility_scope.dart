import 'package:flutter/foundation.dart' show ValueNotifier, ValueListenable;
import 'package:flutter/widgets.dart' show BuildContext, InheritedNotifier;

class ChatVisibilityScope extends InheritedNotifier<ValueNotifier<bool>> {
  const ChatVisibilityScope({
    super.key,
    required ValueNotifier<bool> super.notifier,
    required super.child,
  });

  static ValueListenable<bool>? of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<ChatVisibilityScope>();
    return w?.notifier;
  }
}
