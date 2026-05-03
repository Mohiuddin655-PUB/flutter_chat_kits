part of '../core/chat_manager.dart';

extension ChatManagerActions on ChatManager {
  // ── React ─────────────────────────────────────────────────────────────────

  Future<void> react(
    Message msg,
    String? react, {
    ChatSilentNotification? notification,
  }) async {
    if (msg.isSending) return;
    put(msg.copyWith(react: react));
    final status = await RoomManager.i.updateMessage(
      msg.roomId,
      msg.id,
      {
        '${MessageKeys.i.reactions}.$me':
            (react ?? '').isEmpty ? ChatValueDelete() : react,
      },
      notification: notification ?? const ChatSilentNotification(),
    );
    if (!status) put(msg);
  }

  // ── Pin ───────────────────────────────────────────────────────────────────

  Future<void> pin(Message msg) async {
    if (msg.isSending) return;
    put(msg.copyWith(isPinned: true));
    final status = await RoomManager.i.updateMessage(msg.roomId, msg.id, {
      '${MessageKeys.i.pins}.$me': true,
    });
    if (!status) put(msg.copyWith(isPinned: false));
  }

  Future<void> unpin(Message msg) async {
    if (msg.isSending) return;
    put(msg.copyWith(isPinned: false));
    final status = await RoomManager.i.updateMessage(msg.roomId, msg.id, {
      '${MessageKeys.i.pins}.$me': ChatValueDelete(),
    });
    if (!status) put(msg.copyWith(isPinned: true));
  }

  Future<void> togglePin(Message msg) => msg.isPinned ? unpin(msg) : pin(msg);

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> delete(Message msg) async {
    if (!msg.isSentByMe || msg.isSending) return;
    put(msg.copyWith(isDeleted: true));

    final isLastMessage = room.lastMessageId == msg.id;
    final status = await RoomManager.i.updateMessage(
      msg.roomId,
      msg.id,
      {MessageKeys.i.isDeleted: true},
      roomValues: {
        if (isLastMessage) ...{
          RoomKeys.i.lastMessage: msg.lastMessage(deleted: true),
          RoomKeys.i.lastMessageSenderId: me,
          RoomKeys.i.lastMessageDeleted: true,
        },
      },
    );
    if (!status) put(msg.copyWith(isDeleted: false));
  }

  Future<void> deletePermanently(Message msg) async {
    if (!msg.isSentByMe || msg.isSending) return;
    pop(msg);
    final status = await RoomManager.i.deleteMessage(msg);
    if (!status) put(msg);
  }

  Future<void> deleteForMe(Message msg) async {
    if (msg.isSending) return;
    put(msg.copyWith(isDeletedForMe: true));
    final status = await RoomManager.i.updateMessage(msg.roomId, msg.id, {
      '${MessageKeys.i.deletes}.$me': true,
    });
    if (!status) put(msg.copyWith(isDeletedForMe: false));
  }

  Future<void> deletes(List<Message> messages) async {
    final eligible =
        messages.where((e) => e.isSentByMe && !e.isSending).toList();
    if (eligible.isEmpty) return;
    puts(eligible.map((e) => e.copyWith(isDeleted: true)));
    final status = await RoomManager.i.deleteMessages(eligible);
    if (!status) puts(eligible.map((e) => e.copyWith(isDeleted: false)));
  }

  Future<void> deletesForMe(Iterable<Message> messages) async {
    final eligible = messages.where((e) => !e.isSending).toList();
    if (eligible.isEmpty) return;
    puts(eligible.map((e) => e.copyWith(isDeletedForMe: true)));
    final entries = eligible.map(
      (e) => MapEntry(e.id, {'${MessageKeys.i.deletes}.$me': true}),
    );
    final status = await RoomManager.i.updateMessages(
      roomId,
      Map.fromEntries(entries),
    );
    if (!status) puts(eligible.map((e) => e.copyWith(isDeletedForMe: false)));
  }

  // ── Remove ────────────────────────────────────────────────────────────────

  Future<void> remove(Message msg) async {
    if (!msg.shouldRemove && msg.isRemovedByMe) return;
    pop(msg);

    final allRemoved = room.participants.every(
      (uid) => uid == me || msg.removes[uid] == true,
    );

    final status = allRemoved
        ? await RoomManager.i.deleteMessage(msg)
        : await RoomManager.i.updateMessage(msg.roomId, msg.id, {
            '${MessageKeys.i.removes}.$me': true,
          });

    if (!status) put(msg);
  }
}
