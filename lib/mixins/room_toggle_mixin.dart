import '../core/room_manager_base.dart';
import '../models/room.dart';
import '../utils/field_value.dart';

mixin RoomToggleMixin on RoomManagerBase {
  Future<void> archive(Room room) => _toggleMeInSet(
    room,
    operation: 'archive',
    guard: room.isArchivedByMe,
    field: RoomKeys.i.archives,
    add: true,
    optimistic: room.copyWith(isArchived: true),
  );

  Future<void> unarchive(Room room) => _toggleMeInSet(
    room,
    operation: 'unarchive',
    guard: !room.isArchivedByMe,
    field: RoomKeys.i.archives,
    add: false,
    optimistic: room.copyWith(isArchived: false),
  );

  Future<void> mute(Room room) => _toggleMeInSet(
    room,
    operation: 'mute',
    guard: room.isMutedByMe,
    field: RoomKeys.i.mutes,
    add: true,
    optimistic: room.copyWith(isMuted: true),
  );

  Future<void> unmute(Room room) => _toggleMeInSet(
    room,
    operation: 'unmute',
    guard: !room.isMutedByMe,
    field: RoomKeys.i.mutes,
    add: false,
    optimistic: room.copyWith(isMuted: false),
  );

  Future<void> pin(Room room) => _toggleMeInSet(
    room,
    operation: 'pin',
    guard: room.isPinnedByMe,
    field: RoomKeys.i.pins,
    add: true,
    optimistic: room.copyWith(isPinned: true),
  );

  Future<void> unpin(Room room) => _toggleMeInSet(
    room,
    operation: 'unpin',
    guard: !room.isPinnedByMe,
    field: RoomKeys.i.pins,
    add: false,
    optimistic: room.copyWith(isPinned: false),
  );

  Future<void> block(Room room, Iterable<String> participants) =>
      _toggleParticipantsInSet(
        room,
        operation: 'block',
        participants: participants,
        field: RoomKeys.i.blocks,
        add: true,
        optimistic: room.copyWith(blocks: participants, isBlocked: true),
      );

  Future<void> unblock(Room room, Iterable<String> participants) =>
      _toggleParticipantsInSet(
        room,
        operation: 'unblock',
        participants: participants,
        field: RoomKeys.i.blocks,
        add: false,
        optimistic: room.copyWith(blocks: participants, isBlocked: false),
      );

  Future<void> restrict(Room room, Iterable<String> participants) =>
      _toggleParticipantsInSet(
        room,
        operation: 'restrict',
        participants: participants,
        field: RoomKeys.i.restricts,
        add: true,
        optimistic: room.copyWith(restricts: participants, isRestricted: true),
      );

  Future<void> unrestrict(Room room, Iterable<String> participants) =>
      _toggleParticipantsInSet(
        room,
        operation: 'unrestrict',
        participants: participants,
        field: RoomKeys.i.restricts,
        add: false,
        optimistic: room.copyWith(restricts: participants, isRestricted: false),
      );

  Future<void> join(Room room) async {
    if (me.isEmpty) return;
    put(room.copyWith(isLeaved: false));
    try {
      await roomDelegate.update(
        room.id,
        n.normalize({
          if (room.isAdminByMe) RoomKeys.i.isDeleted: ChatValueDelete(),
          RoomKeys.i.leaves: ChatValueRemove([me]),
          RoomKeys.i.participants: ChatValueAdd([me]),
        }, n.room),
      );
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'RoomToggleMixin.join',
        context: {'roomId': room.id},
      );
      pop(room.id);
    }
  }

  Future<void> leave(Room room) async {
    if (me.isEmpty || room.isLeaveByMe) return;
    pop(room.id);
    try {
      await roomDelegate.update(
        room.id,
        n.normalize({
          if (room.isAdminByMe) RoomKeys.i.isDeleted: true,
          RoomKeys.i.leaves: ChatValueAdd([me]),
          RoomKeys.i.participants: ChatValueRemove([me]),
        }, n.room),
      );
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'RoomToggleMixin.leave',
        context: {'roomId': room.id},
      );
      put(room);
      return;
    }
    reconcileMetadata(buildActiveParticipants());
  }

  Future<void> remove(Room room) async {
    if (me.isEmpty || room.isRemovedByMe) return;
    pop(room.id);
    try {
      await roomDelegate.update(
        room.id,
        n.normalize({'${RoomKeys.i.removes}.$me': room.lastMessageId}, n.room),
      );
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'RoomToggleMixin.remove',
        context: {'roomId': room.id},
      );
      put(room);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Private Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _toggleMeInSet(
    Room room, {
    required String operation,
    required bool guard,
    required String field,
    required bool add,
    required Room optimistic,
  }) async {
    if (me.isEmpty || guard) return;
    put(optimistic);
    try {
      await roomDelegate.update(
        room.id,
        n.normalize({
          field: add ? ChatValueAdd([me]) : ChatValueRemove([me]),
        }, n.room),
      );
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'RoomToggleMixin.$operation',
        context: {'roomId': room.id, 'field': field},
      );
      put(room);
    }
  }

  Future<void> _toggleParticipantsInSet(
    Room room, {
    required String operation,
    required Iterable<String> participants,
    required String field,
    required bool add,
    required Room optimistic,
  }) async {
    final list = participants.toList();
    if (me.isEmpty || list.isEmpty) return;
    put(optimistic);
    try {
      await roomDelegate.update(
        room.id,
        n.normalize({
          field: add ? ChatValueAdd(list) : ChatValueRemove(list),
        }, n.room),
      );
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'RoomToggleMixin.$operation',
        context: {'roomId': room.id, 'field': field, 'participants': list},
      );
      put(room);
    }
  }
}
