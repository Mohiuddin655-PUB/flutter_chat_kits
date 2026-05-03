import 'package:flutter/foundation.dart' show ValueNotifier, protected;

import '../delegates/ai.dart' show ChatAiDelegate;
import '../delegates/cache.dart' show ChatCacheDelegate;
import '../delegates/error_reporter.dart' show ChatErrorReporter;
import '../delegates/message.dart' show ChatMessageDelegate;
import '../delegates/normalizer.dart' show ChatFieldValueNormalizer;
import '../delegates/notification.dart' show ChatNotificationDelegate;
import '../delegates/profile.dart' show ChatProfileDelegate;
import '../delegates/room.dart' show ChatRoomDelegate;
import '../delegates/settings.dart'
    show ChatUserSettingsDelegate, ChatNotification, ChatSilentNotification;
import '../delegates/status.dart' show ChatStatusDelegate;
import '../delegates/typing.dart' show ChatTypingDelegate;
import '../models/message.dart' show Message;
import '../models/profile.dart' show Profile, BotProfile, UserProfile;
import '../models/room.dart' show Room, DirectRoom, GroupRoom;
import '../models/status.dart' show Status;
import '../models/typing.dart' show Typing;
import '../utils/field_value.dart' show ChatValueTimestamp;
import '../utils/model_configs.dart' show ChatModelConfigs;
import 'base.dart' show BaseNotifier;
import 'chat_manager.dart' show ChatManager;

// ─────────────────────────────────────────────────────────────────────────────
// Shared Typedefs
// ─────────────────────────────────────────────────────────────────────────────

typedef OnChatPageOpeningCallback<T extends Object?> = Future<T?> Function(
    ChatManager manager);

typedef VerifyToSendMessage = bool Function(Room room);

typedef OnDeniedToSendMessage = void Function(Room room);

// ─────────────────────────────────────────────────────────────────────────────
// RoomManagerBase
// ─────────────────────────────────────────────────────────────────────────────

abstract class RoomManagerBase extends BaseNotifier {
  RoomManagerBase({
    required super.pausedDurationWhenAppBackground,
    required super.connection,
    required super.connectivity,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared State
  // ═══════════════════════════════════════════════════════════════════════════

  bool loading = true;
  bool error = false;

  Map<String, Room> mappedRooms = {};
  Map<String, Status> mappedStatuses = {};
  Map<String, Typing> mappedTypings = {};
  Map<String, Profile> mappedProfiles = {};
  Set<String> activeParticipants = {};
  final Map<String, ValueNotifier<Room>> _roomNotifiers = {};

  // ═══════════════════════════════════════════════════════════════════════════
  // Abstract Dependency Getters
  // ═══════════════════════════════════════════════════════════════════════════

  @protected
  ChatFieldValueNormalizer get n;

  @protected
  ChatAiDelegate get aiDelegate;

  @protected
  ChatCacheDelegate get cacheDelegate;

  @protected
  ChatRoomDelegate get roomDelegate;

  @protected
  ChatMessageDelegate get messageDelegate;

  @protected
  ChatStatusDelegate get statusDelegate;

  @protected
  ChatTypingDelegate get typingDelegate;

  @protected
  ChatProfileDelegate get profileDelegate;

  @protected
  ChatNotificationDelegate get notificationDelegate;

  @protected
  ChatUserSettingsDelegate get settingsDelegate;

  ChatErrorReporter get errorReporter;

  bool get fetchGroupUserProfiles;

  bool get botEnabled;

  bool get syncTokenEnabled;

  ChatModelConfigs get modelConfigs;

  int get preloadInboxMetadataCount;

  int get maxCachedManagers;

  // ═══════════════════════════════════════════════════════════════════════════
  // Cross-Mixin Interface
  // ═══════════════════════════════════════════════════════════════════════════

  // ── SubscriptionMixin ─────────────────────────────────────────────────────

  @protected
  void startListening();

  @protected
  void startMeProfileListener();

  @protected
  void disposeSubscriptions();

  @protected
  void ensureMetadataForRoom(Room room);

  @protected
  void ensureMetadataListener(String uid);

  @protected
  void cancelMetadataIfOrphaned(String uid);

  @protected
  void cleanupOrphanedParticipants(Room room);

  @protected
  void reconcileMetadata(Set<String> newActives);

  @protected
  Set<String> buildActiveParticipants();

  // ── ManagerLifecycleMixin ─────────────────────────────────────────────────

  @protected
  void disposeAllManagers();

  @protected
  void notifyManagerRoomDeleted(String roomId);

  @protected
  ChatManager managerForRoom(Room room);

  @protected
  bool isRoomActive(String roomId);

  @protected
  bool isRoomManaged(String roomId);

  // ── RoomUpdateMixin ──────────────────────────────────────────────────────────

  @protected
  Future<bool> update(String roomId, Map<String, dynamic> value);

  // ── MessageMixin ──────────────────────────────────────────────────────────

  @protected
  Future<void> markDeliveredForRoom(String roomId);

  Future<bool> updateMessage(
    String roomId,
    String msgId,
    Map<String, dynamic> value, {
    Map<String, dynamic> roomValues = const {},
  });

  @protected
  Future<void> createMessageByBot(Message msg);

  // ── NotificationMixin ─────────────────────────────────────────────────────

  Future<void> pushNotification({
    required String roomId,
    required String msgId,
    required ChatNotification notification,
  });

  Future<void> sendNotification(
    Message msg,
    ChatSilentNotification notification,
  );

  // ── BotResponseMixin ──────────────────────────────────────────────────────

  Future<void> handleBotReply(String roomId, List<Message> messages);

  // ═══════════════════════════════════════════════════════════════════════════
  // Public Accessors
  // ═══════════════════════════════════════════════════════════════════════════

  List<Room> get rooms => mappedRooms.values
      .where((r) => !r.isRemovedByMe && r.isVerified)
      .toList();

  Room room(String? roomId) {
    if (roomId == null || roomId.isEmpty) return const Room.empty();
    return mappedRooms[roomId] ?? const Room.empty();
  }

  ValueNotifier<Room> roomNotifier(String roomId) {
    return _roomNotifiers.putIfAbsent(
      roomId,
      () => ValueNotifier(room(roomId)),
    );
  }

  bool isRoomCreated(String roomId) => mappedRooms.containsKey(roomId);

  // ── Typing ────────────────────────────────────────────────────────────────

  bool isTyping(Room? room) {
    if (room is DirectRoom) return _typingMatchesRoom(room.friendId, room.id);
    if (room is GroupRoom) {
      return room.participants.any((uid) => _typingMatchesRoom(uid, room.id));
    }
    return false;
  }

  Typing typingFor(String? uid) {
    if (uid == null || uid.isEmpty) return Typing.empty();
    return mappedTypings[uid] ?? Typing.empty();
  }

  List<Typing> typingsFromRoom(Room? room) {
    if (room is DirectRoom) {
      final t = typingFor(room.friendId);
      return (t.roomId == room.id) ? [t] : [];
    }
    if (room is GroupRoom) {
      return room.participants
          .map(typingFor)
          .where((t) => !t.isEmpty && t.roomId == room.id)
          .toList();
    }
    return [];
  }

  // ── Status ────────────────────────────────────────────────────────────────

  Status statusFor(String? uid) {
    if (uid == null || uid.isEmpty) return Status.empty();
    return mappedStatuses[uid] ?? Status.empty();
  }

  Status statusFromRoom(Room? room) {
    if (room is DirectRoom) return statusFor(room.friendId);
    return Status.empty();
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Profile profileFor(String? uid) {
    if (uid == null || uid.isEmpty) return const Profile.empty();
    final cached = mappedProfiles[uid];
    if (cached != null && !cached.isEmpty) return cached;
    if (activeParticipants.contains(uid) || isParticipantInAnyRoom(uid)) {
      ensureMetadataListener(uid);
    }
    return cached ?? Profile.empty();
  }

  BotProfile profileForBot(String? uid) {
    final profile = profileFor(uid);
    if (profile is BotProfile) return profile;
    return const BotProfile.empty();
  }

  UserProfile profileForUser(String? uid) {
    final profile = profileFor(uid);
    if (profile is UserProfile) return profile;
    return const UserProfile.empty();
  }

  Profile profileFromRoom(Room? room) {
    if (room is DirectRoom) return profileFor(room.friendId);
    if (room is GroupRoom) {
      return Profile(id: room.id, name: room.name, photo: room.photo);
    }
    return Profile.empty();
  }

  BotProfile botProfileFromRoom(Room? room) {
    final profile = profileFromRoom(room);
    if (profile is BotProfile) return profile;
    return const BotProfile.empty();
  }

  UserProfile userProfileFromRoom(Room? room) {
    final profile = profileFromRoom(room);
    if (profile is UserProfile) return profile;
    return const UserProfile.empty();
  }

  void cacheProfile(Profile profile) {
    if (profile.id.isEmpty) return;
    mappedProfiles[profile.id] = profile;
    notify();
  }

  // ── Local State Helpers ───────────────────────────────────────────────────

  void pop(String roomId) {
    mappedRooms.remove(roomId);
    notifyListeners();
  }

  void put(Room room) {
    if (room.isEmpty) return;
    mappedRooms[room.id] = room;
    notifyListeners();
  }

  ChatValueTimestamp timestamp(Object? raw) => n.timestamp(raw);

  // ── Manager accessor ───────────────────────────

  ChatManager? managerOrNull(String roomId);

  // ═══════════════════════════════════════════════════════════════════════════
  // Protected Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  @protected
  bool get canOperate => isConnected && isActive && !isPaused && me.isNotEmpty;

  @protected
  bool isParticipantInAnyRoom(String uid) {
    return mappedRooms.values.any((r) {
      if (r is DirectRoom) return r.friendId == uid;
      return r.participants.contains(uid);
    });
  }

  @protected
  Set<String> participantsOf(Room room) {
    if (room is DirectRoom) return {room.friendId};
    return {...room.participants}..remove(me);
  }

  @protected
  List<String> sortedParticipants(List<String> participants) =>
      ({...participants, me}.toList()..sort());

  @protected
  String? extractFriend(List<String> participants) {
    final others = {...participants}..remove(me);
    return others.firstOrNull;
  }

  @protected
  void updateRoomNotifier(String roomId) {
    final notifier = _roomNotifiers[roomId];
    if (notifier == null) return;
    final current = room(roomId);
    if (notifier.value != current) notifier.value = current;
  }

  @protected
  void updateAllRoomNotifiers() {
    for (final id in _roomNotifiers.keys) {
      updateRoomNotifier(id);
    }
  }

  @protected
  void disposeRoomNotifier(String roomId) {
    _roomNotifiers.remove(roomId)?.dispose();
  }

  @protected
  void disposeAllRoomNotifiers() {
    for (final notifier in _roomNotifiers.values) {
      notifier.dispose();
    }
    _roomNotifiers.clear();
  }

  @protected
  void updateNotifiersForParticipant(String uid) {
    for (final entry in _roomNotifiers.entries) {
      final room = mappedRooms[entry.key];
      if (room == null) continue;
      final isParticipant = room is DirectRoom
          ? room.friendId == uid
          : room.participants.contains(uid);
      if (isParticipant) updateRoomNotifier(entry.key);
    }
  }

  // ── Private ───────────────────────────────────────────────────────────────

  bool _typingMatchesRoom(String uid, String roomId) {
    final t = typingFor(uid);
    return !t.isEmpty && t.roomId == roomId;
  }
}
