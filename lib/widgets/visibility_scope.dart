import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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
