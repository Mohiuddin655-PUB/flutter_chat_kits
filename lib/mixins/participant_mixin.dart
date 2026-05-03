import '../core/room_manager_base.dart';
import '../models/room.dart';
import '../utils/field_value.dart';

mixin ParticipantMixin on RoomManagerBase {
  Future<void> addParticipants(Room room, Iterable<String> participants) async {
    if (me.isEmpty) return;

    final toAdd =
        participants.where((uid) => !room.participants.contains(uid)).toSet();
    if (toAdd.isEmpty) return;

    put(room.copyWith(participants: toAdd, isAddMember: true));

    try {
      await roomDelegate.update(
        room.id,
        n.normalize({
          RoomKeys.i.leaves: ChatValueRemove([...toAdd]),
          RoomKeys.i.participants: ChatValueAdd([...toAdd]),
        }, n.room),
      );
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'ParticipantMixin.addParticipants',
        context: {'roomId': room.id, 'participants': toAdd.toList()},
      );
      put(room);
      return;
    }

    for (final uid in toAdd) {
      if (uid != me) ensureMetadataListener(uid);
    }
  }

  Future<void> removeParticipants(
    Room room,
    Iterable<String> participants,
  ) async {
    if (me.isEmpty) return;

    final toRemove = participants.where(room.participants.contains).toSet();
    if (toRemove.isEmpty) return;

    put(room.copyWith(participants: toRemove, isAddMember: false));

    try {
      await roomDelegate.update(
        room.id,
        n.normalize({
          RoomKeys.i.leaves: ChatValueAdd([...toRemove]),
          RoomKeys.i.participants: ChatValueRemove([...toRemove]),
        }, n.room),
      );
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'ParticipantMixin.removeParticipants',
        context: {'roomId': room.id, 'participants': toRemove.toList()},
      );
      put(room);
      return;
    }

    for (final uid in toRemove) {
      cancelMetadataIfOrphaned(uid);
    }
  }
}
