part of '../core/chat_manager.dart';

extension ChatManagerStatus on ChatManager {
  // ── Typing ────────────────────────────────────────────────────────────────

  Future<void> typing(bool status) =>
      RoomManager.i.markAsTyping(roomId, status);

  // ── Seen ──────────────────────────────────────────────────────────────────

  Future<void> seen(Message msg) async {
    if (msg.isSentByMe) return;
    if (msg.isSeenByMe) return;
    put(msg.copyWith(status: MessageStatus.seen));

    final isLastMsg = room.lastMessageId == msg.id;

    final success = await RoomManager.i.updateMessage(
      msg.roomId,
      msg.id,
      {'${MessageKeys.i.statuses}.$me': MessageStatus.seen.name},
      roomValues: {
        if (isLastMsg)
          '${RoomKeys.i.lastMessageStatuses}.$me': MessageStatus.seen.name,
      },
    );
    if (!success) put(msg);
  }

  // ── Delivered ────────────────────────────────────────────

  Future<void> _deliverSingle(Message msg) async {
    if (msg.isSentByMe) return;
    if (msg.isDeliveredByMe) return;
    if (_pendingDeliveryIds.contains(msg.id)) return;

    _pendingDeliveryIds.add(msg.id);
    put(msg.copyWith(status: MessageStatus.delivered));

    final isLastMsg = room.lastMessageId == msg.id;

    final success = await RoomManager.i.updateMessage(
      msg.roomId,
      msg.id,
      {'${MessageKeys.i.statuses}.$me': MessageStatus.delivered.name},
      roomValues: {
        if (isLastMsg)
          '${RoomKeys.i.lastMessageStatuses}.$me': MessageStatus.delivered.name,
      },
    );

    _pendingDeliveryIds.remove(msg.id);
    if (!success) put(msg);
  }

  // ── Visibility ────────────────────────────────────────────────────────────

  void visible(Message msg) {
    if (msg.isSentByMe) return;
    if (msg.isSeenByMe) return;
    seen(msg);
  }

  void invisible(Message msg) {
    if (msg.isSentByMe) return;
    if (msg.isDeliveredByMe) return;
    _deliverSingle(msg);
  }
}
