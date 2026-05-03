import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../core/chat_manager.dart';
import '../core/room_manager.dart';
import '../utils/chat_helper.dart';
import '../utils/enum_parser.dart';
import '../utils/field_value.dart';
import '../utils/parser.dart';

typedef MessageExtra = Map<String, dynamic>;

// ── Keys ──────────────────────────────────────────────────────────────────────

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

// ── Enums ─────────────────────────────────────────────────────────────────────

enum MessageType { none, audio, custom, image, link, text, video }

enum MessageStatus {
  none,
  sending,
  retrying,
  failed,
  sent,
  delivered,
  seen,
  deleting,
}

// ── Message ───────────────────────────────────────────────────────────────────

class Message extends Equatable {
  // ── Mandatory Fields ──────────────────────────────────────────────────────

  final String id;
  final String roomId;
  final String senderId;
  final ChatValueTimestamp createdAt;
  final ChatValueTimestamp updatedAt;
  final MessageType type;
  final Map<String, MessageStatus> statuses;

  // ── Optional Fields ───────────────────────────────────────────────────────

  final Map<String, bool> deletes;
  final Map<String, bool> removes;
  final Map<String, bool> pins;
  final Map<String, String> reactions;
  final ChatValueTimestamp editedAt;
  final String replyId;
  final MessageExtra extra;

  final bool isDeleted;
  final bool isEdited;
  final bool isForwarded;

  // ── Getters ───────────────────────────────────────────────────────────────

  String get me => RoomManager.i.me;

  String? get reactByMe => reactions[me];

  bool get isDeletedByMe => deletes[me] ?? false;

  bool get isRemovedByMe => removes[me] ?? false;

  bool get isPinned => pins[me] ?? false;

  bool get isSentByMe => senderId == me;

  bool get isReactedByMe => reactByMe?.isNotEmpty ?? false;

  bool get shouldRemove => isDeleted || isDeletedByMe;

  bool get isSending {
    if (statuses.isEmpty || statuses.length > 1) return false;
    final s = statusFor(me);
    return s == MessageStatus.sending || s == MessageStatus.retrying;
  }

  bool get isRetrying {
    if (statuses.isEmpty || statuses.length > 1) return false;
    return statusFor(me) == MessageStatus.retrying;
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

  String? get content => switch (this) {
    ImageMessage m => m.caption,
    LinkMessage m => m.link,
    TextMessage m => m.text,
    VideoMessage m => m.caption,
    _ => null,
  };

  Message get replyMessage {
    final msg = ChatManager.ofOrNull(roomId)?.mappedMessages[replyId];
    return msg ?? const Message.empty();
  }

  MessageStatus get status {
    if (isSending) return MessageStatus.sending;
    final participants = RoomManager.i.room(roomId).participants;
    if (isSeen(participants)) return MessageStatus.seen;
    if (isDelivered(participants)) return MessageStatus.delivered;
    return MessageStatus.sent;
  }

  MessageStatus statusFor(String uid) => statuses[uid] ?? MessageStatus.none;

  // ── Status Checks ────────────────────────────────────────────────────────

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
      return statuses[e] == MessageStatus.seen;
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<String> findPathOrUrls([bool thumbnail = false]) => switch (this) {
    AudioMessage m => [m.url],
    ImageMessage m => m.urls,
    VideoMessage m => [m.url, if (thumbnail) m.thumbnail],
    _ => [],
  };

  String lastMessage({bool edited = false, bool deleted = false}) {
    if (edited) return '{SENDER} edited a message';
    if (deleted) return '{SENDER} deleted a message';

    return switch (this) {
      TextMessage m => '{SENDER_OR_EMPTY}${m.text}',
      ImageMessage m =>
        '{SENDER} sent ${m.urls.length > 1 ? 'photos' : 'a photo'}',
      VideoMessage _ => '{SENDER} sent a video',
      AudioMessage _ => '{SENDER} sent a voice message',
      LinkMessage _ => '{SENDER} sent a link',
      _ => '{SENDER} sent a message',
    };
  }

  String notificationBody(String? sender) {
    final actor = (sender != null && sender.isNotEmpty) ? sender : 'Someone';
    return switch (this) {
      TextMessage m => m.text,
      ImageMessage m =>
        '$actor sent ${m.urls.length > 1 ? 'photos' : 'a photo'}',
      VideoMessage _ => '$actor sent a video',
      AudioMessage _ => '$actor sent a voice message',
      LinkMessage _ => '$actor sent a link',
      _ => '$actor sent a message',
    };
  }

  // ── Constructor ───────────────────────────────────────────────────────────

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
    required this.reactions,
    required this.isDeleted,
    required this.isEdited,
    required this.isForwarded,
    required this.extra,
    required ChatValueTimestamp? editedAt,
    required String? replyId,
  }) : editedAt = editedAt ?? const ChatValueTimestamp(),
       replyId = replyId ?? '';

  // ── Factories ─────────────────────────────────────────────────────────────

  const Message.empty()
    : this(
        id: '',
        roomId: '',
        senderId: '',
        createdAt: const ChatValueTimestamp(),
        updatedAt: const ChatValueTimestamp(),
        type: MessageType.none,
        statuses: const {},
        deletes: const {},
        pins: const {},
        removes: const {},
        editedAt: const ChatValueTimestamp(),
        replyId: null,
        reactions: const {},
        isDeleted: false,
        isEdited: false,
        isForwarded: false,
        extra: const {},
      );

  factory Message.parse(Object? source, {MessageExtra? extra}) {
    if (source is Message) return source;
    if (source is! Map) return Message.empty();

    final keys = MessageKeys.i;

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
    final ex = source[keys.extra];
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

    return switch (msg.type) {
      MessageType.none => const Message.empty(),
      MessageType.text =>
        mContent == null
            ? const Message.empty()
            : TextMessage.from(msg, mContent),
      MessageType.link =>
        mContent == null
            ? const Message.empty()
            : LinkMessage.from(msg, mContent),
      MessageType.image => _parseImage(msg, source, keys, mContent),
      MessageType.audio => _parseAudio(msg, source, keys, mDuration, mUrl),
      MessageType.video => _parseVideo(
        msg,
        source,
        keys,
        mContent,
        mDuration,
        mUrl,
      ),
      MessageType.custom => _parseCustom(msg, source, keys),
    };
  }

  static Message _parseImage(
    Message msg,
    Map source,
    MessageKeys keys,
    String? caption,
  ) {
    final urls = source[keys.urls];
    final mUrls =
        urls is List && urls.isNotEmpty
            ? urls.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
            : <String>[];
    if (mUrls.isEmpty) return const Message.empty();
    return ImageMessage.from(msg, caption, mUrls);
  }

  static Message _parseAudio(
    Message msg,
    Map source,
    MessageKeys keys,
    int? duration,
    String? url,
  ) {
    if (duration == null || url == null) return const Message.empty();
    final waveforms = source[keys.waveform];
    final mWaveform = _tryDecodeJson(waveforms);
    return AudioMessage.from(
      msg,
      duration,
      url,
      mWaveform is Iterable ? mWaveform.parsedDoubles.toList() : [],
    );
  }

  static Message _parseVideo(
    Message msg,
    Map source,
    MessageKeys keys,
    String? caption,
    int? duration,
    String? url,
  ) {
    final t = source[keys.thumbnail];
    final mT = t is String && t.isNotEmpty ? t : null;
    if (duration == null || url == null || mT == null) {
      return const Message.empty();
    }
    return VideoMessage.from(msg, caption, duration, mT, url);
  }

  static Message _parseCustom(Message msg, Map source, MessageKeys keys) {
    final data = source[keys.data];
    final kind = source[keys.kind];
    final mKind = kind is String && kind.isNotEmpty ? kind : '';
    if (mKind.isEmpty) return const Message.empty();
    return CustomMessage.from(msg, data is Map ? data : {}, mKind);
  }

  static Object? _tryDecodeJson(Object? raw) {
    if (raw is! String) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  // ── CopyWith ──────────────────────────────────────────────────────────────

  Message copyWith({
    bool? isDeleted,
    bool? isDeletedForMe,
    bool? isEdited,
    bool? isForwarded,
    bool? isPinned,
    bool? isRemoved,
    bool clearReplyId = false,
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

    final removes = Map<String, bool>.from(this.removes);
    if (isRemoved == true) removes[me] = true;

    final pins = Map<String, bool>.from(this.pins);
    if (isPinned != null) {
      if (isPinned) {
        pins[me] = true;
      } else {
        pins.remove(me);
      }
    }

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
      updatedAt: updatedAt ?? this.updatedAt,
      editedAt: editedAt ?? this.editedAt,
      replyId: clearReplyId ? null : (replyId ?? this.replyId),
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      isForwarded: isForwarded ?? this.isForwarded,
      extra: extra ?? this.extra,
      type: type,
      statuses: statuses,
      deletes: deletes,
      removes: removes,
      pins: pins,
      reactions: reactions,
    );
  }

  // ── ResolveWith ───────────────────────────────────────────────────────────

  Message resolveWith(Map changes) {
    final keys = MessageKeys.i;

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
    final extra = changes[keys.extra];

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
      reactions:
          reactions is Map
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

  // ── Source ────────────────────────────────────────────────────────────────

  Map<String, dynamic> get source {
    final keys = MessageKeys.i;
    return {
      if (id.isNotEmpty) keys.id: id,
      if (roomId.isNotEmpty) keys.roomId: roomId,
      if (senderId.isNotEmpty) keys.senderId: senderId,
      if (type != MessageType.none) keys.type: type.name,
      if (!createdAt.isEmpty) keys.createdAt: createdAt,
      if (!updatedAt.isEmpty) keys.updatedAt: updatedAt,
      if (!editedAt.isEmpty) keys.editedAt: editedAt,
      if (replyId.isNotEmpty) keys.replyId: replyId,
      if (statuses.isNotEmpty)
        keys.statuses: statuses.map((k, v) => MapEntry(k, v.name)),
      if (deletes.isNotEmpty) keys.deletes: deletes,
      if (removes.isNotEmpty) keys.removes: removes,
      if (reactions.isNotEmpty) keys.reactions: reactions,
      if (pins.isNotEmpty) keys.pins: pins,
      if (extra.isNotEmpty) keys.extra: extra,
      if (isDeleted) keys.isDeleted: isDeleted,
      if (isEdited) keys.isEdited: isEdited,
      if (isForwarded) keys.isForwarded: isForwarded,
    };
  }

  // ── Equatable ─────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [
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

// ── AudioMessage ──────────────────────────────────────────────────────────────

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
    if (senderId.isEmpty) return const AudioMessage.empty();
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
      statuses: {senderId: MessageStatus.sending},
      durationInSec: durationInSec,
      url: path,
      waveform: waveform,
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
    bool clearReplyId = false,
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
    return AudioMessage.from(
      super.copyWith(
        isDeleted: isDeleted,
        isDeletedForMe: isDeletedForMe,
        isEdited: isEdited,
        isForwarded: isForwarded,
        isPinned: isPinned,
        isRemoved: isRemoved,
        clearReplyId: clearReplyId,
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
      ),
      durationInSec ?? this.durationInSec,
      url ?? this.url,
      waveform ?? this.waveform,
    );
  }

  @override
  AudioMessage resolveWith(Map changes) {
    final keys = MessageKeys.i;
    final msg = super.resolveWith(changes);
    final duration = changes[keys.durationInSec];
    final url = changes[keys.url];
    final waveform = changes[keys.waveform];
    final mWaveform = Message._tryDecodeJson(waveform);
    return AudioMessage.from(
      msg,
      duration is num && duration > 0 ? duration.toInt() : durationInSec,
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
  String toString() => '$AudioMessage#$hashCode($durationInSec)';
}

// ── CustomMessage ─────────────────────────────────────────────────────────────

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
    if (senderId.isEmpty) return const CustomMessage.empty();
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
      statuses: {senderId: MessageStatus.sending},
      data: data,
      kind: kind,
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
    bool clearReplyId = false,
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
    return CustomMessage.from(
      super.copyWith(
        isDeleted: isDeleted,
        isDeletedForMe: isDeletedForMe,
        isEdited: isEdited,
        isForwarded: isForwarded,
        isPinned: isPinned,
        isRemoved: isRemoved,
        clearReplyId: clearReplyId,
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
      ),
      data ?? this.data,
      kind ?? this.kind,
    );
  }

  @override
  CustomMessage resolveWith(Map changes) {
    final keys = MessageKeys.i;
    final msg = super.resolveWith(changes);
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
  String toString() => '$CustomMessage#$hashCode($kind)';
}

// ── ImageMessage ──────────────────────────────────────────────────────────────

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
    if (senderId.isEmpty) return const ImageMessage.empty();
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
    bool clearReplyId = false,
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
    return ImageMessage.from(
      super.copyWith(
        isDeleted: isDeleted,
        isDeletedForMe: isDeletedForMe,
        isEdited: isEdited,
        isForwarded: isForwarded,
        isPinned: isPinned,
        isRemoved: isRemoved,
        clearReplyId: clearReplyId,
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
      ),
      caption ?? this.caption,
      urls ?? this.urls,
    );
  }

  @override
  ImageMessage resolveWith(Map changes) {
    final keys = MessageKeys.i;
    final msg = super.resolveWith(changes);
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
  String toString() => '$ImageMessage#$hashCode($urls)';
}

// ── LinkMessage ───────────────────────────────────────────────────────────────

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
    if (senderId.isEmpty) return const LinkMessage.empty();
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
    bool clearReplyId = false,
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
    return LinkMessage.from(
      super.copyWith(
        isDeleted: isDeleted,
        isDeletedForMe: isDeletedForMe,
        isEdited: isEdited,
        isForwarded: isForwarded,
        isPinned: isPinned,
        isRemoved: isRemoved,
        clearReplyId: clearReplyId,
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
      ),
      link ?? this.link,
    );
  }

  @override
  LinkMessage resolveWith(Map changes) {
    final keys = MessageKeys.i;
    final msg = super.resolveWith(changes);
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
  String toString() => '$LinkMessage#$hashCode($link)';
}

// ── TextMessage ───────────────────────────────────────────────────────────────

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
    if (senderId.isEmpty) return const TextMessage.empty();
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
    bool clearReplyId = false,
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
    return TextMessage.from(
      super.copyWith(
        isDeleted: isDeleted,
        isDeletedForMe: isDeletedForMe,
        isEdited: isEdited,
        isForwarded: isForwarded,
        isPinned: isPinned,
        isRemoved: isRemoved,
        clearReplyId: clearReplyId,
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
      ),
      text ?? this.text,
    );
  }

  @override
  TextMessage resolveWith(Map changes) {
    final keys = MessageKeys.i;
    final msg = super.resolveWith(changes);
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
  String toString() => '$TextMessage#$hashCode($text)';
}

// ── VideoMessage ──────────────────────────────────────────────────────────────

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
    if (senderId.isEmpty) return const VideoMessage.empty();
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
    bool clearReplyId = false,
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
    return VideoMessage.from(
      super.copyWith(
        isDeleted: isDeleted,
        isDeletedForMe: isDeletedForMe,
        isEdited: isEdited,
        isForwarded: isForwarded,
        isPinned: isPinned,
        isRemoved: isRemoved,
        clearReplyId: clearReplyId,
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
      ),
      caption ?? this.caption,
      durationInSec ?? this.durationInSec,
      thumbnail ?? this.thumbnail,
      url ?? this.url,
    );
  }

  @override
  VideoMessage resolveWith(Map changes) {
    final keys = MessageKeys.i;
    final msg = super.resolveWith(changes);
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
  List<Object?> get props => [
    ...super.props,
    caption,
    durationInSec,
    thumbnail,
    url,
  ];

  @override
  String toString() => '$VideoMessage#$hashCode($url)';
}
