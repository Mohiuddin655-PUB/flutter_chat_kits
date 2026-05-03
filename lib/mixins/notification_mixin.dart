import 'package:flutter/foundation.dart' show debugPrint;

import '../core/room_manager_base.dart' show RoomManagerBase;
import '../delegates/notification.dart' show ChatNotificationContent;
import '../delegates/settings.dart'
    show
        ChatNotification,
        ChatSilentNotification,
        ChatNewRoomNotification,
        ChatNewMessageNotification,
        ChatDeleteMessageNotification,
        ChatCustomNotification;
import '../models/message.dart' show Message;
import '../models/profile.dart' show UserProfile;
import '../models/room.dart' show Room;

mixin NotificationMixin on RoomManagerBase {
  // ═══════════════════════════════════════════════════════════════════════════
  // RoomManagerBase contract
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> pushNotification({
    required String roomId,
    required String msgId,
    required ChatNotification notification,
  }) async {
    if (me.isEmpty) return;
    if (notification.title == null || notification.body == null) return;

    final target = room(roomId);
    if (target.isEmpty) return;

    final sender = await notification.sender?.call() ?? profileFor(me);

    for (final participant in target.participants) {
      if (participant == me) continue;
      if (target.mutes.contains(participant)) continue;

      try {
        final receiver = profileFor(participant);
        if (receiver is! UserProfile) continue;
        if (receiver.isEmpty || receiver.isActiveRoom(roomId)) continue;

        final allowed = await _isNotificationAllowed(
          notification,
          participant,
          target,
          receiver,
        );
        if (!allowed) continue;

        await notificationDelegate.sendNotification(
          ChatNotificationContent(
            id: msgId,
            roomId: roomId,
            title: notification.title!,
            body: notification.body!,
            token: receiver.token,
            platform: receiver.platform,
            profile: sender,
          ),
        );
      } catch (e) {
        debugPrint('[NotificationMixin] failed for $participant: $e');
      }
    }
  }

  @override
  Future<void> sendNotification(
    Message msg,
    ChatSilentNotification notification,
  ) async {
    if (me.isEmpty) return;
    final sender = profileFor(me);
    return pushNotification(
      roomId: msg.roomId,
      msgId: msg.id,
      notification: notification.copyWith(
        title: notification.title ?? sender.name ?? 'Someone',
        body: notification.body ?? msg.notificationBody(sender.name),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Private Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> _isNotificationAllowed(
    ChatNotification notification,
    String participant,
    Room room,
    UserProfile receiver,
  ) async {
    if (notification.verify != null) {
      final allowed = notification.verify!(room, receiver);
      if (!allowed) notification.onDenied?.call(room, receiver);
      return allowed;
    }

    return switch (notification) {
      ChatNewRoomNotification() =>
        settingsDelegate.isEnabledToSendNewRoomNotification(participant),
      ChatNewMessageNotification() =>
        settingsDelegate.isEnabledToSendMessageNotification(participant),
      ChatDeleteMessageNotification() =>
        settingsDelegate.isEnabledToSendDeleteRoomNotification(participant),
      ChatCustomNotification() => settingsDelegate.isEnabled(
          participant,
          notification.type,
        ),
      _ => Future.value(false),
    };
  }
}
