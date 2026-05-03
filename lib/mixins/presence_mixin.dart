import '../core/room_manager_base.dart';
import '../models/profile.dart';
import '../models/status.dart';
import '../utils/field_value.dart';

mixin PresenceMixin on RoomManagerBase {
  Future<void> markAsActive(String? roomId) async {
    if (me.isEmpty) return;
    try {
      final hasRoom = roomId != null && roomId.isNotEmpty;
      final value = n.normalize({
        UserProfileKeys.i.room: hasRoom ? roomId : ChatValueDelete(),
      }, n.profile);
      await profileDelegate.update(me, value);
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'PresenceMixin.markAsActive',
        context: {'roomId': roomId},
      );
    }
  }

  Future<void> markAsOnline(bool isOnline) async {
    if (me.isEmpty) return;
    try {
      final normalized = n.normalize({
        StatusKeys.i.isOnline: isOnline ? true : ChatValueDelete(),
        StatusKeys.i.lastSeen: ChatValueTimestamp(),
      }, n.status);
      if (isOnline) {
        await statusDelegate.online(me, normalized);
      } else {
        await statusDelegate.offline(me, normalized);
      }
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'PresenceMixin.markAsOnline',
        context: {'isOnline': isOnline},
      );
    }
  }

  Future<void> markAsTyping(String roomId, bool isTyping) async {
    if (me.isEmpty) return;
    try {
      if (isTyping) {
        await typingDelegate.start(roomId, me);
      } else {
        await typingDelegate.end(me);
      }
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'PresenceMixin.markAsTyping',
        context: {'roomId': roomId, 'isTyping': isTyping},
      );
    }
  }
}
