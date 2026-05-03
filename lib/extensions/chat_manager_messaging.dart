part of '../core/chat_manager.dart';

extension ChatManagerMessaging on ChatManager {
  // ── Send ──────────────────────────────────────────────────────────────────

  Future<void> send(
    Message message, {
    ChatSilentNotification? notification,
    VerifyToSendMessage? verifyToSend,
    OnDeniedToSendMessage? onDeniedToSend,
  }) async {
    if (room.isLocal) {
      final global = await RoomManager.i.createOrGetRoom(
        room,
        notification: const ChatSilentNotification(),
      );
      if (global.isEmpty) return;
      room = global;
      notify();
    }

    final msg = message.copyWith(roomId: roomId, replyId: replyMsg?.id);

    _pendingSendIds.add(msg.id);
    put(msg);

    final sent = await RoomManager.i.createMessage(
      msg,
      notification: notification ?? const ChatSilentNotification(),
      verifyToSend: verifyToSend,
      onDeniedToSend: onDeniedToSend,
    );

    _pendingSendIds.remove(sent.id);
    put(sent);
  }

  // ── Edit / Update / Forward ───────────────────────────────────────────────

  Future<void> edit(Message msg, String content) async {
    if (content.isEmpty || content == msg.content) return;

    final editedAt = ChatValueTimestamp.now();

    final updatedMsg = switch (msg) {
      TextMessage() => msg.copyWith(
          isEdited: true,
          editedAt: editedAt,
          text: content,
        ),
      LinkMessage() => msg.copyWith(
          isEdited: true,
          editedAt: editedAt,
          link: content,
        ),
      _ => null,
    };

    if (updatedMsg == null) return;
    put(updatedMsg);

    final status = await RoomManager.i.updateMessage(
      roomId,
      msg.id,
      {
        MessageKeys.i.isEdited: true,
        MessageKeys.i.content: content,
        MessageKeys.i.editedAt: editedAt,
      },
      roomValues: {
        if (room.lastMessageId == msg.id)
          RoomKeys.i.lastMessage: updatedMsg.lastMessage(),
      },
    );

    if (!status) put(msg);
  }

  Future<void> update(String msgId, Map<String, dynamic> changes) async {
    if (changes.isEmpty) return;
    final msg = mappedMessages[msgId];
    if (msg == null) return;
    put(msg.resolveWith(changes));
    final status = await RoomManager.i.updateMessage(roomId, msgId, changes);
    if (!status) put(msg);
  }

  Future<void> forward(List<String> targetRoomIds, Message msg) async {
    if (targetRoomIds.isEmpty) return;
    await RoomManager.i.forward(targetRoomIds, msg);
  }
}
