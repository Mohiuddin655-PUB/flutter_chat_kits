import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../delegates/message.dart';
import '../delegates/normalizer.dart';
import '../delegates/notification.dart';
import '../delegates/profile.dart';
import '../delegates/room.dart';
import '../delegates/status.dart';
import '../delegates/typing.dart';
import '../models/message.dart';
import '../models/profile.dart';
import '../models/room.dart';
import '../models/status.dart';
import '../models/typing.dart';
import '../utils/chat_helper.dart';
import '../utils/chat_ui.dart';
import '../utils/field_value.dart';
import 'base.dart';
import 'chat.dart';

class RoomManager extends BaseNotifier {
  final bool fetchGroupUserProfiles;
  final ChatFieldValueNormalizer _n;
  final ChatRoomDelegate _room;
  final ChatMessageDelegate _message;
  final ChatStatusDelegate _status;
  final ChatTypingDelegate _typing;
  final ChatProfileDelegate _profile;
  final ChatNotificationDelegate _notification;
  final ChatUiConfigs uiConfigs;

  RoomManager._(
    super.pausedDurationWhenAppBackground,
    super.connectivity,
    this.fetchGroupUserProfiles,
    this._room,
    this._message,
    this._status,
    this._typing,
    this._profile,
    this._notification,
    this._n,
    this.uiConfigs,
  );

  static RoomManager? _i;

  static RoomManager get i => _i!;

  static void init({
    bool fetchGroupUserProfiles = false,
    Duration pausedDurationWhenAppBackground = const Duration(minutes: 2),
    required Stream<bool> connectivity,
    required ChatRoomDelegate room,
    required ChatMessageDelegate message,
    required ChatStatusDelegate status,
    required ChatTypingDelegate typing,
    required ChatProfileDelegate profile,
    required ChatNotificationDelegate notification,
    required ChatFieldValueNormalizer normalizer,
    required ChatUiConfigs uiConfigs,
  }) async {
    _i = RoomManager._(
      pausedDurationWhenAppBackground,
      connectivity,
      fetchGroupUserProfiles,
      room,
      message,
      status,
      typing,
      profile,
      notification,
      normalizer,
      uiConfigs,
    );
  }

  bool loading = true;
  bool error = false;

  Map<String, Room> mappedRooms = {};
  Map<String, Status> mappedStatuses = {};
  Map<String, Typing> mappedTypings = {};
  Map<String, Profile> mappedProfiles = {};

  Set<String> activeParticipants = {};

  List<Room> get rooms => [...mappedRooms.values];

  Room room(String? roomId) {
    if (roomId == null || roomId.isEmpty) return Room.empty();
    final room = mappedRooms[roomId];
    return room ?? Room.empty();
  }

  bool isRoomCreated(String roomId) {
    return mappedRooms.containsKey(roomId);
  }

  bool isTyping(Room? room) {
    if (room is DirectRoom) {
      final x = typingFor(room.friendId);
      return x.roomId == room.id;
    }
    if (room is GroupRoom) {
      final typings = room.participants.map(typingFor);
      final isTyping = typings.any((e) => !e.isEmpty && e.roomId == room.id);
      return isTyping;
    }
    return false;
  }

  Typing typingFor(String? uid) {
    if (uid == null || uid.isEmpty) return Typing.empty();
    final typing = mappedTypings[uid];
    return typing ?? Typing.empty();
  }

  List<Typing> typingsFromRoom(Room? room) {
    if (room is DirectRoom) {
      final x = typingFor(room.friendId);
      if (x.roomId == room.id) return [x];
      return [];
    } else if (room is GroupRoom) {
      final typings = room.participants.map(typingFor);
      final types = typings.where((e) => !e.isEmpty && e.roomId == room.id);
      if (types.isNotEmpty) return typings.toList();
      return [];
    }
    return [];
  }

  Status statusFor(String? uid) {
    if (uid == null || uid.isEmpty) return Status.empty();
    final status = mappedStatuses[uid];
    return status ?? Status.empty();
  }

  Status statusFromRoom(Room? room) {
    if (room is DirectRoom) {
      return statusFor(room.friendId);
    }
    return Status.empty();
  }

  Profile profileFor(String? uid) {
    if (uid == null || uid.isEmpty) return Profile.empty();
    final status = mappedProfiles[uid];
    return status ?? Profile.empty();
  }

  Profile profileFromRoom(Room? room) {
    if (room is DirectRoom) {
      return profileFor(room.friendId);
    }
    if (room is GroupRoom) {
      return Profile(
        id: room.id,
        name: room.name ?? "",
        photo: room.photo,
        platform: '',
        token: '',
      );
    }
    return Profile.empty();
  }

  // SUBSCRIPTIONS
  StreamSubscription? _roomSubscription;
  final Map<String, StreamSubscription> _statusSubs = {};
  final Map<String, StreamSubscription> _typingSubs = {};
  final Map<String, StreamSubscription> _profileSubs = {};
  final Map<String, ChatManager> _mappedManagers = {};

  void _listenMeProfile() {
    final uid = me;
    if (uid.isEmpty) {
      return;
    }
    if (!isActive) {
      return;
    }
    if (!isConnected) {
      return;
    }
    if (_profileSubs.containsKey(uid)) {
      return;
    }
    _profileSubs[uid] = _profile.stream(uid).listen((v) {
      mappedProfiles[uid] = v;
      notify();
    });
  }

  void _listenMetadata(String uid, Iterable<String> leaves) {
    if (uid.isEmpty) {
      return;
    }
    if (!isActive) {
      return;
    }
    if (!isConnected) {
      return;
    }
    void apply(String type) {
      if (type == 'profile') {
        if (_profileSubs.containsKey(uid)) {
          if (leaves.contains(uid)) {
            _profileSubs[uid]?.cancel();
          }
          return;
        }
        _profileSubs[uid] = _profile.stream(uid).listen((v) {
          mappedProfiles[uid] = v;
          notify();
        });
      } else if (type == 'status') {
        if (_statusSubs.containsKey(uid)) {
          if (leaves.contains(uid)) {
            _statusSubs[uid]?.cancel();
          }
          return;
        }
        _statusSubs[uid] = _status.stream(uid).listen((v) {
          mappedStatuses[uid] = v;
          notify();
        });
      } else if (type == 'typing') {
        if (_typingSubs.containsKey(uid)) {
          if (leaves.contains(uid)) {
            _typingSubs[uid]?.cancel();
          }
          return;
        }
        _typingSubs[uid] = _typing.stream(uid).listen((v) {
          mappedTypings[uid] = v;
          notify();
        });
      }
    }

    apply('profile');
    apply('status');
    apply('typing');
  }

  void _cancelMetadata(String uid) {
    _profileSubs[uid]?.cancel();
    _statusSubs[uid]?.cancel();
    _typingSubs[uid]?.cancel();
  }

  void _listenAllMetadata(Iterable<String> actives, Iterable<String> leaves) {
    if (me.isEmpty) return;
    if (actives.isEmpty) {
      _cancelAllMetadata();
      return;
    }
    for (final uid in actives) {
      _listenMetadata(uid, leaves);
    }
  }

  void _cancelAllMetadata() {
    if (_profileSubs.isNotEmpty) {
      for (final sub in _profileSubs.values) {
        sub.cancel();
      }
      _profileSubs.clear();
    }
    if (_statusSubs.isNotEmpty) {
      for (final sub in _statusSubs.values) {
        sub.cancel();
      }
      _statusSubs.clear();
    }
    if (_typingSubs.isNotEmpty) {
      for (final sub in _typingSubs.values) {
        sub.cancel();
      }
      _typingSubs.clear();
    }
  }

  void _listen() {
    _roomSubscription?.cancel();
    if (!isConnected) return;
    if (me.isEmpty) return;
    _roomSubscription = _room.stream(me).listen((event) {
      loading = false;
      if (event.isEmpty) {
        notify();
        return;
      }

      mappedRooms = Map.fromEntries(event.map((e) => MapEntry(e.id, e)));

      final actives = mappedRooms.values.map((e) {
        if (e is DirectRoom) return {e.friendId};
        if (e is GroupRoom && fetchGroupUserProfiles) {
          return e.participants;
        }
        return <String>{};
      }).reduce((a, b) => {...a, ...b});

      _listenAllMetadata(
        actives,
        activeParticipants.where((e) => !actives.contains(e)),
      );

      activeParticipants = actives;

      notify();
    });
  }

  void _dispose() {
    _roomSubscription?.cancel();
    _cancelAllMetadata();
    _disconnectAllManagers();
  }

  void _disconnectAllManagers() {
    if (_mappedManagers.isEmpty) return;
    for (var i in _mappedManagers.values) {
      i.dispose();
    }
    _mappedManagers.clear();
  }

  ChatManager _manager(Room room) {
    return _mappedManagers[room.id] ??= ChatManager(room);
  }

  ChatManager manager(String roomId) {
    return _mappedManagers[roomId] ??= ChatManager(room(roomId));
  }

  ChatManager? managerOrNull(String roomId) {
    return _mappedManagers[roomId];
  }

  Future<T?> connect<T extends Object?>(
    BuildContext context,
    Room room, {
    ValueChanged<String>? onError,
  }) async {
    try {
      final manager = _manager(room)..connect();
      if (room.isLocal) {
        if (room is DirectRoom) {
          _listenMetadata(room.friendId, {});
        } else if (room is GroupRoom) {
          for (var uid in room.participants) {
            _listenMetadata(uid, {});
          }
        }
      }
      final feedback = await uiConfigs.onChatStart(context, manager);
      manager.disconnect();
      final closedRoom = this.room(room.id);
      if (closedRoom.isLocal || closedRoom.isEmpty) {
        final actives = mappedRooms.values
            .map((e) => e.participants)
            .reduce((a, b) => {...a, ...b})
            .toList();
        if (room is DirectRoom) {
          if (!actives.contains(room.friendId)) {
            _cancelMetadata(room.friendId);
          }
        } else if (room is GroupRoom) {
          for (var uid in room.participants) {
            if (!actives.contains(uid)) {
              _cancelMetadata(uid);
            }
          }
        }
      }
      if (feedback is T) return feedback;
      return null;
    } catch (e) {
      onError?.call(e.toString());
      return null;
    }
  }

  void disconnect(String roomId) {
    _mappedManagers[roomId]?.dispose();
    _mappedManagers.remove(roomId);
  }

  @override
  void attach(String uid) {
    super.attach(uid);
    markAsOnline(true);
  }

  @override
  void detach() {
    markAsOnline(false);
    super.detach();
  }

  @override
  void run() {
    _listen();
    _listenMeProfile();
    resetToken();
  }

  @override
  void stop() {
    _dispose();
  }

  @override
  void paused() {
    _dispose();
  }

  @override
  void foreground() {
    _listen();
    markAsOnline(true);
  }

  @override
  void background() {
    markAsOnline(false);
  }

  ChatValueTimestamp timestamp(Object? raw) {
    return _n.timestamp(raw);
  }

  void pop(String roomId) {
    mappedRooms.remove(roomId);
    notifyListeners();
  }

  void put(Room room) {
    mappedRooms[room.id] = room;
    notifyListeners();
  }

  Future<Room> generateOrGetThread(
    Profile profile,
    List<String> participants, {
    RoomExtra? extra,
  }) async {
    try {
      if (!isConnected || !isActive || isPaused) return Room.empty();
      if (me.isEmpty) return Room.empty();
      final friend = ({...participants}..remove(me)).firstOrNull;
      if (friend == null || friend.isEmpty) return Room.empty();
      if (!participants.contains(me)) {
        participants.add(me);
      }
      participants.sort();
      if (participants.length < 2) return Room.empty();
      String id = ChatHelper.generateThreadId(me, friend);
      final old = mappedRooms[id] ?? await _room.get(id);
      if (!mappedProfiles.containsKey(profile.id)) {
        mappedProfiles[profile.id] = profile;
      }
      if (!old.isEmpty) {
        return old;
      }
      return Room(
        isLocal: true,
        id: id,
        createdBy: me,
        participants: participants.toSet(),
        extra: extra ?? {},
      );
    } catch (_) {
      return Room.empty();
    }
  }

  Future<Room> createOrGetRoom(Room room) async {
    try {
      if (!isConnected || !isActive || isPaused) return Room.empty();
      if (me.isEmpty) return Room.empty();
      final old = mappedRooms[room.id] ?? await _room.get(room.id);
      if (!old.isEmpty) {
        return old;
      }
      final participants = [...room.participants];
      if (!participants.contains(me)) {
        participants.add(me);
      }
      participants.sort();
      if (participants.length < 2) return Room.empty();
      final source = {...room.source};
      source[RoomKeys.participants] = participants;
      final creates = _n.normalize(source, _n.room);
      await _room.create(room.id, creates);
      resetToken();
      return room.copyWith(isLocal: false);
    } catch (_) {
      return Room.empty();
    }
  }

  Future<Room> createOrGetThread(
    List<String> participants, {
    RoomExtra? extra,
  }) async {
    try {
      if (!isConnected || !isActive || isPaused) return Room.empty();
      if (me.isEmpty) return Room.empty();
      final friend = ({...participants}..remove(me)).firstOrNull;
      if (friend == null || friend.isEmpty) return Room.empty();
      if (!participants.contains(me)) {
        participants.add(me);
      }
      participants.sort();
      if (participants.length < 2) return Room.empty();
      String id = ChatHelper.generateThreadId(me, friend);
      final old = mappedRooms[id] ?? await _room.get(id);
      if (!old.isEmpty) {
        return old;
      }
      final creates = _n.normalize({
        RoomKeys.isGroup: false,
        RoomKeys.id: id,
        RoomKeys.createdAt: ChatValueTimestamp(),
        RoomKeys.updatedAt: ChatValueTimestamp(),
        RoomKeys.createdBy: me,
        RoomKeys.participants: participants,
        if (extra != null && extra.isNotEmpty) RoomKeys.extra: extra,
      }, _n.room);
      await _room.create(id, creates);
      resetToken();
      return _room.get(id);
    } catch (_) {
      return Room.empty();
    }
  }

  Future<Room> createOrGetGroup(
    String name, {
    String? id,
    List<String>? participants,
    RoomExtra? extra,
  }) async {
    try {
      if (!isConnected || !isActive || !isPaused) return Room.empty();
      if (me.isEmpty) return Room.empty();
      participants ??= [];
      if (!participants.contains(me)) {
        participants.add(me);
      }
      participants.sort();
      id ??= ChatHelper.generateGroupId();
      final old = mappedRooms[id] ?? await _room.get(id);
      if (!old.isEmpty && old.isGroup) {
        return old;
      }
      final creates = _n.normalize({
        RoomKeys.isGroup: true,
        RoomKeys.id: id,
        RoomKeys.createdAt: ChatValueTimestamp(),
        RoomKeys.updatedAt: ChatValueTimestamp(),
        RoomKeys.createdBy: me,
        RoomKeys.participants: participants.toSet().toList(),
        if (extra != null && extra.isNotEmpty) RoomKeys.extra: extra,
      }, _n.room);
      await _room.create(id, creates);
      resetToken();
      return _room.get(id);
    } catch (_) {
      return Room.empty();
    }
  }

  Future<void> update(String roomId, Map<String, dynamic> value) async {
    if (me.isEmpty) return;
    try {
      await _room.update(roomId, _n.normalize(value, _n.room));
    } catch (_) {}
  }

  Future<void> updateExtra(String roomId, Map<String, dynamic> extra) async {
    if (me.isEmpty) return;
    try {
      await _room.update(roomId, {
        RoomKeys.extra: _n.normalize(extra, _n.room),
      });
    } catch (_) {}
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> value) async {
    if (me.isEmpty) return;
    try {
      await _profile.update(uid, _n.normalize(value, _n.profile));
    } catch (_) {}
  }

  Future<void> updateProfileExtra(
      String uid, Map<String, dynamic> extra) async {
    if (me.isEmpty) return;
    try {
      await _profile.update(uid, {
        RoomKeys.extra: _n.normalize(extra, _n.profile),
      });
    } catch (_) {}
  }

  Future<void> delete(String roomId) async {
    final room = this.room(roomId);
    try {
      pop(room.id);
      await _room.delete(roomId);
    } catch (_) {
      put(room);
    }
    try {
      await _message.deleteAll(roomId);
    } catch (_) {}
  }

  Future<void> sayHello(
    String friendId,
    Message Function(String roomId) message, {
    BuildContext? roomOpeningContext,
  }) async {
    try {
      final room = await createOrGetThread([friendId]);
      if (room.isEmpty) return;
      final manager = _manager(room)..send(message(room.id));
      if (roomOpeningContext != null && roomOpeningContext.mounted) {
        manager.connect();
        await uiConfigs.onChatStart(roomOpeningContext, manager);
        manager.disconnect();
      }
    } catch (_) {}
  }

  /// --------------------------------------------------------------------------
  /// PROFILE CALLBACKS
  /// --------------------------------------------------------------------------

  Future<void> markAsActive(String? roomId) async {
    if (me.isEmpty) return;
    final normalized = _n.normalize({
      ProfileKeys.room: (roomId ?? '').isEmpty ? ChatValueDelete() : roomId,
    }, _n.profile);
    return _profile.update(me, normalized);
  }

  /// --------------------------------------------------------------------------
  /// STATUS CALLBACKS
  /// --------------------------------------------------------------------------

  Future<void> markAsOnline(bool status) async {
    if (me.isEmpty) return;
    try {
      final normalized = _n.normalize({
        StatusKeys.isOnline: status ? true : ChatValueDelete(),
        StatusKeys.lastSeen: ChatValueTimestamp(),
      }, _n.status);
      if (status) {
        await _status.online(me, normalized);
      } else {
        await _status.offline(me, normalized);
      }
    } catch (_) {}
  }

  /// --------------------------------------------------------------------------
  /// TYPING CALLBACKS
  /// --------------------------------------------------------------------------

  Future<void> markAsTyping(String roomId, bool status) async {
    if (me.isEmpty) return;
    try {
      if (status) {
        await _typing.start(roomId, me);
      } else {
        await _typing.end(me);
      }
    } catch (_) {}
  }

  /// --------------------------------------------------------------------------
  /// ROOM METADATA
  /// --------------------------------------------------------------------------

  Future<void> addParticipants(Room room, Iterable<String> participants) async {
    if (me.isEmpty) return;
    final filtered = participants.where((e) {
      return !room.participants.contains(e);
    }).toSet();
    if (filtered.isEmpty) return;
    put(room.copyWith(participants: filtered, isAddMember: true));
    try {
      final value = _n.normalize({
        RoomKeys.leaves: ChatValueRemove([...filtered]),
        RoomKeys.participants: ChatValueAdd([...filtered]),
      }, _n.room);
      await _room.update(room.id, value);
    } catch (_) {
      put(room);
    }
  }

  Future<void> removeParticipants(
    Room room,
    Iterable<String> participants,
  ) async {
    if (me.isEmpty) return;
    final filtered = participants.where(room.participants.contains).toSet();
    if (filtered.isEmpty) return;
    put(room.copyWith(participants: filtered, isAddMember: false));
    try {
      final value = _n.normalize({
        RoomKeys.leaves: ChatValueAdd([...filtered]),
        RoomKeys.participants: ChatValueRemove([...filtered]),
      }, _n.room);
      await _room.update(room.id, value);
    } catch (_) {
      put(room);
    }
  }

  Future<void> archive(Room room) async {
    if (me.isEmpty) return;
    if (room.isArchivedByMe) return;
    put(room.copyWith(isArchived: true));
    try {
      final value = _n.normalize({
        RoomKeys.archives: ChatValueAdd([me]),
      }, _n.room);
      await _room.update(room.id, value);
    } catch (_) {
      put(room);
    }
  }

  Future<void> unarchive(Room room) async {
    if (me.isEmpty) return;
    if (!room.isArchivedByMe) return;
    put(room.copyWith(isArchived: false));
    try {
      final value = _n.normalize({
        RoomKeys.archives: ChatValueRemove([me]),
      }, _n.room);
      await _room.update(room.id, value);
    } catch (_) {
      put(room);
    }
  }

  Future<void> block(Room room, Iterable<String> participants) async {
    if (me.isEmpty) return;
    put(room.copyWith(blocks: participants, isBlocked: true));
    try {
      final value = _n.normalize({
        RoomKeys.blocks: ChatValueAdd([...participants]),
      }, _n.room);
      await _room.update(room.id, value);
    } catch (_) {
      put(room);
    }
  }

  Future<void> unblock(Room room, Iterable<String> participants) async {
    if (me.isEmpty) return;
    put(room.copyWith(blocks: participants, isBlocked: false));
    try {
      final value = _n.normalize({
        RoomKeys.blocks: ChatValueRemove([...participants]),
      }, _n.room);
      await _room.update(room.id, value);
    } catch (_) {
      put(room);
    }
  }

  Future<void> join(Room room) async {
    if (me.isEmpty) return;
    put(room.copyWith(isLeaved: false));
    try {
      final value = _n.normalize({
        if (room.isAdminByMe) RoomKeys.isDeleted: ChatValueDelete(),
        RoomKeys.leaves: ChatValueRemove([me]),
        RoomKeys.participants: ChatValueAdd([me]),
      }, _n.room);
      await _room.update(room.id, value);
    } catch (_) {
      pop(room.id);
    }
  }

  Future<void> leave(Room room) async {
    if (me.isEmpty) return;
    if (room.isLeaveByMe) return;
    pop(room.id);
    try {
      final value = _n.normalize({
        if (room.isAdminByMe) RoomKeys.isDeleted: true,
        RoomKeys.leaves: ChatValueAdd([me]),
        RoomKeys.participants: ChatValueRemove([me]),
      }, _n.room);
      await _room.update(room.id, value);
    } catch (_) {
      put(room);
    }
  }

  Future<void> mute(Room room) async {
    if (me.isEmpty) return;
    if (room.isMutedByMe) return;
    put(room.copyWith(isMuted: true));
    try {
      final value = _n.normalize({
        RoomKeys.mutes: ChatValueAdd([me]),
      }, _n.room);
      await _room.update(room.id, value);
    } catch (_) {
      put(room);
    }
  }

  Future<void> unmute(Room room) async {
    if (me.isEmpty) return;
    if (!room.isPinnedByMe) return;
    put(room.copyWith(isMuted: false));
    try {
      final value = _n.normalize({
        RoomKeys.mutes: ChatValueRemove([me]),
      }, _n.room);
      await _room.update(room.id, value);
    } catch (_) {
      put(room);
    }
  }

  Future<void> remove(Room room) async {
    if (me.isEmpty) return;
    if (room.isRemovedByMe) return;
    pop(room.id);
    try {
      final value = _n.normalize({
        "${RoomKeys.removes}.$me": room.lastMessageId,
      }, _n.room);
      await _room.update(room.id, value);
    } catch (_) {
      put(room);
    }
  }

  Future<void> restrict(Room room, Iterable<String> participants) async {
    if (me.isEmpty) return;
    put(room.copyWith(restricts: participants, isRestricted: true));
    try {
      final value = _n.normalize({
        RoomKeys.restricts: ChatValueAdd([...participants]),
      }, _n.room);
      await _room.update(room.id, value);
    } catch (_) {
      put(room);
    }
  }

  Future<void> unrestrict(Room room, Iterable<String> participants) async {
    if (me.isEmpty) return;
    put(room.copyWith(restricts: participants, isRestricted: false));
    try {
      final value = _n.normalize({
        RoomKeys.restricts: ChatValueRemove([...participants]),
      }, _n.room);
      await _room.update(room.id, value);
    } catch (_) {
      put(room);
    }
  }

  Future<void> pin(Room room) async {
    if (me.isEmpty) return;
    if (room.isPinnedByMe) return;
    put(room.copyWith(isPinned: true));
    try {
      final value = _n.normalize({
        RoomKeys.pins: ChatValueAdd([me]),
      }, _n.room);
      await _room.update(room.id, value);
    } catch (_) {
      put(room);
    }
  }

  Future<void> unpin(Room room) async {
    if (me.isEmpty) return;
    if (!room.isPinnedByMe) return;
    put(room.copyWith(isPinned: false));
    try {
      final value = _n.normalize({
        RoomKeys.pins: ChatValueRemove([me]),
      }, _n.room);
      await _room.update(room.id, value);
    } catch (_) {
      put(room);
    }
  }

  Future<void> resetToken() async {
    if (me.isEmpty) return;
    String kPlatform = kIsWeb
        ? 'web'
        : Platform.isAndroid
            ? 'android'
            : Platform.isIOS
                ? 'ios'
                : Platform.isMacOS
                    ? 'macos'
                    : Platform.isFuchsia
                        ? 'fuchsia'
                        : Platform.isLinux
                            ? 'linux'
                            : Platform.isWindows
                                ? 'windows'
                                : 'unknown';
    final token = await _notification.deviceToken();
    return _profile.update(me, {
      ProfileKeys.platform: kPlatform,
      ProfileKeys.token: token,
    });
  }

  Future<void> resetUnseenCount(String roomId) async {
    if (me.isEmpty) return;
    try {
      final updates = _n.normalize({
        "${RoomKeys.unseenCount}.$me": ChatValueDelete(),
      }, _n.room);
      await _room.update(roomId, updates);
      notify();
    } catch (_) {}
  }

  Future<void> sendNotification(Message msg) async {
    if (me.isEmpty) return;
    try {
      final room = this.room(msg.roomId);
      final sender = profileFor(me);
      for (final participant in room.participants) {
        if (participant == me) continue;
        final isMuted = room.mutes.contains(participant);
        if (isMuted) continue;
        final receiver = profileFor(participant);
        if (receiver.isEmpty) continue;
        final isActiveRoom = receiver.isActiveRoom(msg.roomId);
        if (isActiveRoom) continue;
        final content = ChatNotificationContent(
          id: msg.id,
          roomId: msg.roomId,
          title: sender.name ?? "?",
          body: msg.notificationBody(sender.name ?? "?"),
          token: receiver.token,
          platform: receiver.platform,
        );
        _notification.send(content);
      }
    } catch (_) {}
  }

  Future<bool> forward(List<String> targetRoomIds, Message msg) async {
    if (me.isEmpty) return false;
    try {
      for (final id in targetRoomIds) {
        await createMessage(
          msg.copyWith(
            isForwarded: true,
            roomId: id,
            createdAt: ChatValueTimestamp(),
            updatedAt: ChatValueTimestamp(),
          ),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Stream<List<Message>> stream(String roomId) {
    if (me.isEmpty) return Stream.value([]);
    return _message.stream(roomId);
  }

  Future<Iterable<String>> _deletes(Iterable<String> urls) async {
    final futures = List.generate(urls.length, (index) async {
      final url = urls.elementAt(index);
      try {
        await _message.deleteFromStorage(url);
        return '';
      } catch (_) {
        return url;
      }
    });
    final failures = await Future.wait(futures).then((v) {
      return v.where((e) => e.isNotEmpty).toList();
    });
    return failures;
  }

  Future<List<String>> _uploads(
    String roomId,
    String msgId,
    MessageType type,
    List<String> paths,
  ) async {
    if (paths.isEmpty) return [];
    String? findExtension(String path) {
      final clean = path.split('?').first;
      final ext = clean.split('.').last.toLowerCase();

      const extensions = {
        '3gp',
        'aac',
        'avi',
        'bmp',
        'flac',
        'gif',
        'jpeg',
        'jpg',
        'm4a',
        'mkv',
        'mov',
        'mp3',
        'mp4',
        'ogg',
        'png',
        'webm',
        'webp',
        'wav',
      };
      if (extensions.contains(ext)) return ext;
      switch (type) {
        case MessageType.audio:
          return 'm4a';
        case MessageType.image:
          return 'jpg';
        case MessageType.video:
          return 'mp4';
        default:
          return null;
      }
    }

    String findPrefix(String? extension) {
      const Map<String, String> fileTypeMap = {
        'jpg': 'img',
        'jpeg': 'img',
        'png': 'img',
        'webp': 'img',
        'gif': 'img',
        'bmp': 'img',
        'mp3': 'aud',
        'm4a': 'aud',
        'aac': 'aud',
        'wav': 'aud',
        'ogg': 'aud',
        'flac': 'aud',
        'mp4': 'vid',
        'mov': 'vid',
        'avi': 'vid',
        'mkv': 'vid',
        'webm': 'vid',
        '3gp': 'vid',
      };

      final pre = fileTypeMap[extension];
      if (pre != null && pre.isNotEmpty) return pre;
      switch (type) {
        case MessageType.audio:
          return 'aud';
        case MessageType.image:
          return 'img';
        case MessageType.video:
          return 'vid';
        default:
          return 'txt';
      }
    }

    final futures = List.generate(paths.length, (index) async {
      try {
        final path = paths[index];
        final ext = findExtension(path);
        final pre = findPrefix(ext);
        final data = MessageUploadData(
          roomId: roomId,
          msgId: msgId,
          path: path,
          name: "${pre}_${index + 1}${ext != null ? ".$ext" : ''}",
        );
        return _message.upload(data);
      } catch (_) {
        return '';
      }
    });
    final urls = await Future.wait(futures).then((v) {
      return v.where((e) => e.isNotEmpty).toList();
    });
    return urls;
  }

  Future<Message> _replace(Message msg) async {
    List<String> findPaths() {
      switch (msg) {
        case AudioMessage():
          return [msg.url];
        case ImageMessage():
          return msg.urls;
        case VideoMessage():
          return [msg.url];
        default:
          return [];
      }
    }

    final paths = findPaths();
    if (paths.isEmpty) return msg;

    String thumbnail = '';
    List<String> urls = [];
    if (msg is AudioMessage || msg is ImageMessage || msg is VideoMessage) {
      urls = await _uploads(msg.roomId, msg.id, msg.type, paths);
      if (msg is VideoMessage) {
        thumbnail = await _uploads(msg.roomId, msg.id, msg.type, [
          msg.thumbnail,
        ]).then((v) => v.firstOrNull ?? '');
      }
    }
    switch (msg) {
      case AudioMessage():
        return msg.copyWith(url: urls.firstOrNull ?? '');
      case ImageMessage():
        return msg.copyWith(urls: urls);
      case VideoMessage():
        return msg.copyWith(thumbnail: thumbnail, url: urls.firstOrNull ?? '');
      default:
        return msg;
    }
  }

  Future<Message> createMessage(Message msg) async {
    if (me.isEmpty) return msg.copyWith(status: MessageStatus.failed);
    if (msg.isEmpty) return msg.copyWith(status: MessageStatus.failed);
    final body = msg.lastMessage();
    final room = this.room(msg.roomId);
    try {
      put(room.copyWith(
        lastMessage: body,
        lastMessageId: msg.id,
        lastMessageSenderId: me,
        lastMessageDeleted: false,
        updatedAt: ChatValueTimestamp.now(),
      ));
      final replacedMsg = await _replace(msg);
      if (replacedMsg.isEmpty) {
        put(room);
        return msg.copyWith(status: MessageStatus.failed);
      }
      final normalized = _n.normalize(
        replacedMsg.copyWith(status: MessageStatus.sent).source,
        _n.message,
      );
      await _message.create(msg.roomId, msg.id, normalized);
      final normalizedRoom = _n.normalize({
        RoomKeys.lastMessage: body,
        RoomKeys.lastMessageId: msg.id,
        RoomKeys.lastMessageSenderId: me,
        RoomKeys.lastMessageDeleted: false,
        RoomKeys.updatedAt: ChatValueTimestamp(),
        RoomKeys.lastMessageStatuses: {
          ...Map.fromEntries(
            room.participants.map((e) {
              return MapEntry(e, MessageStatus.sent.name);
            }),
          ),
        },
        RoomKeys.unseenCount: {
          ...Map.fromEntries(
            room.participants.map((e) {
              return MapEntry(e, ChatValueIncrement(1));
            }),
          ),
        },
      }, _n.room);
      await _room.update(msg.roomId, normalizedRoom);
      await sendNotification(msg);
      return replacedMsg.copyWith(status: MessageStatus.sent);
    } catch (_) {
      put(room);
      return msg.copyWith(status: MessageStatus.failed);
    }
  }

  Future<bool> deleteMessage(
    Message msg, {
    bool deleteBothAsSync = false,
    bool deleteMetaFromRoom = false,
  }) async {
    if (me.isEmpty) return false;
    try {
      await _message.delete(msg.roomId, msg.id);
      final urls = msg.findPathOrUrls(true);
      if (urls.isNotEmpty) {
        if (deleteBothAsSync) {
          await _deletes(urls);
        } else {
          _deletes(urls);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteMessages(
    Iterable<Message> messages, {
    bool deleteBothAsSync = false,
  }) async {
    if (me.isEmpty) return false;
    try {
      await _message.deletes(messages);
      List<String> urls = [];
      for (final i in messages) {
        urls.addAll(i.findPathOrUrls(true));
      }
      if (urls.isNotEmpty) {
        if (deleteBothAsSync) {
          await _deletes(urls);
        } else {
          _deletes(urls);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateMessage(
    String roomId,
    String msgId,
    Map<String, dynamic> value, {
    Map<String, dynamic> roomValues = const {},
  }) async {
    if (me.isEmpty) return false;
    try {
      final normalized = _n.normalize(value, _n.message);
      await _message.update(roomId, msgId, normalized);
      if (roomValues.isEmpty) {
        return true;
      }
      final normalizedRoom = _n.normalize(roomValues, _n.room);
      await RoomManager.i.update(roomId, normalizedRoom);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateMessageExtra(
    String roomId,
    String msgId,
    Map<String, dynamic> extra,
  ) async {
    if (me.isEmpty) return;
    try {
      await _message.update(roomId, msgId, {
        RoomKeys.extra: _n.normalize(extra, _n.message),
      });
    } catch (_) {}
  }

  Future<bool> updateMessages(
    String roomId,
    Map<String, Map<String, dynamic>> values,
  ) async {
    if (me.isEmpty) return false;
    try {
      final normalized = values.map((k, v) {
        return MapEntry(k, _n.normalize(v, _n.message));
      });
      await _message.updates(roomId, normalized);
      return true;
    } catch (_) {
      return false;
    }
  }

  void visible(Room room) {
    if (me.isEmpty) return;
  }

  void invisible(Room room) {
    if (me.isEmpty) return;
  }
}
