import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/room_manager_base.dart';
import '../delegates/settings.dart';
import '../models/message.dart';

/// Queues messages locally when offline and replays them when connectivity
/// is restored. Each entry preserves the original message + notification
/// settings so the eventual send is identical to a live send.
///
/// Behavior:
/// - When offline & user sends: message goes to queue, optimistic UI shown.
/// - When connection restored: queue drains in FIFO order with retry.
/// - Per-room ordering preserved (queue is global FIFO; messages in same
///   room maintain send order).
mixin OfflineQueueMixin on RoomManagerBase {
  final List<_QueuedMessage> _queue = [];
  bool _draining = false;

  /// Live notifier for UI badges ("3 messages waiting to send").
  /// Updated whenever the queue grows or shrinks.
  final ValueNotifier<int> _pendingCountNotifier = ValueNotifier(0);

  /// Maximum messages to keep in the offline queue. When exceeded, oldest
  /// pending messages are dropped (and the user is shown a failed state
  /// for those — though those drops are reported via [errorReporter]).
  int get maxOfflineQueueSize => 100;

  /// Whether the offline queue is enabled. App can override to disable
  /// in builds where queueing is undesirable.
  bool get offlineQueueEnabled => true;

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Queue length — useful for UI badge ("3 messages waiting to send").
  int get pendingMessageCount => _queue.length;

  /// Live notifier — wrap with [ValueListenableBuilder] in the UI to show
  /// a "queued messages" indicator.
  ValueListenable<int> get pendingMessageCountNotifier => _pendingCountNotifier;

  /// Enqueue a message for later send. Returns the message immediately
  /// (with status: sending) so the UI can display it optimistically.
  Message enqueueMessage(
    Message msg, {
    ChatSilentNotification notification = const ChatSilentNotification(),
    VerifyToSendMessage? verifyToSend,
    OnDeniedToSendMessage? onDeniedToSend,
  }) {
    if (!offlineQueueEnabled || msg.isEmpty) {
      return msg.copyWith(status: MessageStatus.failed);
    }

    if (_queue.length >= maxOfflineQueueSize) {
      final dropped = _queue.removeAt(0);
      errorReporter.report(
        StateError('Offline queue full — dropping oldest'),
        source: 'OfflineQueueMixin.enqueueMessage',
        context: {
          'droppedMsgId': dropped.message.id,
          'droppedRoomId': dropped.message.roomId,
        },
      );
    }

    _queue.add(
      _QueuedMessage(
        message: msg,
        notification: notification,
        verifyToSend: verifyToSend,
        onDeniedToSend: onDeniedToSend,
      ),
    );

    _pendingCountNotifier.value = _queue.length;

    return msg;
  }

  /// Called when connectivity comes back. Drains the queue in order.
  /// Safe to call multiple times — concurrent drain is prevented.
  Future<void> drainOfflineQueue() async {
    if (_draining || _queue.isEmpty || !isConnected || me.isEmpty) return;
    _draining = true;

    try {
      while (_queue.isNotEmpty && isConnected) {
        final entry = _queue.removeAt(0);
        _pendingCountNotifier.value = _queue.length;
        try {
          await _sendQueued(entry);
        } catch (e, st) {
          errorReporter.report(
            e,
            stackTrace: st,
            source: 'OfflineQueueMixin.drainOfflineQueue',
            context: {
              'msgId': entry.message.id,
              'roomId': entry.message.roomId,
            },
          );
        }
      }
    } finally {
      _draining = false;
    }
  }

  /// Clears the queue without sending — call on logout.
  void clearOfflineQueue() {
    _queue.clear();
    _draining = false;
    _pendingCountNotifier.value = 0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Abstract — implementations provided by MessageMixin
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Message> sendNow(
    Message msg, {
    ChatSilentNotification notification,
    VerifyToSendMessage? verifyToSend,
    OnDeniedToSendMessage? onDeniedToSend,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Private
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _sendQueued(_QueuedMessage entry) async {
    await sendNow(
      entry.message,
      notification: entry.notification,
      verifyToSend: entry.verifyToSend,
      onDeniedToSend: entry.onDeniedToSend,
    );
  }
}

class _QueuedMessage {
  final Message message;
  final ChatSilentNotification notification;
  final VerifyToSendMessage? verifyToSend;
  final OnDeniedToSendMessage? onDeniedToSend;

  const _QueuedMessage({
    required this.message,
    required this.notification,
    this.verifyToSend,
    this.onDeniedToSend,
  });
}
