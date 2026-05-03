import 'dart:async';

import '../core/room_manager_base.dart';
import '../delegates/message.dart';
import '../delegates/settings.dart';
import '../models/message.dart';
import '../models/profile.dart';
import '../models/room.dart';
import '../utils/field_value.dart';
import '../utils/file_upload_helper.dart';
import '../utils/retry_helper.dart';
import 'offline_queue_mixin.dart';

mixin MessageMixin on RoomManagerBase, OfflineQueueMixin {
  // ═══════════════════════════════════════════════════════════════════════════
  // Failed Message Tracking
  // ═══════════════════════════════════════════════════════════════════════════

  /// Messages that failed to send actively (network died mid-send, server
  /// error after retries exhausted, etc.). On reconnect / foreground these
  /// auto-retry, similar to how the offline queue drains.
  final Map<String, _FailedSend> _failedMessages = {};

  bool _retryingFailed = false;

  /// Maximum failed messages to retain. Beyond this, oldest are dropped.
  int get maxFailedMessageBuffer => 50;

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<List<Message>> stream(String roomId) {
    if (me.isEmpty) return Stream.value([]);
    return messageDelegate.stream(roomId);
  }

  Future<bool> forward(
    List<String> targetRoomIds,
    Message msg, {
    ChatNewMessageNotification notification =
        const ChatNewMessageNotification(),
  }) async {
    if (me.isEmpty || targetRoomIds.isEmpty) return false;
    try {
      for (final id in targetRoomIds) {
        await createMessage(
          msg.copyWith(
            isForwarded: true,
            roomId: id,
            clearReplyId: true,
            createdAt: ChatValueTimestamp.now(),
            updatedAt: ChatValueTimestamp.now(),
          ),
          notification: notification,
        );
      }
      return true;
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'MessageMixin.forward',
        context: {'targetRoomIds': targetRoomIds, 'msgId': msg.id},
      );
      return false;
    }
  }

  Future<Message> createMessage(
    Message msg, {
    ChatSilentNotification notification = const ChatSilentNotification(),
    VerifyToSendMessage? verifyToSend,
    OnDeniedToSendMessage? onDeniedToSend,
  }) async {
    final failed = msg.copyWith(status: MessageStatus.failed);
    if (me.isEmpty || msg.isEmpty) return failed;

    if (!isConnected && offlineQueueEnabled) {
      final target = room(msg.roomId);
      put(
        target.copyWith(
          lastMessage: msg.lastMessage(),
          lastMessageId: msg.id,
          lastMessageSenderId: me,
          lastMessageDeleted: false,
          updatedAt: ChatValueTimestamp.now(),
        ),
      );
      return enqueueMessage(
        msg,
        notification: notification,
        verifyToSend: verifyToSend,
        onDeniedToSend: onDeniedToSend,
      );
    }

    return sendNow(
      msg,
      notification: notification,
      verifyToSend: verifyToSend,
      onDeniedToSend: onDeniedToSend,
    );
  }

  /// Direct send without queue check. Used by [createMessage] for online
  /// path and by [drainOfflineQueue] for queued messages.
  @override
  Future<Message> sendNow(
    Message msg, {
    ChatSilentNotification notification = const ChatSilentNotification(),
    VerifyToSendMessage? verifyToSend,
    OnDeniedToSendMessage? onDeniedToSend,
  }) async {
    final failed = msg.copyWith(status: MessageStatus.failed);
    if (me.isEmpty || msg.isEmpty) return failed;

    final target = room(msg.roomId);
    if (verifyToSend != null && !verifyToSend(target)) {
      onDeniedToSend?.call(target);
      return msg;
    }

    final body = msg.lastMessage();
    final optimistic = target.copyWith(
      lastMessage: body,
      lastMessageId: msg.id,
      lastMessageSenderId: me,
      lastMessageDeleted: false,
      updatedAt: ChatValueTimestamp.now(),
    );

    try {
      put(optimistic);

      final uploaded = await _replace(msg);
      if (uploaded.isEmpty) {
        put(target);
        _trackFailed(msg, notification, verifyToSend, onDeniedToSend);
        return failed;
      }

      final sent = uploaded.copyWith(status: MessageStatus.sent);
      final normalizedMsg = n.normalize(sent.source, n.message);

      await RetryHelper.run(
        operation:
            () => messageDelegate.create(msg.roomId, msg.id, normalizedMsg),
        onRetry: (attempt, error) {
          managerOrNull(
            msg.roomId,
          )?.put(uploaded.copyWith(status: MessageStatus.retrying));
          errorReporter.report(
            error,
            source: 'MessageMixin.sendNow.retry',
            context: {
              'roomId': msg.roomId,
              'msgId': msg.id,
              'attempt': attempt,
              'phase': 'create',
            },
          );
        },
      );

      await RetryHelper.run(
        operation:
            () => roomDelegate.update(
              msg.roomId,
              n.normalize(
                _roomMessageUpdatePayload(target, msg.id, body),
                n.room,
              ),
            ),
        onRetry: (attempt, error) {
          errorReporter.report(
            error,
            source: 'MessageMixin.sendNow.retry',
            context: {
              'roomId': msg.roomId,
              'msgId': msg.id,
              'attempt': attempt,
              'phase': 'roomUpdate',
            },
          );
        },
      );

      await sendNotification(msg, notification);

      _failedMessages.remove(msg.id);

      return sent;
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'MessageMixin.sendNow',
        context: {'roomId': msg.roomId, 'msgId': msg.id, 'type': msg.type.name},
      );
      put(target);
      _trackFailed(msg, notification, verifyToSend, onDeniedToSend);
      return failed;
    }
  }

  /// Auto-retry all failed messages. Called on reconnect / foreground.
  /// Safe to call multiple times — concurrent retry is prevented.
  Future<void> retryFailedMessages() async {
    if (_retryingFailed || _failedMessages.isEmpty) return;
    if (!isConnected || me.isEmpty) return;

    _retryingFailed = true;

    try {
      // Snapshot — new failures during retry won't be retried this round
      final entries = _failedMessages.values.toList();
      _failedMessages.clear();

      for (final entry in entries) {
        if (!isConnected) {
          // Lost connection mid-retry — re-queue remaining
          _failedMessages[entry.message.id] = entry;
          continue;
        }
        try {
          await sendNow(
            entry.message,
            notification: entry.notification,
            verifyToSend: entry.verifyToSend,
            onDeniedToSend: entry.onDeniedToSend,
          );
        } catch (e, st) {
          errorReporter.report(
            e,
            stackTrace: st,
            source: 'MessageMixin.retryFailedMessages',
            context: {
              'msgId': entry.message.id,
              'roomId': entry.message.roomId,
            },
          );
        }
      }
    } finally {
      _retryingFailed = false;
    }
  }

  /// Manually retry a specific failed message. Returns the result.
  Future<Message> retryFailedMessage(String msgId) async {
    final entry = _failedMessages.remove(msgId);
    if (entry == null) {
      return const Message.empty().copyWith(status: MessageStatus.failed);
    }
    return sendNow(
      entry.message,
      notification: entry.notification,
      verifyToSend: entry.verifyToSend,
      onDeniedToSend: entry.onDeniedToSend,
    );
  }

  /// Clears the failed-message buffer — call on logout.
  void clearFailedMessages() {
    _failedMessages.clear();
    _retryingFailed = false;
  }

  /// Number of failed messages awaiting retry.
  int get failedMessageCount => _failedMessages.length;

  @override
  Future<void> createMessageByBot(Message msg) async {
    if (msg.isEmpty) return;
    final target = room(msg.roomId);
    final body = msg.lastMessage();
    try {
      final normalizedMsg = n.normalize(msg.source, n.message);
      await messageDelegate.create(msg.roomId, msg.id, normalizedMsg);
      await roomDelegate.update(
        msg.roomId,
        n.normalize(
          _roomMessageUpdatePayload(
            target,
            msg.id,
            body,
            senderId: msg.senderId,
          ),
          n.room,
        ),
      );
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'MessageMixin.createMessageByBot',
        context: {'roomId': msg.roomId, 'msgId': msg.id},
      );
    }
  }

  Future<bool> deleteMessage(
    Message msg, {
    bool deleteBothAsSync = false,
  }) async {
    if (me.isEmpty) return false;
    try {
      await messageDelegate.delete(msg.roomId, msg.id);
      await _deleteStorageFiles(
        msg.findPathOrUrls(true),
        sync: deleteBothAsSync,
      );
      _failedMessages.remove(msg.id);
      return true;
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'MessageMixin.deleteMessage',
        context: {'roomId': msg.roomId, 'msgId': msg.id},
      );
      return false;
    }
  }

  Future<bool> deleteMessages(
    Iterable<Message> messages, {
    bool deleteBothAsSync = false,
  }) async {
    if (me.isEmpty || messages.isEmpty) return false;
    try {
      await messageDelegate.deletes(messages);
      final urls = messages.expand((m) => m.findPathOrUrls(true)).toList();
      await _deleteStorageFiles(urls, sync: deleteBothAsSync);
      for (final m in messages) {
        _failedMessages.remove(m.id);
      }
      return true;
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'MessageMixin.deleteMessages',
        context: {'count': messages.length},
      );
      return false;
    }
  }

  @override
  Future<bool> updateMessage(
    String roomId,
    String msgId,
    Map<String, dynamic> value, {
    Map<String, dynamic> roomValues = const {},
    ChatSilentNotification? notification,
  }) async {
    if (me.isEmpty) return false;
    try {
      await RetryHelper.run(
        operation: () {
          return messageDelegate.update(
            roomId,
            msgId,
            n.normalize(value, n.message),
          );
        },
      );
      if (roomValues.isNotEmpty) {
        await RetryHelper.run(
          operation: () {
            return roomDelegate.update(roomId, n.normalize(roomValues, n.room));
          },
        );
      }

      if (notification != null) {
        final msg = managerOrNull(roomId)?.mappedMessages[msgId];
        if (msg != null) await sendNotification(msg, notification);
      }

      return true;
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'MessageMixin.updateMessage',
        context: {'roomId': roomId, 'msgId': msgId},
      );
      return false;
    }
  }

  Future<bool> updateMessageExtra(
    String roomId,
    String msgId,
    Map<String, dynamic> extra,
  ) async {
    if (me.isEmpty) return false;
    try {
      await messageDelegate.update(roomId, msgId, {
        MessageKeys.i.extra: n.normalize(extra, n.message),
      });
      return true;
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'MessageMixin.updateMessageExtra',
        context: {'roomId': roomId, 'msgId': msgId},
      );
      return false;
    }
  }

  Future<bool> updateMessages(
    String roomId,
    Map<String, Map<String, dynamic>> values,
  ) async {
    if (me.isEmpty || values.isEmpty) return false;
    try {
      final normalized = values.map(
        (k, v) => MapEntry(k, n.normalize(v, n.message)),
      );
      await messageDelegate.updates(roomId, normalized);
      return true;
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'MessageMixin.updateMessages',
        context: {'roomId': roomId, 'count': values.length},
      );
      return false;
    }
  }

  // ── Background Delivery ───────────────────────────────────────────────────

  @override
  Future<void> markDeliveredForRoom(String roomId) async {
    if (me.isEmpty || roomId.isEmpty) return;
    try {
      final r = room(roomId);
      final lastMsgId = r.lastMessageId;
      if (lastMsgId.isEmpty) return;
      if (r.lastMessageSenderId == me) return;

      final myStatus = r.lastMessageStatuses[me];
      if (myStatus == MessageStatus.delivered ||
          myStatus == MessageStatus.seen) {
        return;
      }
      await updateMessage(
        roomId,
        lastMsgId,
        {'${MessageKeys.i.statuses}.$me': MessageStatus.delivered.name},
        roomValues: {
          '${RoomKeys.i.lastMessageStatuses}.$me': MessageStatus.delivered.name,
        },
      );
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'MessageMixin.markDeliveredForRoom',
        context: {'roomId': roomId},
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Private Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  void _trackFailed(
    Message msg,
    ChatSilentNotification notification,
    VerifyToSendMessage? verifyToSend,
    OnDeniedToSendMessage? onDeniedToSend,
  ) {
    if (_failedMessages.length >= maxFailedMessageBuffer) {
      final oldestKey = _failedMessages.keys.first;
      _failedMessages.remove(oldestKey);
    }
    _failedMessages[msg.id] = _FailedSend(
      message: msg,
      notification: notification,
      verifyToSend: verifyToSend,
      onDeniedToSend: onDeniedToSend,
    );
  }

  Map<String, dynamic> _roomMessageUpdatePayload(
    Room room,
    String msgId,
    String body, {
    String? senderId,
  }) {
    final isBot = senderId?.startsWith(kBotPrefix) ?? false;
    senderId ??= me;
    return {
      RoomKeys.i.lastMessage: body,
      RoomKeys.i.lastMessageId: msgId,
      RoomKeys.i.lastMessageSenderId: senderId,
      RoomKeys.i.lastMessageDeleted: false,
      RoomKeys.i.updatedAt: ChatValueTimestamp(),
      if (!isBot)
        RoomKeys.i.lastMessageStatuses: {
          for (final uid in room.participants) uid: MessageStatus.sent.name,
        },
      RoomKeys.i.unseenCount: {
        for (final uid in room.participants)
          if (uid != senderId) uid: ChatValueIncrement(1),
      },
    };
  }

  Future<Message> _replace(Message msg) async {
    final paths = _localPathsFor(msg);
    if (paths.isEmpty) return msg;

    final urls = await _upload(msg.roomId, msg.id, msg.type, paths);

    if (msg is VideoMessage) {
      final thumbnail =
          msg.thumbnail.isNotEmpty
              ? await _upload(msg.roomId, msg.id, msg.type, [
                msg.thumbnail,
              ]).then((v) => v.firstOrNull ?? '')
              : '';
      return msg.copyWith(thumbnail: thumbnail, url: urls.firstOrNull ?? '');
    }

    return switch (msg) {
      AudioMessage() => msg.copyWith(url: urls.firstOrNull ?? ''),
      ImageMessage() => msg.copyWith(urls: urls),
      _ => msg,
    };
  }

  List<String> _localPathsFor(Message msg) => switch (msg) {
    AudioMessage() => [msg.url],
    ImageMessage() => msg.urls,
    VideoMessage() => [msg.url],
    _ => [],
  };

  Future<List<String>> _upload(
    String roomId,
    String msgId,
    MessageType type,
    List<String> paths,
  ) async {
    if (paths.isEmpty) return [];

    final futures = paths.indexed.map((entry) async {
      final (index, path) = entry;
      if (path.isEmpty) return '';
      try {
        final ext = FileUploadHelper.fileExtension(path, fallbackType: type);
        final prefix = FileUploadHelper.filePrefix(ext, fallbackType: type);
        final name =
            '${prefix}_${msgId}_${index + 1}${ext != null ? '.$ext' : ''}';
        return messageDelegate.upload(
          MessageUploadData(
            roomId: roomId,
            msgId: msgId,
            path: path,
            name: name,
          ),
        );
      } catch (e, st) {
        errorReporter.report(
          e,
          stackTrace: st,
          source: 'MessageMixin._upload',
          context: {'roomId': roomId, 'msgId': msgId, 'path': path},
        );
        return '';
      }
    });

    final urls = await Future.wait(futures);
    return urls.where((url) => url.isNotEmpty).toList();
  }

  Future<void> _deleteStorageFiles(
    Iterable<String> urls, {
    required bool sync,
  }) async {
    if (urls.isEmpty) return;
    final deletions = urls.map((url) async {
      try {
        await messageDelegate.deleteFromStorage(url);
      } catch (e, st) {
        errorReporter.report(
          e,
          stackTrace: st,
          source: 'MessageMixin._deleteStorageFiles',
          context: {'url': url},
        );
      }
    });
    if (sync) {
      await Future.wait(deletions);
    } else {
      unawaited(Future.wait(deletions));
    }
  }
}

class _FailedSend {
  final Message message;
  final ChatSilentNotification notification;
  final VerifyToSendMessage? verifyToSend;
  final OnDeniedToSendMessage? onDeniedToSend;

  const _FailedSend({
    required this.message,
    required this.notification,
    this.verifyToSend,
    this.onDeniedToSend,
  });
}
