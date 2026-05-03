import 'package:flutter/foundation.dart' show ValueChanged, debugPrint;

import '../core/chat_manager.dart' show ChatManager;
import '../core/room_manager_base.dart'
    show RoomManagerBase, OnChatPageOpeningCallback;
import '../models/room.dart' show Room;

mixin ManagerLifecycleMixin on RoomManagerBase {
  /// LinkedHashMap preserves insertion order — used as LRU access order.
  /// Most recently accessed manager is at the end; eviction removes from
  /// the start of the inactive (disconnected) entries.
  final Map<String, ChatManager> _managers = {};

  /// Maximum number of cached ChatManager instances. Active (connected)
  /// managers are never evicted — only inactive ones over the limit.
  /// Override [maxCachedManagers] to customize.
  @override
  int get maxCachedManagers => 10;

  // ═══════════════════════════════════════════════════════════════════════════
  // RoomManagerBase contract
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void disposeAllManagers() {
    for (final mgr in _managers.values) {
      mgr.dispose();
    }
    _managers.clear();
  }

  @override
  void notifyManagerRoomDeleted(String roomId) {
    _managers[roomId]?.onRoomDeleted();
  }

  @override
  bool isRoomActive(String roomId) {
    final manager = managerOrNull(roomId);
    return manager != null && manager.isAttached;
  }

  @override
  bool isRoomManaged(String roomId) => _managers.containsKey(roomId);

  @override
  ChatManager managerForRoom(Room room) {
    final cached = _managers[room.id];
    if (cached != null && !cached.isEmpty) {
      _touchAccess(room.id, cached);
      return cached;
    }
    cached?.dispose();
    final manager = ChatManager(room);
    _managers[room.id] = manager;
    _evictIfNeeded();
    return manager;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Public API
  // ═══════════════════════════════════════════════════════════════════════════

  ChatManager manager(String roomId) => managerForRoom(room(roomId));

  @override
  ChatManager? managerOrNull(String roomId) => _managers[roomId];

  Future<T?> connect<T extends Object?>(
    Room room,
    OnChatPageOpeningCallback<T> callback, {
    ValueChanged<String>? onError,
  }) async {
    try {
      ensureMetadataForRoom(room);
      final mgr = managerForRoom(room)..connect();

      if (room.isLocal) ensureMetadataForRoom(room);

      try {
        return await callback(mgr);
      } finally {
        mgr.disconnect();
        _evictIfNeeded();
        final current = this.room(room.id);
        if (current.isLocal || current.isEmpty) {
          cleanupOrphanedParticipants(current);
        }
      }
    } catch (e) {
      onError?.call(e.toString());
      return null;
    }
  }

  Future<T?> openRoomFromNotification<T extends Object?>(
    String roomId,
    OnChatPageOpeningCallback<T> callback, {
    ValueChanged<String>? onError,
  }) async {
    if (me.isEmpty || roomId.isEmpty) return null;

    var target = room(roomId);
    if (target.isEmpty) {
      try {
        target = await roomDelegate.get(roomId);
      } catch (e) {
        debugPrint('[ManagerLifecycleMixin] failed to fetch room $roomId: $e');
        onError?.call(e.toString());
        return null;
      }
    }
    if (target.isEmpty) return null;

    final existing = managerOrNull(roomId);
    if (existing != null && existing.isAttached) return null;

    return connect(target, callback, onError: onError);
  }

  void disconnect(String roomId) {
    _managers.remove(roomId)?.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LRU Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Marks [roomId] as most recently accessed by re-inserting it at the
  /// end of the LinkedHashMap order.
  void _touchAccess(String roomId, ChatManager manager) {
    _managers.remove(roomId);
    _managers[roomId] = manager;
  }

  /// Evicts the oldest inactive managers when the cache exceeds
  /// [maxCachedManagers]. Active managers are never evicted.
  void _evictIfNeeded() {
    if (_managers.length <= maxCachedManagers) return;

    final overflow = _managers.length - maxCachedManagers;
    final toEvict = <String>[];

    for (final entry in _managers.entries) {
      if (toEvict.length >= overflow) break;
      if (entry.value.isAttached) continue;
      toEvict.add(entry.key);
    }

    for (final id in toEvict) {
      _managers.remove(id)?.dispose();
    }
  }
}
