import 'dart:async';

import 'package:flutter/material.dart';

import '../models/message.dart';
import '../models/room.dart';
import '../utils/field_value.dart';
import 'base.dart';
import 'room.dart';

class ChatManager extends BaseNotifier {
  ChatManager(this.room)
      : super(Duration(minutes: 1), RoomManager.i.connectivity);

  late Room room;
  late final profile = ValueNotifier(RoomManager.i.profileFromRoom(room));
  late final status = ValueNotifier(RoomManager.i.statusFromRoom(room));
  late final typings = ValueNotifier(RoomManager.i.typingsFromRoom(room));

  factory ChatManager.of(String roomId) {
    return RoomManager.i.manager(roomId);
  }

  static ChatManager? ofOrNull(String roomId) {
    return RoomManager.i.managerOrNull(roomId);
  }

  bool _attached = false;
  bool loading = true;
  Map<String, Message> mappedMessages = {};

  String get roomId => room.id;

  @override
  String get me => RoomManager.i.me;

  List<Message> get messages => mappedMessages.values.toList();

  List<Message> get unseens {
    return mappedMessages.values.where((e) => !e.isSeenByMe).toList();
  }

  List<Message> get pins {
    return mappedMessages.values.where((e) => e.isPinned).toList();
  }

  @override
  void background() {
    RoomManager.i.markAsActive(null);
    RoomManager.i.markAsTyping(roomId, false);
  }

  @override
  void foreground() {
    RoomManager.i.markAsActive(roomId);
  }

  @override
  void paused() {}

  @override
  void run() {
    _listen();
  }

  @override
  void stop() {
    _sub?.cancel();
    typing(false);
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  void connect() {
    if (_attached) return;
    _attached = true;
    mappedMessages = {};
    RoomManager.i.addListener(_latest);
    run();
    notify();
    RoomManager.i.markAsActive(roomId);
    final unseen = room.unseenCount;
    if (unseen > 0) {
      RoomManager.i.resetUnseenCount(room.id);
    }
  }

  void disconnect() {
    if (!_attached) return;
    _attached = false;
    stop();
    RoomManager.i.markAsActive(null);
    RoomManager.i.removeListener(_latest);
  }

  void _latest() {
    final r = RoomManager.i.room(roomId);
    room = r;
    profile.value = RoomManager.i.profileFromRoom(r);
    status.value = RoomManager.i.statusFromRoom(r);
    typings.value = RoomManager.i.typingsFromRoom(r);
  }

  StreamSubscription? _sub;

  void _listen() {
    _sub?.cancel();
    if (roomId.isEmpty) return;
    if (!loading) {
      loading = true;
      notifyListeners();
    }
    _sub = RoomManager.i.stream(roomId).listen((event) {
      loading = false;
      final current = Map.fromEntries(event.map((e) => MapEntry(e.id, e)));
      mappedMessages = current;
      delivered(current.values);
      notify();
    });
  }

  Message? replyMsg;

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

  void react(Message msg, String? react) async {
    if (msg.isSending) return;
    put(msg.copyWith(react: react));
    final status = await RoomManager.i.updateMessage(msg.roomId, msg.id, {
      "${MessageKeys.reactions}.$me":
          (react ?? '').isEmpty ? ChatValueDelete() : react,
    });
    if (status) return;
    put(msg);
  }

  void pin(Message msg) async {
    if (msg.isSending) return;
    put(msg.copyWith(isPinned: true));
    final status = await RoomManager.i.updateMessage(msg.roomId, msg.id, {
      "${MessageKeys.pins}.$me": true,
    });
    if (status) return;
    put(msg.copyWith(isPinned: false));
  }

  void unpin(Message msg) async {
    if (msg.isSending) return;
    put(msg.copyWith(isPinned: false));
    final status = await RoomManager.i.updateMessage(msg.roomId, msg.id, {
      "${MessageKeys.pins}.$me": ChatValueDelete(),
    });
    if (status) return;
    put(msg.copyWith(isPinned: true));
  }

  void togglePin(Message msg) {
    if (msg.isPinned) {
      unpin(msg);
    } else {
      pin(msg);
    }
  }

  void delete(Message msg) async {
    if (!msg.isSentByMe || msg.isSending) return;
    if (msg.isSending) return;
    put(msg.copyWith(isDeleted: true));
    final status = await RoomManager.i.updateMessage(
      msg.roomId,
      msg.id,
      {MessageKeys.isDeleted: true},
      roomValues: {
        if (room.lastMessageId == msg.id) ...{
          RoomKeys.lastMessage: msg.lastMessage(deleted: true),
          RoomKeys.lastMessageSenderId: me,
          RoomKeys.lastMessageDeleted: true,
        },
      },
    );
    if (!status) {
      put(msg.copyWith(isDeleted: false));
      return;
    }
  }

  void deleteForMe(Message msg) async {
    if (msg.isSending) return;
    put(msg.copyWith(isDeletedForMe: true));
    final status = await RoomManager.i.updateMessage(msg.roomId, msg.id, {
      "${MessageKeys.deletes}.$me": true,
    });
    if (status) return;
    put(msg.copyWith(isDeletedForMe: false));
  }

  void deletes(List<Message> messages) {
    final current = messages.where((e) => e.isSentByMe && !e.isSending);
    if (current.isEmpty) return;
    puts(messages.map((e) => e.copyWith(isDeleted: true)));
    RoomManager.i.deleteMessages(messages).then((v) {
      if (v) return;
      puts(current.map((e) => e.copyWith(isDeleted: false)));
    });
  }

  void deletesForMe(Iterable<Message> messages) async {
    final current = messages.where((e) => !e.isSending);
    if (current.isEmpty) return;
    puts(current.map((e) => e.copyWith(isDeletedForMe: true)));
    final entries = current.map((e) {
      final update = {"${MessageKeys.deletes}.$me": true};
      return MapEntry(e.id, update);
    });
    final v = await RoomManager.i.updateMessages(
      roomId,
      Map.fromEntries(entries),
    );
    if (v) {
      return;
    }
    puts(current.map((e) => e.copyWith(isDeletedForMe: false)));
  }

  void remove(Message msg) async {
    if (!msg.shouldRemove) return;
    pop(msg);
    final participants = room.participants.map((e) {
      if (e == me) return true;
      if (msg.statuses.containsKey(e)) {
        return msg.removes[e] ?? false;
      }
      return true;
    });
    if (participants.every((e) => e == true)) {
      final status = await RoomManager.i.deleteMessage(msg);
      if (status) return;
      put(msg);
    } else {
      final status = await RoomManager.i.updateMessage(msg.roomId, msg.id, {
        "${MessageKeys.removes}.$me": true,
      });
      if (status) return;
      put(msg);
    }
  }

  void send(Message message) async {
    if (room.isLocal) {
      final global = await RoomManager.i.createOrGetRoom(room);
      if (global.isEmpty) {
        return;
      }
      room = global;
      notify();
    }
    put(message);
    RoomManager.i.createMessage(message).then((v) {
      put(v);
    });
  }

  void edit(Message msg, String content) async {
    if (!(msg is TextMessage || msg is LinkMessage)) return;
    if (content.isEmpty || content == msg.content) return;
    Message updatedMsg = msg;
    if (msg is TextMessage) {
      updatedMsg = msg.copyWith(
        isEdited: true,
        editedAt: ChatValueTimestamp.now(),
        text: content,
      );
    } else if (msg is LinkMessage) {
      updatedMsg = msg.copyWith(
        isEdited: true,
        editedAt: ChatValueTimestamp.now(),
        link: content,
      );
    }
    put(updatedMsg);
    final status = await RoomManager.i.updateMessage(
      roomId,
      msg.id,
      {
        MessageKeys.isEdited: true,
        MessageKeys.content: content,
        MessageKeys.editedAt: ChatValueTimestamp(),
      },
      roomValues: {
        if (room.lastMessageId == msg.id) ...{
          RoomKeys.lastMessage: updatedMsg.lastMessage(),
        },
      },
    );
    if (status) return;
    put(msg);
  }

  void forward(List<String> targetRoomIds, Message msg) async {
    if (targetRoomIds.isEmpty) return;
    put(msg.copyWith(isForwarded: true));
    final status = await RoomManager.i.forward(targetRoomIds, msg);
    if (status) return;
    put(msg);
  }

  void typing(bool status) => RoomManager.i.markAsTyping(roomId, status);

  void seen(Message msg) async {
    if (msg.isSeenByMe) return;
    put(msg.copyWith(status: MessageStatus.seen));
    final status = await RoomManager.i.updateMessage(msg.roomId, msg.id, {
      "${MessageKeys.statuses}.$me": MessageStatus.seen.name,
    });
    if (status) return;
    put(msg);
  }

  void delivered(Iterable<Message> messages) {
    final current = messages.where((e) => !e.isDeliveredByMe);
    if (current.isEmpty) return;
    puts(current.map((e) => e.copyWith(status: MessageStatus.delivered)));
    final entries = current.map((e) {
      final update = {
        "${MessageKeys.statuses}.$me": MessageStatus.delivered.name,
      };
      return MapEntry(e.id, update);
    });
    RoomManager.i.updateMessages(roomId, Map.fromEntries(entries)).then((v) {
      if (v) return;
      puts(current);
    });
  }

  void visible(Message msg) {}

  void invisible(Message msg) {}
}
