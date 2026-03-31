import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../managers/chat.dart';
import '../managers/room.dart';
import '../utils/chat_helper.dart';
import '../utils/enum_parser.dart';
import '../utils/field_value.dart';
import '../utils/parser.dart';

typedef MessageExtra = Map<String, dynamic>;

class MessageKeys {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final String data;
  final String kind;
  final String type;
  final String statuses;
  final String createdAt;
  final String updatedAt;
  final String urls;
  final String url;
  final String waveform;
  final String replyId;
  final String reactions;
  final String pins;
  final String durationInSec;
  final String thumbnail;
  final String deletes;
  final String removes;
  final String isDeleted;
  final String isEdited;
  final String editedAt;
  final String isForwarded;
  final String extra;

  static MessageKeys get i => RoomManager.i.modelConfigs.messageKeys;

  const MessageKeys({
    this.id = 'id',
    this.roomId = 'roomId',
    this.senderId = 'senderId',
    this.content = 'content',
    this.data = 'data',
    this.kind = 'kind',
    this.type = 'type',
    this.statuses = 'statuses',
    this.createdAt = 'createdAt',
    this.updatedAt = 'updatedAt',
    this.urls = 'urls',
    this.url = 'url',
    this.waveform = 'waveform',
    this.replyId = 'replyId',
    this.reactions = 'reactions',
    this.pins = 'pins',
    this.durationInSec = 'durationInSec',
    this.thumbnail = 'thumbnail',
    this.deletes = 'deletes',
    this.removes = 'removes',
    this.isDeleted = 'isDeleted',
    this.isEdited = 'isEdited',
    this.editedAt = 'editedAt',
    this.isForwarded = 'isForwarded',
    this.extra = 'extra',
  });
}

enum MessageType { none, audio, custom, image, link, text, video }

enum MessageStatus { none, sending, failed, sent, delivered, seen, deleting }

class Message extends Equatable {
  // MANDATORY
  final String id;
  final String roomId;
  final String senderId;
  final ChatValueTimestamp createdAt;
  final ChatValueTimestamp updatedAt;
  final MessageType type;
  final Map<String, MessageStatus> statuses;

  // OPTIONAL
  final Map<String, bool> deletes;
  final Map<String, bool> removes;
  final Map<String, bool> pins;
  final ChatValueTimestamp editedAt;
  final Map<String, String> reactions;
  final String replyId;
  final MessageExtra extra;

  final bool isDeleted;
  final bool isEdited;
  final bool isForwarded;

  bool get isDeletedByMe => deletes[me] ?? false;

  bool get isRemovedByMe => removes[me] ?? false;

  bool get isReactedByMe {
    final x = reactByMe;
    return x != null && x.isNotEmpty;
  }

  bool get shouldRemove => isDeleted || isDeletedByMe;

  bool get isSentByMe => senderId == me;

  bool get isSending {
    if (statuses.length > 1) return false;
    return statusFor(me) == MessageStatus.sending;
  }

  bool get isSeenByMe {
    if (isSentByMe) return true;
    if (isSending) return true;
    return statusFor(me) == MessageStatus.seen;
  }

  bool get isDeliveredByMe {
    if (isSeenByMe) return true;
    return statusFor(me) == MessageStatus.delivered;
  }

  bool get isPinned => pins[me] ?? false;

  bool get isEditable => content?.isNotEmpty ?? false;

  bool get isEmpty {
    if (id.isEmpty) return true;
    if (roomId.isEmpty) return true;
    if (senderId.isEmpty) return true;
    if (type == MessageType.none) return true;
    if (statuses.isEmpty) return true;
    if (createdAt.isEmpty) return true;
    return false;
  }

  String get me => RoomManager.i.me;

  String? get reactByMe => reactions[me];

  Message get replyMessage {
    final msg = ChatManager.ofOrNull(roomId)?.mappedMessages[replyId];
    if (msg == null) return Message.empty();
    if (msg.isDeleted || msg.isDeletedByMe) return Message.empty();
    return msg;
  }

  String? get content {
    final msg = this;
    if (msg is ImageMessage) return msg.caption;
    if (msg is LinkMessage) return msg.link;
    if (msg is TextMessage) return msg.text;
    if (msg is VideoMessage) return msg.caption;
    return null;
  }

  String lastMessage({
    String? sender,
    String? senderId,
    bool edited = false,
    bool deleted = false,
    bool notification = false,
  }) {
    final msg = this;

    String body = '{SENDER} sent a message';

    if (edited) {
      body = "{SENDER} edited a message";
    } else if (deleted) {
      body = "{SENDER} deleted a message";
    } else {
      if (msg is TextMessage) {
        body = notification ? msg.text : "{SENDER_OR_EMPTY}${msg.text}";
      } else if (msg is ImageMessage) {
        body = '{SENDER} sent ${msg.urls.length > 1 ? 'photos' : 'a photo'}';
      } else if (msg is VideoMessage) {
        body = '{SENDER} sent a video';
      } else if (msg is AudioMessage) {
        body = '{SENDER} sent a voice message';
      } else if (msg is LinkMessage) {
        body = '{SENDER} sent a link';
      }
    }

    return body;
  }

  String notificationBody(String sender) {
    return lastMessage(senderId: senderId, sender: sender, notification: true);
  }

  bool isDelivered(Set<String> participants) {
    return participants.every((e) {
      if (e == me) return true;
      if (statuses[e] == MessageStatus.delivered) return true;
      if (statuses[e] == MessageStatus.seen) return true;
      return false;
    });
  }

  bool isSeen(Set<String> participants) {
    return participants.every((e) {
      if (e == me) return true;
      if (statuses[e] == MessageStatus.seen) return true;
      return false;
    });
  }

  MessageStatus get status {
    if (isSending) return MessageStatus.sending;
    final participants = RoomManager.i.room(roomId).participants;
    if (isSeen(participants)) return MessageStatus.seen;
    if (isDelivered(participants)) return MessageStatus.delivered;
    return MessageStatus.sent;
  }

  MessageStatus statusFor(String uid) => statuses[uid] ?? MessageStatus.none;

  List<String> findPathOrUrls([bool thumbnail = false]) {
    final msg = this;
    switch (msg) {
      case AudioMessage():
        return [msg.url];
      case ImageMessage():
        return msg.urls;
      case VideoMessage():
        return [msg.url, if (thumbnail) msg.thumbnail];
      default:
        return [];
    }
  }

  const Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    required this.statuses,
    required this.deletes,
    required this.pins,
    required this.removes,
    required ChatValueTimestamp? editedAt,
    required String? replyId,
    required this.reactions,
    required this.isDeleted,
    required this.isEdited,
    required this.isForwarded,
    required this.extra,
  })  : editedAt = editedAt ?? const ChatValueTimestamp(),
        replyId = replyId ?? '';

  factory Message.empty() {
    return Message(
      id: '',
      roomId: '',
      senderId: '',
      createdAt: ChatValueTimestamp(),
      updatedAt: ChatValueTimestamp(),
      type: MessageType.none,
      statuses: {},
      deletes: {},
      pins: {},
      removes: {},
      editedAt: ChatValueTimestamp(),
      replyId: null,
      reactions: {},
      isDeleted: false,
      isEdited: false,
      isForwarded: false,
      extra: {},
    );
  }

  factory Message.parse(Object? source, {MessageExtra? extra}) {
    if (source is Message) return source;
    if (source is! Map) return Message.empty();
    final keys = MessageKeys.i;
    final ex = source[keys.extra];
    final id = source[keys.id];
    final roomId = source[keys.roomId];
    final senderId = source[keys.senderId];
    final type = source[keys.type];
    final statuses = source[keys.statuses];
    final createdAt = source[keys.createdAt];
    final updatedAt = source[keys.updatedAt];
    final replyId = source[keys.replyId];
    final reactions = source[keys.reactions];
    final pins = source[keys.pins];
    final deletes = source[keys.deletes];
    final removes = source[keys.removes];
    final isDeleted = source[keys.isDeleted];
    final isEdited = source[keys.isEdited];
    final editedAt = source[keys.editedAt];
    final isForwarded = source[keys.isForwarded];

    final content = source[keys.content];
    final url = source[keys.url];
    final duration = source[keys.durationInSec];

    final msg = Message(
      id: id is String && id.isNotEmpty ? id : '',
      roomId: roomId is String && roomId.isNotEmpty ? roomId : '',
      senderId: senderId is String && senderId.isNotEmpty ? senderId : '',
      type: MessageType.values.parse(type),
      statuses: MessageStatus.values.references(statuses),
      createdAt: ChatValueTimestamp.parse(createdAt),
      updatedAt: ChatValueTimestamp.parse(updatedAt),
      editedAt: ChatValueTimestamp.parse(editedAt),
      reactions: reactions is Map ? reactions.parse() : {},
      deletes: deletes is Map ? deletes.parse() : {},
      pins: pins is Map ? pins.parse() : {},
      removes: removes is Map ? removes.parse() : {},
      replyId: replyId is String && replyId.isNotEmpty ? replyId : null,
      isEdited: isEdited is bool ? isEdited : false,
      isForwarded: isForwarded is bool ? isForwarded : false,
      isDeleted: isDeleted is bool ? isDeleted : false,
      extra: extra ?? (ex is Map ? ex.parse() : {}),
    );

    final mContent = content is String && content.isNotEmpty ? content : null;
    final mDuration = duration is num && duration > 0 ? duration.toInt() : null;
    final mUrl = url is String && url.isNotEmpty ? url : null;

    switch (msg.type) {
      case MessageType.none:
        return Message.empty();
      case MessageType.audio:
        if (mDuration == null || mUrl == null) return Message.empty();
        final waveforms = source[keys.waveform];
        final mWaveform = waveforms is String ? jsonDecode(waveforms) : null;
        return AudioMessage.from(
          msg,
          mDuration,
          mUrl,
          mWaveform is Iterable ? mWaveform.parsedDoubles.toList() : [],
        );
      case MessageType.custom:
        final data = source[keys.data];
        final kind = source[keys.kind];
        final mKind = kind is String && kind.isNotEmpty ? kind : '';
        if (mKind.isEmpty) return Message.empty();
        return CustomMessage.from(
          msg,
          data is Map ? data : {},
          mKind,
        );
      case MessageType.image:
        final urls = source[keys.urls];
        final mUrls = urls is List && urls.isNotEmpty
            ? urls.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
            : <String>[];
        if (mUrls.isEmpty) return Message.empty();
        return ImageMessage.from(msg, mContent, mUrls);
      case MessageType.link:
        if (mContent == null) return Message.empty();
        return LinkMessage.from(msg, mContent);
      case MessageType.text:
        if (mContent == null) return Message.empty();
        return TextMessage.from(msg, mContent);
      case MessageType.video:
        final t = source[keys.thumbnail];
        final mT = t is String && t.isNotEmpty ? t : null;
        if (mDuration == null || mUrl == null || mT == null) {
          return Message.empty();
        }
        return VideoMessage.from(msg, mContent, mDuration, mT, mUrl);
    }
  }

  Message copyWith({
    bool? isDeleted,
    bool? isDeletedForMe,
    bool? isEdited,
    bool? isForwarded,
    bool? isPinned,
    bool? isRemoved,
    String? id,
    String? roomId,
    String? senderId,
    String? replyId,
    String? react,
    ChatValueTimestamp? createdAt,
    ChatValueTimestamp? editedAt,
    ChatValueTimestamp? updatedAt,
    MessageStatus? status,
    MessageExtra? extra,
  }) {
    final deletes = Map<String, bool>.from(this.deletes);
    if (isDeletedForMe == true) deletes[me] = true;

    final pins = Map<String, bool>.from(this.pins);
    if (isPinned != null) {
      if (isPinned) {
        pins[me] = true;
      } else {
        pins.remove(me);
      }
    }

    final removes = Map<String, bool>.from(this.removes);
    if (isRemoved == true) removes[me] = true;

    final reactions = Map<String, String>.from(this.reactions);
    if (react != null) {
      if (react.isNotEmpty) {
        reactions[me] = react;
      } else {
        reactions.remove(me);
      }
    }

    final statuses = Map<String, MessageStatus>.from(this.statuses);
    if (status != null) statuses[me] = status;

    return Message(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      createdAt: createdAt ?? this.createdAt,
      statuses: statuses,
      deletes: deletes,
      editedAt: editedAt ?? this.editedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replyId: replyId ?? this.replyId,
      reactions: reactions,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      isForwarded: isForwarded ?? this.isForwarded,
      pins: pins,
      removes: removes,
      type: type,
      extra: extra ?? this.extra,
    );
  }

  Message resolveWith(Map changes) {
    final keys = MessageKeys.i;
    final extra = changes[keys.extra];
    final id = changes[keys.id];
    final roomId = changes[keys.roomId];
    final senderId = changes[keys.senderId];
    final type = changes[keys.type];
    final statuses = changes[keys.statuses];
    final createdAt = changes[keys.createdAt];
    final updatedAt = changes[keys.updatedAt];
    final replyId = changes[keys.replyId];
    final reactions = changes[keys.reactions];
    final pins = changes[keys.pins];
    final deletes = changes[keys.deletes];
    final removes = changes[keys.removes];
    final isDeleted = changes[keys.isDeleted];
    final isEdited = changes[keys.isEdited];
    final editedAt = changes[keys.editedAt];
    final isForwarded = changes[keys.isForwarded];
    return Message(
      id: id is String && id.isNotEmpty ? id : this.id,
      roomId: roomId is String && roomId.isNotEmpty ? roomId : this.roomId,
      senderId:
          senderId is String && senderId.isNotEmpty ? senderId : this.senderId,
      type: MessageType.values.tryParse(type) ?? this.type,
      statuses: MessageStatus.values.tryReferences(statuses) ?? this.statuses,
      createdAt: ChatValueTimestamp.tryParse(createdAt) ?? this.createdAt,
      updatedAt: ChatValueTimestamp.tryParse(updatedAt) ?? this.updatedAt,
      editedAt: ChatValueTimestamp.tryParse(editedAt) ?? this.editedAt,
      reactions: reactions is Map
          ? reactions.tryParse() ?? this.reactions
          : this.reactions,
      deletes:
          deletes is Map ? deletes.tryParse() ?? this.deletes : this.deletes,
      pins: pins is Map ? pins.tryParse() ?? this.pins : this.pins,
      removes:
          removes is Map ? removes.tryParse() ?? this.removes : this.removes,
      replyId: replyId is String && replyId.isNotEmpty ? replyId : this.replyId,
      isEdited: isEdited is bool ? isEdited : this.isEdited,
      isForwarded: isForwarded is bool ? isForwarded : this.isForwarded,
      isDeleted: isDeleted is bool ? isDeleted : this.isDeleted,
      extra: extra is Map ? extra.tryParse() ?? this.extra : this.extra,
    );
  }

  Map<String, dynamic> get source {
    final keys = MessageKeys.i;
    return {
      if (id.isNotEmpty) keys.id: id,
      if (roomId.isNotEmpty) keys.roomId: roomId,
      if (senderId.isNotEmpty) keys.senderId: senderId,
      if (type != MessageType.none) keys.type: type.name,
      if (!createdAt.isEmpty) keys.createdAt: createdAt,
      if (!updatedAt.isEmpty) keys.updatedAt: updatedAt,
      if (statuses.isNotEmpty)
        keys.statuses: statuses.map((k, v) => MapEntry(k, v.name)),
      if (deletes.isNotEmpty) keys.deletes: deletes,
      if (removes.isNotEmpty) keys.removes: removes,
      if (!editedAt.isEmpty) keys.editedAt: editedAt,
      if (reactions.isNotEmpty) keys.reactions: reactions,
      if (replyId.isNotEmpty) keys.replyId: replyId,
      if (isDeleted) keys.isDeleted: isDeleted,
      if (isEdited) keys.isEdited: isEdited,
      if (isForwarded) keys.isForwarded: isForwarded,
      if (pins.isNotEmpty) keys.pins: pins,
      if (extra.isNotEmpty) keys.extra: extra,
    };
  }

  @override
  List<Object?> get props {
    return [
      id,
      roomId,
      senderId,
      createdAt,
      updatedAt,
      type,
      statuses,
      replyId,
      reactions,
      pins,
      deletes,
      removes,
      isDeleted,
      isEdited,
      editedAt,
      isForwarded,
      extra,
    ];
  }
}

class AudioMessage extends Message {
  final int durationInSec;
  final String url;
  final List<double> waveform;

  Duration get duration => Duration(seconds: durationInSec);

  const AudioMessage._({
    super.id = '',
    super.roomId = '',
    super.senderId = '',
    super.createdAt = const ChatValueTimestamp(),
    super.updatedAt = const ChatValueTimestamp(),
    super.statuses = const {},
    super.deletes = const {},
    super.pins = const {},
    super.removes = const {},
    super.editedAt,
    super.replyId,
    super.reactions = const {},
    super.isDeleted = false,
    super.isEdited = false,
    super.isForwarded = false,
    super.extra = const {},
    this.durationInSec = 0,
    this.url = '',
    this.waveform = const [],
  }) : super(type: MessageType.audio);

  const AudioMessage.empty() : this._();

  factory AudioMessage.create(
    String path,
    int durationInSec,
    List<double> waveform, {
    String? roomId,
    MessageExtra? extra,
    String? id,
    String? senderId,
    String? replyId,
    ChatValueTimestamp? createdAt,
  }) {
    senderId ??= RoomManager.i.me;
    if (senderId.isEmpty) return AudioMessage.empty();
    id ??= ChatHelper.generateMessageId();
    createdAt ??= ChatValueTimestamp.now();
    return AudioMessage._(
      id: id,
      roomId: roomId ?? '',
      senderId: senderId,
      replyId: replyId,
      createdAt: createdAt,
      updatedAt: createdAt,
      extra: extra ?? {},
      durationInSec: durationInSec,
      url: path,
      waveform: waveform,
      statuses: {senderId: MessageStatus.sending},
    );
  }

  factory AudioMessage.from(
    Message msg,
    int durationInSec,
    String url,
    List<double> waveform,
  ) {
    return AudioMessage._(
      id: msg.id,
      roomId: msg.roomId,
      senderId: msg.senderId,
      createdAt: msg.createdAt,
      updatedAt: msg.updatedAt,
      statuses: msg.statuses,
      deletes: msg.deletes,
      pins: msg.pins,
      removes: msg.removes,
      editedAt: msg.editedAt,
      replyId: msg.replyId,
      reactions: msg.reactions,
      isDeleted: msg.isDeleted,
      isEdited: msg.isEdited,
      isForwarded: msg.isForwarded,
      extra: msg.extra,
      durationInSec: durationInSec,
      url: url,
      waveform: waveform,
    );
  }

  @override
  AudioMessage copyWith({
    bool? isDeleted,
    bool? isDeletedForMe,
    bool? isEdited,
    bool? isForwarded,
    bool? isPinned,
    bool? isRemoved,
    String? id,
    String? roomId,
    String? senderId,
    String? replyId,
    String? react,
    ChatValueTimestamp? createdAt,
    ChatValueTimestamp? editedAt,
    ChatValueTimestamp? updatedAt,
    MessageStatus? status,
    MessageExtra? extra,
    int? durationInSec,
    String? url,
    List<double>? waveform,
  }) {
    final msg = super.copyWith(
      isDeleted: isDeleted,
      isDeletedForMe: isDeletedForMe,
      isEdited: isEdited,
      isForwarded: isForwarded,
      isPinned: isPinned,
      isRemoved: isRemoved,
      id: id,
      roomId: roomId,
      senderId: senderId,
      replyId: replyId,
      react: react,
      createdAt: createdAt,
      editedAt: editedAt,
      updatedAt: updatedAt,
      status: status,
      extra: extra,
    );
    return AudioMessage.from(
      msg,
      durationInSec ?? this.durationInSec,
      url ?? this.url,
      waveform ?? this.waveform,
    );
  }

  @override
  AudioMessage resolveWith(Map changes) {
    final msg = super.resolveWith(changes);
    final keys = MessageKeys.i;
    final durationInSec = changes[keys.durationInSec];
    final url = changes[keys.url];
    final waveform = changes[keys.waveform];
    final mWaveform = waveform is String ? jsonDecode(waveform) : null;
    return AudioMessage.from(
      msg,
      durationInSec is num && durationInSec > 0
          ? durationInSec.toInt()
          : this.durationInSec,
      url is String && url.isNotEmpty ? url : this.url,
      mWaveform is Iterable && mWaveform.isNotEmpty
          ? mWaveform.parsedDoubles.toList()
          : this.waveform,
    );
  }

  @override
  Map<String, dynamic> get source {
    final keys = MessageKeys.i;
    return {
      ...super.source,
      if (durationInSec > 0) keys.durationInSec: durationInSec,
      if (url.isNotEmpty) keys.url: url,
      if (waveform.isNotEmpty) keys.waveform: jsonEncode(waveform),
    };
  }

  @override
  List<Object?> get props => [...super.props, durationInSec, url, waveform];

  @override
  String toString() => "$AudioMessage#$hashCode($durationInSec)";
}

class CustomMessage extends Message {
  final Map data;
  final String kind;

  const CustomMessage._({
    super.id = '',
    super.roomId = '',
    super.senderId = '',
    super.createdAt = const ChatValueTimestamp(),
    super.updatedAt = const ChatValueTimestamp(),
    super.statuses = const {},
    super.deletes = const {},
    super.pins = const {},
    super.removes = const {},
    super.editedAt,
    super.replyId,
    super.reactions = const {},
    super.isDeleted = false,
    super.isEdited = false,
    super.isForwarded = false,
    super.extra = const {},
    this.data = const {},
    this.kind = '',
  }) : super(type: MessageType.custom);

  const CustomMessage.empty() : this._();

  factory CustomMessage.create(
    String kind,
    Map data, {
    String? roomId,
    MessageExtra? extra,
    String? id,
    String? senderId,
    String? replyId,
    ChatValueTimestamp? createdAt,
  }) {
    senderId ??= RoomManager.i.me;
    if (senderId.isEmpty) return CustomMessage.empty();
    id ??= ChatHelper.generateMessageId();
    createdAt ??= ChatValueTimestamp.now();
    return CustomMessage._(
      id: id,
      roomId: roomId ?? '',
      senderId: senderId,
      replyId: replyId,
      createdAt: createdAt,
      updatedAt: createdAt,
      extra: extra ?? {},
      data: data,
      kind: kind,
      statuses: {senderId: MessageStatus.sending},
    );
  }

  factory CustomMessage.from(Message msg, Map data, String kind) {
    return CustomMessage._(
      id: msg.id,
      roomId: msg.roomId,
      senderId: msg.senderId,
      createdAt: msg.createdAt,
      updatedAt: msg.updatedAt,
      statuses: msg.statuses,
      deletes: msg.deletes,
      pins: msg.pins,
      removes: msg.removes,
      editedAt: msg.editedAt,
      replyId: msg.replyId,
      reactions: msg.reactions,
      isDeleted: msg.isDeleted,
      isEdited: msg.isEdited,
      isForwarded: msg.isForwarded,
      extra: msg.extra,
      data: data,
      kind: kind,
    );
  }

  @override
  CustomMessage copyWith({
    bool? isDeleted,
    bool? isDeletedForMe,
    bool? isEdited,
    bool? isForwarded,
    bool? isPinned,
    bool? isRemoved,
    String? id,
    String? roomId,
    String? senderId,
    String? replyId,
    String? react,
    ChatValueTimestamp? createdAt,
    ChatValueTimestamp? editedAt,
    ChatValueTimestamp? updatedAt,
    MessageStatus? status,
    MessageExtra? extra,
    Map? data,
    String? kind,
  }) {
    final msg = super.copyWith(
      isDeleted: isDeleted,
      isDeletedForMe: isDeletedForMe,
      isEdited: isEdited,
      isForwarded: isForwarded,
      isPinned: isPinned,
      isRemoved: isRemoved,
      id: id,
      roomId: roomId,
      senderId: senderId,
      replyId: replyId,
      react: react,
      createdAt: createdAt,
      editedAt: editedAt,
      updatedAt: updatedAt,
      status: status,
      extra: extra,
    );
    return CustomMessage.from(msg, data ?? this.data, kind ?? this.kind);
  }

  @override
  CustomMessage resolveWith(Map changes) {
    final msg = super.resolveWith(changes);
    final keys = MessageKeys.i;
    final data = changes[keys.data];
    final kind = changes[keys.kind];
    return CustomMessage.from(
      msg,
      data is Map && data.isNotEmpty ? data : this.data,
      kind is String && kind.isNotEmpty ? kind : this.kind,
    );
  }

  @override
  Map<String, dynamic> get source {
    final keys = MessageKeys.i;
    return {
      ...super.source,
      if (data.isNotEmpty) keys.data: data,
      if (kind.isNotEmpty) keys.kind: kind,
    };
  }

  @override
  List<Object?> get props => [...super.props, data, kind];

  @override
  String toString() => "$CustomMessage#$hashCode($kind)";
}

class ImageMessage extends Message {
  final String? caption;
  final List<String> urls;

  const ImageMessage._({
    super.id = '',
    super.roomId = '',
    super.senderId = '',
    super.createdAt = const ChatValueTimestamp(),
    super.updatedAt = const ChatValueTimestamp(),
    super.statuses = const {},
    super.deletes = const {},
    super.pins = const {},
    super.removes = const {},
    super.editedAt,
    super.replyId,
    super.reactions = const {},
    super.isDeleted = false,
    super.isEdited = false,
    super.isForwarded = false,
    super.extra = const {},
    this.caption,
    this.urls = const [],
  }) : super(type: MessageType.image);

  const ImageMessage.empty() : this._();

  factory ImageMessage.create(
    Iterable<String> paths, {
    String? roomId,
    String? caption,
    MessageExtra? extra,
    String? id,
    String? senderId,
    String? replyId,
    ChatValueTimestamp? createdAt,
  }) {
    senderId ??= RoomManager.i.me;
    if (senderId.isEmpty) return ImageMessage.empty();
    id ??= ChatHelper.generateMessageId();
    createdAt ??= ChatValueTimestamp.now();
    return ImageMessage._(
      id: id,
      roomId: roomId ?? '',
      senderId: senderId,
      createdAt: createdAt,
      updatedAt: createdAt,
      statuses: {senderId: MessageStatus.sending},
      extra: extra ?? {},
      replyId: replyId,
      caption: caption,
      urls: paths.toList(),
    );
  }

  factory ImageMessage.from(Message msg, String? caption, List<String> urls) {
    return ImageMessage._(
      id: msg.id,
      roomId: msg.roomId,
      senderId: msg.senderId,
      createdAt: msg.createdAt,
      updatedAt: msg.updatedAt,
      statuses: msg.statuses,
      deletes: msg.deletes,
      pins: msg.pins,
      removes: msg.removes,
      editedAt: msg.editedAt,
      replyId: msg.replyId,
      reactions: msg.reactions,
      isDeleted: msg.isDeleted,
      isEdited: msg.isEdited,
      isForwarded: msg.isForwarded,
      extra: msg.extra,
      caption: caption,
      urls: urls,
    );
  }

  @override
  ImageMessage copyWith({
    bool? isDeleted,
    bool? isDeletedForMe,
    bool? isEdited,
    bool? isForwarded,
    bool? isPinned,
    bool? isRemoved,
    String? id,
    String? roomId,
    String? senderId,
    String? replyId,
    String? react,
    ChatValueTimestamp? createdAt,
    ChatValueTimestamp? editedAt,
    ChatValueTimestamp? updatedAt,
    MessageStatus? status,
    MessageExtra? extra,
    String? caption,
    List<String>? urls,
  }) {
    final msg = super.copyWith(
      isDeleted: isDeleted,
      isDeletedForMe: isDeletedForMe,
      isEdited: isEdited,
      isForwarded: isForwarded,
      isPinned: isPinned,
      isRemoved: isRemoved,
      id: id,
      roomId: roomId,
      senderId: senderId,
      replyId: replyId,
      react: react,
      createdAt: createdAt,
      editedAt: editedAt,
      updatedAt: updatedAt,
      status: status,
      extra: extra,
    );
    return ImageMessage.from(msg, caption ?? this.caption, urls ?? this.urls);
  }

  @override
  ImageMessage resolveWith(Map changes) {
    final msg = super.resolveWith(changes);
    final keys = MessageKeys.i;
    final caption = changes[keys.content];
    final urls = changes[keys.urls];
    return ImageMessage.from(
      msg,
      caption is String && caption.isNotEmpty ? caption : this.caption,
      urls is Iterable && urls.isNotEmpty
          ? urls.parsedStrings.toList()
          : this.urls,
    );
  }

  @override
  Map<String, dynamic> get source {
    final keys = MessageKeys.i;
    return {
      ...super.source,
      if (caption != null && caption!.isNotEmpty) keys.content: caption,
      if (urls.isNotEmpty) keys.urls: urls,
    };
  }

  @override
  List<Object?> get props => [...super.props, caption, urls];

  @override
  String toString() => "$ImageMessage#$hashCode($urls)";
}

class LinkMessage extends Message {
  final String link;

  const LinkMessage._({
    super.id = '',
    super.roomId = '',
    super.senderId = '',
    super.createdAt = const ChatValueTimestamp(),
    super.updatedAt = const ChatValueTimestamp(),
    super.statuses = const {},
    super.deletes = const {},
    super.pins = const {},
    super.removes = const {},
    super.editedAt,
    super.replyId,
    super.reactions = const {},
    super.isDeleted = false,
    super.isEdited = false,
    super.isForwarded = false,
    super.extra = const {},
    this.link = '',
  }) : super(type: MessageType.link);

  const LinkMessage.empty() : this._();

  factory LinkMessage.create(
    String link, {
    String? roomId,
    MessageExtra? extra,
    String? id,
    String? senderId,
    String? replyId,
    ChatValueTimestamp? createdAt,
  }) {
    senderId ??= RoomManager.i.me;
    if (senderId.isEmpty) return LinkMessage.empty();
    id ??= ChatHelper.generateMessageId();
    createdAt ??= ChatValueTimestamp.now();
    return LinkMessage._(
      id: id,
      roomId: roomId ?? '',
      senderId: senderId,
      createdAt: createdAt,
      updatedAt: createdAt,
      statuses: {senderId: MessageStatus.sending},
      replyId: replyId,
      extra: extra ?? {},
      link: link,
    );
  }

  factory LinkMessage.from(Message msg, String link) {
    return LinkMessage._(
      id: msg.id,
      roomId: msg.roomId,
      senderId: msg.senderId,
      createdAt: msg.createdAt,
      updatedAt: msg.updatedAt,
      statuses: msg.statuses,
      deletes: msg.deletes,
      pins: msg.pins,
      removes: msg.removes,
      editedAt: msg.editedAt,
      replyId: msg.replyId,
      reactions: msg.reactions,
      isDeleted: msg.isDeleted,
      isEdited: msg.isEdited,
      isForwarded: msg.isForwarded,
      extra: msg.extra,
      link: link,
    );
  }

  @override
  LinkMessage copyWith({
    bool? isDeleted,
    bool? isDeletedForMe,
    bool? isEdited,
    bool? isForwarded,
    bool? isPinned,
    bool? isRemoved,
    String? id,
    String? roomId,
    String? senderId,
    String? replyId,
    String? react,
    ChatValueTimestamp? createdAt,
    ChatValueTimestamp? editedAt,
    ChatValueTimestamp? updatedAt,
    MessageStatus? status,
    MessageExtra? extra,
    String? link,
  }) {
    final msg = super.copyWith(
      isDeleted: isDeleted,
      isDeletedForMe: isDeletedForMe,
      isEdited: isEdited,
      isForwarded: isForwarded,
      isPinned: isPinned,
      isRemoved: isRemoved,
      id: id,
      roomId: roomId,
      senderId: senderId,
      replyId: replyId,
      react: react,
      createdAt: createdAt,
      editedAt: editedAt,
      updatedAt: updatedAt,
      status: status,
      extra: extra,
    );
    return LinkMessage.from(msg, link ?? this.link);
  }

  @override
  LinkMessage resolveWith(Map changes) {
    final msg = super.resolveWith(changes);
    final keys = MessageKeys.i;
    final link = changes[keys.content];
    return LinkMessage.from(
      msg,
      link is String && link.isNotEmpty ? link : this.link,
    );
  }

  @override
  Map<String, dynamic> get source {
    final keys = MessageKeys.i;
    return {...super.source, if (link.isNotEmpty) keys.content: link};
  }

  @override
  List<Object?> get props => [...super.props, link];

  @override
  String toString() => "$LinkMessage#$hashCode($link)";
}

class TextMessage extends Message {
  final String text;

  const TextMessage._({
    super.id = '',
    super.roomId = '',
    super.senderId = '',
    super.createdAt = const ChatValueTimestamp(),
    super.updatedAt = const ChatValueTimestamp(),
    super.statuses = const {},
    super.deletes = const {},
    super.pins = const {},
    super.removes = const {},
    super.editedAt,
    super.replyId,
    super.reactions = const {},
    super.isDeleted = false,
    super.isEdited = false,
    super.isForwarded = false,
    super.extra = const {},
    this.text = '',
  }) : super(type: MessageType.text);

  const TextMessage.empty() : this._();

  factory TextMessage.create(
    String text, {
    String? roomId,
    MessageExtra? extra,
    String? id,
    String? senderId,
    String? replyId,
    ChatValueTimestamp? createdAt,
  }) {
    senderId ??= RoomManager.i.me;
    if (senderId.isEmpty) return TextMessage.empty();
    id ??= ChatHelper.generateMessageId();
    createdAt ??= ChatValueTimestamp.now();
    return TextMessage._(
      id: id,
      roomId: roomId ?? '',
      senderId: senderId,
      createdAt: createdAt,
      updatedAt: createdAt,
      statuses: {senderId: MessageStatus.sending},
      replyId: replyId,
      extra: extra ?? {},
      text: text,
    );
  }

  factory TextMessage.from(Message msg, String text) {
    return TextMessage._(
      id: msg.id,
      roomId: msg.roomId,
      senderId: msg.senderId,
      createdAt: msg.createdAt,
      updatedAt: msg.updatedAt,
      statuses: msg.statuses,
      deletes: msg.deletes,
      pins: msg.pins,
      removes: msg.removes,
      editedAt: msg.editedAt,
      replyId: msg.replyId,
      reactions: msg.reactions,
      isDeleted: msg.isDeleted,
      isEdited: msg.isEdited,
      isForwarded: msg.isForwarded,
      extra: msg.extra,
      text: text,
    );
  }

  @override
  TextMessage copyWith({
    bool? isDeleted,
    bool? isDeletedForMe,
    bool? isEdited,
    bool? isForwarded,
    bool? isPinned,
    bool? isRemoved,
    String? id,
    String? roomId,
    String? senderId,
    String? replyId,
    String? react,
    ChatValueTimestamp? createdAt,
    ChatValueTimestamp? editedAt,
    ChatValueTimestamp? updatedAt,
    MessageStatus? status,
    MessageExtra? extra,
    String? text,
  }) {
    final msg = super.copyWith(
      isDeleted: isDeleted,
      isDeletedForMe: isDeletedForMe,
      isEdited: isEdited,
      isForwarded: isForwarded,
      isPinned: isPinned,
      isRemoved: isRemoved,
      id: id,
      roomId: roomId,
      senderId: senderId,
      replyId: replyId,
      react: react,
      createdAt: createdAt,
      editedAt: editedAt,
      updatedAt: updatedAt,
      status: status,
      extra: extra,
    );
    return TextMessage.from(msg, text ?? this.text);
  }

  @override
  TextMessage resolveWith(Map changes) {
    final msg = super.resolveWith(changes);
    final keys = MessageKeys.i;
    final text = changes[keys.content];
    return TextMessage.from(
      msg,
      text is String && text.isNotEmpty ? text : this.text,
    );
  }

  @override
  Map<String, dynamic> get source {
    final keys = MessageKeys.i;
    return {...super.source, if (text.isNotEmpty) keys.content: text};
  }

  @override
  List<Object?> get props => [...super.props, text];

  @override
  String toString() => "$TextMessage#$hashCode($text)";
}

class VideoMessage extends Message {
  final String? caption;
  final int durationInSec;
  final String thumbnail;
  final String url;

  Duration get duration => Duration(seconds: durationInSec);

  const VideoMessage._({
    super.id = '',
    super.roomId = '',
    super.senderId = '',
    super.createdAt = const ChatValueTimestamp(),
    super.updatedAt = const ChatValueTimestamp(),
    super.statuses = const {},
    super.deletes = const {},
    super.pins = const {},
    super.removes = const {},
    super.editedAt,
    super.replyId,
    super.reactions = const {},
    super.isDeleted = false,
    super.isEdited = false,
    super.isForwarded = false,
    super.extra = const {},
    this.caption,
    this.durationInSec = 0,
    this.thumbnail = '',
    this.url = '',
  }) : super(type: MessageType.video);

  const VideoMessage.empty() : this._();

  factory VideoMessage.create(
    String path,
    String thumbnail,
    int durationInSec, {
    String? roomId,
    String? caption,
    MessageExtra? extra,
    String? id,
    String? senderId,
    String? replyId,
    ChatValueTimestamp? createdAt,
  }) {
    senderId ??= RoomManager.i.me;
    if (senderId.isEmpty) return VideoMessage.empty();
    id ??= ChatHelper.generateMessageId();
    createdAt ??= ChatValueTimestamp.now();
    return VideoMessage._(
      id: id,
      roomId: roomId ?? '',
      senderId: senderId,
      createdAt: createdAt,
      updatedAt: createdAt,
      statuses: {senderId: MessageStatus.sending},
      replyId: replyId,
      extra: extra ?? {},
      caption: caption,
      durationInSec: durationInSec,
      thumbnail: thumbnail,
      url: path,
    );
  }

  factory VideoMessage.from(
    Message msg,
    String? caption,
    int durationInSec,
    String thumbnail,
    String url,
  ) {
    return VideoMessage._(
      id: msg.id,
      roomId: msg.roomId,
      senderId: msg.senderId,
      createdAt: msg.createdAt,
      updatedAt: msg.updatedAt,
      statuses: msg.statuses,
      deletes: msg.deletes,
      pins: msg.pins,
      removes: msg.removes,
      editedAt: msg.editedAt,
      replyId: msg.replyId,
      reactions: msg.reactions,
      isDeleted: msg.isDeleted,
      isEdited: msg.isEdited,
      isForwarded: msg.isForwarded,
      extra: msg.extra,
      caption: caption,
      durationInSec: durationInSec,
      thumbnail: thumbnail,
      url: url,
    );
  }

  @override
  VideoMessage copyWith({
    bool? isDeleted,
    bool? isDeletedForMe,
    bool? isEdited,
    bool? isForwarded,
    bool? isPinned,
    bool? isRemoved,
    String? id,
    String? roomId,
    String? senderId,
    String? replyId,
    String? react,
    ChatValueTimestamp? createdAt,
    ChatValueTimestamp? editedAt,
    ChatValueTimestamp? updatedAt,
    MessageStatus? status,
    MessageExtra? extra,
    int? durationInSec,
    String? caption,
    String? thumbnail,
    String? url,
  }) {
    final msg = super.copyWith(
      isDeleted: isDeleted,
      isDeletedForMe: isDeletedForMe,
      isEdited: isEdited,
      isForwarded: isForwarded,
      isPinned: isPinned,
      isRemoved: isRemoved,
      id: id,
      roomId: roomId,
      senderId: senderId,
      replyId: replyId,
      react: react,
      createdAt: createdAt,
      editedAt: editedAt,
      updatedAt: updatedAt,
      status: status,
      extra: extra,
    );
    return VideoMessage.from(
      msg,
      caption ?? this.caption,
      durationInSec ?? this.durationInSec,
      thumbnail ?? this.thumbnail,
      url ?? this.url,
    );
  }

  @override
  VideoMessage resolveWith(Map changes) {
    final msg = super.resolveWith(changes);
    final keys = MessageKeys.i;
    final caption = changes[keys.content];
    final durationInSec = changes[keys.durationInSec];
    final thumbnail = changes[keys.thumbnail];
    final url = changes[keys.url];
    return VideoMessage.from(
      msg,
      caption is String && caption.isNotEmpty ? caption : this.caption,
      durationInSec is num && durationInSec > 0
          ? durationInSec.toInt()
          : this.durationInSec,
      thumbnail is String && thumbnail.isNotEmpty ? thumbnail : this.thumbnail,
      url is String && url.isNotEmpty ? url : this.url,
    );
  }

  @override
  Map<String, dynamic> get source {
    final keys = MessageKeys.i;
    return {
      ...super.source,
      if (caption != null && caption!.isNotEmpty) keys.content: caption,
      if (durationInSec > 0) keys.durationInSec: durationInSec,
      if (thumbnail.isNotEmpty) keys.thumbnail: thumbnail,
      if (url.isNotEmpty) keys.url: url,
    };
  }

  @override
  List<Object?> get props {
    return [...super.props, caption, durationInSec, thumbnail, url];
  }

  @override
  String toString() => "$VideoMessage#$hashCode($url)";
}
