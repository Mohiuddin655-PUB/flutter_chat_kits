import '../core/room_manager_base.dart' show RoomManagerBase;
import '../delegates/settings.dart' show ChatSilentNotification;
import '../models/profile.dart' show Profile;
import '../models/room.dart' show Room, RoomExtra, RoomKeys;
import '../utils/chat_helper.dart' show ChatHelper;
import '../utils/field_value.dart' show ChatValueTimestamp;

mixin RoomCrudMixin on RoomManagerBase {
  Future<Room> generateOrGetThread(
    Profile profile,
    List<String> participants, {
    RoomExtra? extra,
  }) async {
    try {
      if (!canOperate) return Room.empty();

      final friend = extractFriend(participants);
      if (friend == null) return Room.empty();

      final sorted = sortedParticipants(participants);
      if (sorted.length < 2) return Room.empty();

      final id = ChatHelper.generateThreadId(me, friend);
      final existing = await _getOrFetch(id);

      mappedProfiles[profile.id] = profile;

      if (!existing.isEmpty) return existing;

      return Room(
        isLocal: true,
        id: id,
        createdBy: me,
        participants: sorted.toSet(),
        extra: extra ?? {},
      );
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'RoomCrudMixin.generateOrGetThread',
        context: {'profileId': profile.id},
      );
      return Room.empty();
    }
  }

  Future<Room> createOrGetRoom(
    Room room, {
    ChatSilentNotification notification = const ChatSilentNotification(),
  }) async {
    try {
      if (!canOperate) return Room.empty();

      final existing = await _getOrFetch(room.id);
      if (!existing.isEmpty) {
        ensureMetadataForRoom(existing);
        return existing;
      }

      final sorted = sortedParticipants([...room.participants]);
      if (sorted.length < 2) return Room.empty();

      final source = {...room.source, RoomKeys.i.participants: sorted};
      await roomDelegate.create(room.id, n.normalize(source, n.room));

      final created = room.copyWith(isLocal: false);
      _cacheAndNotify(
        created,
        notification: notification,
        defaultTitle: profileFor(me).name ?? 'Match!',
        defaultBody: 'New matched',
      );

      return created;
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'RoomCrudMixin.createOrGetRoom',
        context: {'roomId': room.id},
      );
      return Room.empty();
    }
  }

  Future<Room> createOrGetThread(
    List<String> participants, {
    RoomExtra? extra,
    ChatSilentNotification notification = const ChatSilentNotification(),
  }) async {
    try {
      if (!canOperate) return Room.empty();

      final friend = extractFriend(participants);
      if (friend == null) return Room.empty();

      final sorted = sortedParticipants(participants);
      if (sorted.length < 2) return Room.empty();

      final id = ChatHelper.generateThreadId(me, friend);
      final existing = await _getOrFetch(id);
      if (!existing.isEmpty) {
        ensureMetadataForRoom(existing);
        return existing;
      }

      await roomDelegate.create(
        id,
        n.normalize({
          RoomKeys.i.isGroup: false,
          RoomKeys.i.id: id,
          RoomKeys.i.isVerified: false,
          RoomKeys.i.createdAt: ChatValueTimestamp(),
          RoomKeys.i.updatedAt: ChatValueTimestamp(),
          RoomKeys.i.createdBy: me,
          RoomKeys.i.participants: sorted,
          if (extra != null && extra.isNotEmpty) RoomKeys.i.extra: extra,
        }, n.room),
      );

      final created = await roomDelegate.get(id);
      if (created.isEmpty) return created;

      _cacheAndNotify(
        created,
        notification: notification,
        defaultTitle: profileFor(me).name ?? 'Created!',
        defaultBody: 'Newly room created',
      );

      return created;
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'RoomCrudMixin.createOrGetThread',
        context: {'participants': participants},
      );
      return Room.empty();
    }
  }

  Future<Room> createOrGetGroup(
    String name, {
    String? id,
    List<String>? participants,
    RoomExtra? extra,
    ChatSilentNotification notification = const ChatSilentNotification(),
  }) async {
    try {
      if (!canOperate) return Room.empty();

      final sorted = sortedParticipants(participants ?? []);
      final groupId = id ?? ChatHelper.generateGroupId();

      final existing = await _getOrFetch(groupId);
      if (!existing.isEmpty && existing.isGroup) {
        ensureMetadataForRoom(existing);
        return existing;
      }

      await roomDelegate.create(
        groupId,
        n.normalize({
          RoomKeys.i.isGroup: true,
          RoomKeys.i.id: groupId,
          RoomKeys.i.createdAt: ChatValueTimestamp(),
          RoomKeys.i.updatedAt: ChatValueTimestamp(),
          RoomKeys.i.createdBy: me,
          RoomKeys.i.participants: sorted,
          if (extra != null && extra.isNotEmpty) RoomKeys.i.extra: extra,
        }, n.room),
      );

      final created = await roomDelegate.get(groupId);
      if (created.isEmpty) return created;

      _cacheAndNotify(
        created,
        notification: notification,
        defaultTitle: name,
        defaultBody: 'Newly group created',
      );

      return created;
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'RoomCrudMixin.createOrGetGroup',
        context: {'name': name, 'id': id},
      );
      return Room.empty();
    }
  }

  Future<void> delete(String roomId) async {
    final target = room(roomId);

    try {
      await roomDelegate.delete(roomId);
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'RoomCrudMixin.delete',
        context: {'roomId': roomId, 'phase': 'roomDelegate.delete'},
      );
      return;
    }

    pop(target.id);
    notifyManagerRoomDeleted(roomId);
    reconcileMetadata(buildActiveParticipants());

    try {
      final messages = await messageDelegate.fetch(roomId);
      final urls = messages.expand((m) => m.findPathOrUrls(true)).toList();
      await messageDelegate.deleteAll(roomId);
      await Future.wait(
        urls.map((url) async {
          try {
            await messageDelegate.deleteFromStorage(url);
          } catch (e, st) {
            errorReporter.report(
              e,
              stackTrace: st,
              source: 'RoomCrudMixin.delete.storage',
              context: {'roomId': roomId, 'url': url},
            );
          }
        }),
      );
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'RoomCrudMixin.delete',
        context: {'roomId': roomId, 'phase': 'cleanup'},
      );
    }
  }

  Future<Room> _getOrFetch(String id) async {
    return mappedRooms[id] ?? await roomDelegate.get(id);
  }

  Future<void> _cacheAndNotify(
    Room created, {
    required ChatSilentNotification notification,
    required String defaultTitle,
    required String defaultBody,
  }) async {
    put(created);
    ensureMetadataForRoom(created);
    await pushNotification(
      roomId: created.id,
      msgId: me,
      notification: notification.copyWith(
        title: notification.title ?? defaultTitle,
        body: notification.body ?? defaultBody,
      ),
    );
  }
}
