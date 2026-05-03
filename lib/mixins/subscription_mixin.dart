import 'dart:async' show StreamSubscription, Timer;

import '../core/room_manager_base.dart' show RoomManagerBase;
import '../models/message.dart' show MessageStatus;
import '../models/room.dart' show Room, DirectRoom, GroupRoom;

mixin SubscriptionMixin on RoomManagerBase {
  StreamSubscription? _roomSubscription;

  final Map<String, StreamSubscription> _profileSubs = {};
  final Map<String, StreamSubscription> _statusSubs = {};
  final Map<String, StreamSubscription> _typingSubs = {};

  final Set<String> _visibleRoomIds = {};
  final Map<String, Timer> _invisibilityTimers = {};

  Duration get invisibilityGracePeriod => const Duration(seconds: 8);

  // ═══════════════════════════════════════════════════════════════════════════
  // Visibility API
  // ═══════════════════════════════════════════════════════════════════════════

  void visible(Room room) {
    if (room.isEmpty) return;
    final id = room.id;

    _invisibilityTimers.remove(id)?.cancel();

    if (_visibleRoomIds.add(id)) {
      reconcileMetadata(buildActiveParticipants());
    }
  }

  void invisible(Room room) {
    if (room.isEmpty) return;
    final id = room.id;

    if (!_visibleRoomIds.contains(id)) return;

    _invisibilityTimers.remove(id)?.cancel();

    _invisibilityTimers[id] = Timer(invisibilityGracePeriod, () {
      _invisibilityTimers.remove(id);
      if (_visibleRoomIds.remove(id)) {
        reconcileMetadata(buildActiveParticipants());
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RoomManagerBase contract
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void startListening() {
    _roomSubscription?.cancel();
    if (!isConnected || me.isEmpty) return;

    _roomSubscription = roomDelegate.stream(me).listen(
      (rooms) {
        loading = false;

        if (rooms.isEmpty) {
          // Guard against transient empty emissions — only treat as
          // full deletion if we previously had rooms AND we're online.
          // Otherwise it's likely a network blip or first-load empty
          // state and wiping cache would cause UI flicker.
          if (mappedRooms.isEmpty || !isConnected) {
            notify();
            return;
          }
          _handleAllRoomsRemoved();
          return;
        }

        final previousRooms = mappedRooms;
        final incoming = {for (final r in rooms) r.id: r};
        _notifyDeletedRooms(incoming);

        _triggerBackgroundDelivery(rooms);

        mappedRooms = incoming;
        reconcileMetadata(buildActiveParticipants());
        _updateChangedRoomNotifiers(previousRooms);
        notify();
      },
      onError: (error, stackTrace) {
        loading = false;
        error = true;
        errorReporter.report(
          error,
          stackTrace: stackTrace is StackTrace ? stackTrace : null,
          source: 'SubscriptionMixin.startListening',
        );
        notify();
      },
    );
  }

  @override
  void startMeProfileListener() {
    final uid = me;
    if (uid.isEmpty || !isConnected) return;
    if (_profileSubs.containsKey(uid)) return;

    _profileSubs[uid] = profileDelegate.stream(uid).listen((profile) {
      mappedProfiles[uid] = profile;
      notify();
    });
  }

  @override
  void disposeSubscriptions() {
    _roomSubscription?.cancel();
    _roomSubscription = null;
    _clearVisibilityState();
    _cancelAllMetadata();
    disposeAllRoomNotifiers();
  }

  @override
  void ensureMetadataForRoom(Room room) {
    for (final uid in participantsOf(room)) {
      if (uid != me) ensureMetadataListener(uid);
    }
  }

  @override
  void ensureMetadataListener(String uid) {
    if (uid.isEmpty || uid == me || !isActive || !isConnected) return;

    if (!_profileSubs.containsKey(uid)) {
      _profileSubs[uid] = profileDelegate.stream(uid).listen((v) {
        mappedProfiles[uid] = v;
        updateNotifiersForParticipant(uid);
        notify();
      });
    }

    if (!_statusSubs.containsKey(uid)) {
      _statusSubs[uid] = statusDelegate.stream(uid).listen((v) {
        mappedStatuses[uid] = v;
        updateNotifiersForParticipant(uid);
        notify();
      });
    }

    if (!_typingSubs.containsKey(uid)) {
      _typingSubs[uid] = typingDelegate.stream(uid).listen((v) {
        mappedTypings[uid] = v;
        updateNotifiersForParticipant(uid);
        notify();
      });
    }
  }

  @override
  void cancelMetadataIfOrphaned(String uid) {
    if (uid.isEmpty || uid == me || isParticipantInAnyRoom(uid)) return;
    _cancelMetadataFor(uid);
  }

  @override
  void cleanupOrphanedParticipants(Room room) {
    for (final uid in participantsOf(room)) {
      if (uid != me) cancelMetadataIfOrphaned(uid);
    }
  }

  @override
  void reconcileMetadata(Set<String> newActives) {
    if (me.isEmpty) return;

    final removed = activeParticipants.difference(newActives);
    for (final uid in removed) {
      cancelMetadataIfOrphaned(uid);
    }
    for (final uid in newActives) {
      ensureMetadataListener(uid);
    }
    activeParticipants = newActives;
  }

  @override
  Set<String> buildActiveParticipants() {
    final result = <String>{};
    final preloadIds = _topRoomsByActivity(preloadInboxMetadataCount);

    for (final r in mappedRooms.values) {
      final isVisible = _visibleRoomIds.contains(r.id);
      final isActive = isRoomActive(r.id);
      final isPreloaded = preloadIds.contains(r.id);
      if (!isVisible && !isActive && !isPreloaded) continue;

      if (r is DirectRoom) {
        result.add(r.friendId);
      } else if (r is GroupRoom && fetchGroupUserProfiles) {
        result.addAll(r.participants);
      }
    }
    return result..remove(me);
  }

  Set<String> _topRoomsByActivity(int count) {
    if (count <= 0 || mappedRooms.isEmpty) return const {};

    final filtered = mappedRooms.values
        .where((r) => !r.isRemovedByMe && r.isVerified)
        .toList();

    if (filtered.length <= count) {
      return filtered.map((r) => r.id).toSet();
    }

    filtered.sort((a, b) {
      if (a.updatedAt.isEmpty && b.updatedAt.isEmpty) return 0;
      if (a.updatedAt.isEmpty) return 1;
      if (b.updatedAt.isEmpty) return -1;
      return b.updatedAt.timestamp.compareTo(a.updatedAt.timestamp);
    });

    return filtered.take(count).map((r) => r.id).toSet();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Private Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Update notifiers only for rooms whose data actually changed —
  /// avoids O(N) full updates on every room snapshot when only one
  /// room's last message updated.
  void _updateChangedRoomNotifiers(Map<String, Room> previousRooms) {
    for (final id in mappedRooms.keys) {
      final oldRoom = previousRooms[id];
      final newRoom = mappedRooms[id];
      if (oldRoom != newRoom) {
        updateRoomNotifier(id);
      }
    }
  }

  void _triggerBackgroundDelivery(List<Room> rooms) {
    for (final room in rooms) {
      if (room.lastMessageSenderId.isEmpty) continue;
      if (room.lastMessageSenderId == me) continue;
      if (room.unseenCount == 0) continue;
      final myStatus = room.lastMessageStatuses[me];
      if (myStatus == MessageStatus.delivered ||
          myStatus == MessageStatus.seen) {
        continue;
      }
      if (isRoomActive(room.id)) continue;
      markDeliveredForRoom(room.id);
    }
  }

  void _handleAllRoomsRemoved() {
    final previousIds = mappedRooms.keys.toSet();
    mappedRooms = {};
    for (final id in previousIds) {
      notifyManagerRoomDeleted(id);
      disposeRoomNotifier(id);
    }
    _clearVisibilityState();
    reconcileMetadata({});
    notify();
  }

  void _notifyDeletedRooms(Map<String, Room> incoming) {
    for (final id in mappedRooms.keys) {
      if (!incoming.containsKey(id)) {
        notifyManagerRoomDeleted(id);
        disposeRoomNotifier(id);
        _visibleRoomIds.remove(id);
        _invisibilityTimers.remove(id)?.cancel();
      }
    }
  }

  void _clearVisibilityState() {
    for (final timer in _invisibilityTimers.values) {
      timer.cancel();
    }
    _invisibilityTimers.clear();
    _visibleRoomIds.clear();
  }

  void _cancelMetadataFor(String uid) {
    _profileSubs.remove(uid)?.cancel();
    _statusSubs.remove(uid)?.cancel();
    _typingSubs.remove(uid)?.cancel();
    mappedProfiles.remove(uid);
    mappedStatuses.remove(uid);
    mappedTypings.remove(uid);
  }

  void _cancelAllMetadata() {
    final uids = {
      ..._profileSubs.keys,
      ..._statusSubs.keys,
      ..._typingSubs.keys,
    };
    for (final uid in uids) {
      _cancelMetadataFor(uid);
    }
  }
}
