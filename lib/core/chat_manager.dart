import 'dart:async' show StreamSubscription;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart' show ValueNotifier, WidgetsBinding;

import '../delegates/message.dart' show PaginatedMessageStream;
import '../delegates/settings.dart' show ChatSilentNotification;
import '../models/message.dart'
    show Message, MessageStatus, MessageKeys, TextMessage, LinkMessage;
import '../models/profile.dart' show Profile;
import '../models/room.dart' show Room, RoomKeys;
import '../models/status.dart' show Status;
import '../models/typing.dart' show Typing;
import '../utils/field_value.dart' show ChatValueDelete, ChatValueTimestamp;
import 'base.dart' show BaseNotifier;
import 'room_manager.dart' show RoomManager;
import 'room_manager_base.dart' show OnDeniedToSendMessage, VerifyToSendMessage;

part '../extensions/chat_manager_actions.dart';
part '../extensions/chat_manager_messaging.dart';
part '../extensions/chat_manager_status.dart';

class ChatManager extends BaseNotifier {
  // ── Constructor ────────────────────────────────────────────────────────────

  ChatManager(this.room)
      : super(
          pausedDurationWhenAppBackground: const Duration(minutes: 1),
          connection: RoomManager.i.connection,
          connectivity: RoomManager.i.connectivity,
        );

  // ── Room State ─────────────────────────────────────────────────────────────

  late Room room;

  late final profileNotifier = ValueNotifier(
    RoomManager.i.profileFromRoom(room),
  );
  late final statusNotifier = ValueNotifier(RoomManager.i.statusFromRoom(room));
  late final typingsNotifier = ValueNotifier(
    RoomManager.i.typingsFromRoom(room),
  );

  final ValueNotifier<bool> _deleted = ValueNotifier(false);

  bool _attached = false;
  bool loading = true;

  // ── Message State ──────────────────────────────────────────────────────────

  Map<String, Message> mappedMessages = {};
  Message? replyMsg;
  Set<String> availableInputtedLinks = {};

  final Set<String> _pendingDeliveryIds = {};

  final Set<String> _pendingSendIds = {};

  PaginatedMessageStream? _paginatedStream;
  StreamSubscription? _sub;

  /// Page size for paginated message loading. Override via constructor or
  /// at the RoomManager level if app needs different sizes.
  int pageSize = 50;

  bool _loadingMore = false;

  bool get isLoadingMore => _loadingMore;

  bool get hasMoreMessages => _paginatedStream?.hasMore ?? false;

  // ── Factories ─────────────────────────────────────────────────────────────

  factory ChatManager.of(String roomId) => RoomManager.i.manager(roomId);

  static ChatManager? ofOrNull(String roomId) =>
      RoomManager.i.managerOrNull(roomId);

  // ── Getters ───────────────────────────────────────────────────────────────

  @override
  String get me => RoomManager.i.me;

  String get roomId => room.id;

  bool get isEmpty => room.isEmpty;

  bool get isDeleted => _deleted.value;

  bool get isAttached => _attached;

  Profile get profile => profileNotifier.value;

  Status get status => statusNotifier.value;

  List<Typing> get typings => typingsNotifier.value;

  ValueNotifier<bool> get deletedNotifier => _deleted;

  List<Message> get messages => mappedMessages.values.toList();

  List<Message> get sortedMessages {
    final list = mappedMessages.values.toList();
    list.sort((a, b) => a.createdAt.timestamp.compareTo(b.createdAt.timestamp));
    return list;
  }

  List<Message> get unseens =>
      mappedMessages.values.where((e) => !e.isSeenByMe).toList();

  List<Message> get pins =>
      mappedMessages.values.where((e) => e.isPinned).toList();

  // ── BaseNotifier Overrides ────────────────────────────────────────────────

  @override
  void run() => _listen();

  @override
  void stop() {
    _sub?.cancel();
    _sub = null;
    _paginatedStream?.cancel();
    _paginatedStream = null;
    typing(false);
  }

  @override
  void background() {
    RoomManager.i.markAsActive(null);
    RoomManager.i.markAsTyping(roomId, false);
  }

  @override
  void foreground() => RoomManager.i.markAsActive(roomId);

  @override
  void paused() {}

  @override
  void dispose() {
    disconnect();
    profileNotifier.dispose();
    statusNotifier.dispose();
    typingsNotifier.dispose();
    _deleted.dispose();
    super.dispose();
  }

  // ── Connect / Disconnect ──────────────────────────────────────────────────

  void connect() {
    if (_attached) return;
    _attached = true;
    _deleted.value = false;
    mappedMessages = {};

    attach(RoomManager.i.me);

    RoomManager.i.ensureMetadataForRoom(room);
    RoomManager.i.addListener(_syncLatest);
    RoomManager.i.markAsActive(roomId);

    _syncLatest();
    notify();
    if (room.unseenCount > 0) RoomManager.i.resetUnseenCount(room.id);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_attached) _syncLatest();
    });
  }

  void disconnect() {
    if (!_attached) return;
    _attached = false;
    _pendingDeliveryIds.clear();
    _pendingSendIds.clear();
    detach();
    RoomManager.i.markAsActive(null);
    RoomManager.i.removeListener(_syncLatest);
  }

  void verified() => RoomManager.i.verified(roomId, true);

  void onRoomDeleted() {
    if (_deleted.value) return;
    _deleted.value = true;
    _sub?.cancel();
    _sub = null;
    mappedMessages = {};
    notify();
    disconnect();
  }

  // ── Room Sync ─────────────────────────────────────────────────────────────

  void _syncLatest() {
    final r = RoomManager.i.room(roomId);
    if (r.isEmpty) {
      _deleted.value = true;
      notify();
      return;
    }
    room = r;
    profileNotifier.value = RoomManager.i.profileFromRoom(r);
    statusNotifier.value = RoomManager.i.statusFromRoom(r);
    typingsNotifier.value = RoomManager.i.typingsFromRoom(r);
    notify();
  }

  // ── Message Stream ────────────────────────────────────────────────────────

  void _listen() {
    _sub?.cancel();
    _paginatedStream?.cancel();
    if (roomId.isEmpty) return;

    if (!loading && mappedMessages.isEmpty) {
      loading = true;
      notifyListeners();
    }

    _paginatedStream = RoomManager.i.messageDelegate.streamPaginated(
      roomId,
      pageSize: pageSize,
    );

    _sub = _paginatedStream!.stream.listen(
      (event) {
        loading = false;

        final incoming = <String, Message>{};
        for (final e in event) {
          final local =
              _pendingSendIds.contains(e.id) ? mappedMessages[e.id] : null;
          incoming[e.id] = (local != null && local.status != MessageStatus.sent)
              ? e.copyWith(status: local.status)
              : e;
        }

        for (final id in _pendingSendIds) {
          if (!incoming.containsKey(id)) {
            final local = mappedMessages[id];
            if (local != null) incoming[id] = local;
          }
        }

        mappedMessages = incoming;
        notify();
        _deliverUndelivered();
        RoomManager.i.handleBotReply(roomId, sortedMessages);
      },
      onError: (error, stackTrace) {
        loading = false;
        notify();
        RoomManager.i.errorReporter.report(
          error,
          stackTrace: stackTrace is StackTrace ? stackTrace : null,
          source: 'ChatManager._listen',
          context: {'roomId': roomId},
        );
      },
    );
  }

  Future<bool> loadMoreMessages() async {
    if (_loadingMore) return false;
    if (_paginatedStream == null) return false;
    if (!_paginatedStream!.hasMore) return false;

    _loadingMore = true;
    notify();

    try {
      final loaded = await _paginatedStream!.loadMore();
      return loaded;
    } catch (e, st) {
      RoomManager.i.errorReporter.report(
        e,
        stackTrace: st,
        source: 'ChatManager.loadMoreMessages',
        context: {'roomId': roomId},
      );
      return false;
    } finally {
      _loadingMore = false;
      notify();
    }
  }

  void _deliverUndelivered() {
    final undelivered = mappedMessages.values.where((msg) {
      if (msg.isSentByMe) return false;
      if (msg.isDeliveredByMe || msg.isSeenByMe) return false;
      if (_pendingDeliveryIds.contains(msg.id)) return false;
      return true;
    }).toList();

    if (undelivered.isEmpty) return;

    for (final msg in undelivered) {
      _pendingDeliveryIds.add(msg.id);
      put(msg.copyWith(status: MessageStatus.delivered));
    }

    _batchDeliver(undelivered);
  }

  Future<void> _batchDeliver(List<Message> messages) async {
    final values = {
      for (final msg in messages)
        msg.id: {'${MessageKeys.i.statuses}.$me': MessageStatus.delivered.name},
    };

    final success = await RoomManager.i.updateMessages(roomId, values);

    if (success) {
      final latest = messages.last;
      if (room.lastMessageId == latest.id) {
        await RoomManager.i.update(roomId, {
          '${RoomKeys.i.lastMessageStatuses}.$me': MessageStatus.delivered.name,
        });
      }
    }

    for (final msg in messages) {
      _pendingDeliveryIds.remove(msg.id);
      if (!success) put(msg);
    }
  }

  // ── Local Message Operations ──────────────────────────────────────────────

  void put(Message message) {
    replyMsg = null;
    mappedMessages[message.id] = message;
    notifyListeners();
  }

  void puts(Iterable<Message> messages) {
    replyMsg = null;
    for (final msg in messages) {
      mappedMessages[msg.id] = msg;
    }
    notifyListeners();
  }

  void pop(Message message) {
    replyMsg = null;
    mappedMessages.remove(message.id);
    notifyListeners();
  }

  void pops(Iterable<Message> messages) {
    replyMsg = null;
    for (final msg in messages) {
      mappedMessages.remove(msg.id);
    }
    notifyListeners();
  }

  void reply(Message? message) {
    replyMsg = message;
    notifyListeners();
  }

  void inputtedLinks(String text) async {
    if (text.isEmpty) {
      availableInputtedLinks.clear();
      return;
    }
    final value = text.trim();
    final linkRegex = RegExp(r'(https?://\S+)', caseSensitive: false);
    final matches = linkRegex.allMatches(value);
    final newLinks = matches
        .map((match) => match.group(0)!)
        .map((url) => url.replaceAll(RegExp(r'[.,)\]]+$'), ''))
        .toSet();
    if (setEquals(newLinks, availableInputtedLinks)) return;
    availableInputtedLinks = newLinks;
    notifyListeners();
  }

  void dismissLink(String link) {
    availableInputtedLinks.remove(link);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
