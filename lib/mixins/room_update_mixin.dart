import '../core/room_manager_base.dart';
import '../models/profile.dart';
import '../models/room.dart';
import '../utils/field_value.dart';

mixin RoomUpdateMixin on RoomManagerBase {
  @override
  Future<bool> update(String roomId, Map<String, dynamic> value) async {
    if (me.isEmpty || value.isEmpty) return false;
    try {
      await roomDelegate.update(roomId, n.normalize(value, n.room));
      return true;
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'RoomUpdateMixin.update',
        context: {'roomId': roomId},
      );
      return false;
    }
  }

  Future<bool> updateExtra(String roomId, Map<String, dynamic> extra) async {
    if (me.isEmpty || extra.isEmpty) return false;
    try {
      await roomDelegate.update(roomId, {
        RoomKeys.i.extra: n.normalize(extra, n.room),
      });
      return true;
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'RoomUpdateMixin.updateExtra',
        context: {'roomId': roomId},
      );
      return false;
    }
  }

  Future<bool> updateProfile(String uid, Map<String, dynamic> value) async {
    if (me.isEmpty || value.isEmpty) return false;
    try {
      await profileDelegate.update(uid, n.normalize(value, n.profile));
      return true;
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'RoomUpdateMixin.updateProfile',
        context: {'uid': uid},
      );
      return false;
    }
  }

  Future<bool> updateProfileExtra(
    String uid,
    Map<String, dynamic> extra,
  ) async {
    if (me.isEmpty || extra.isEmpty) return false;
    try {
      await profileDelegate.update(uid, {
        UserProfileKeys.i.extra: n.normalize(extra, n.profile),
      });
      return true;
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'RoomUpdateMixin.updateProfileExtra',
        context: {'uid': uid},
      );
      return false;
    }
  }

  Future<bool> verified(String roomId, [bool value = true]) async {
    if (me.isEmpty) return false;
    try {
      await roomDelegate.update(
        roomId,
        n.normalize({
          RoomKeys.i.isVerified: value ? true : ChatValueDelete(),
        }, n.room),
      );
      return true;
    } catch (e, st) {
      errorReporter.report(
        e,
        stackTrace: st,
        source: 'RoomUpdateMixin.verified',
        context: {'roomId': roomId, 'value': value},
      );
      return false;
    }
  }
}
