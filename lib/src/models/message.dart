import 'package:equatable/equatable.dart';

import '../managers/chat.dart';
import '../managers/room.dart';
import '../utils/chat_helper.dart';
import '../utils/enum_parser.dart';
import '../utils/field_value.dart';
import '../utils/parser.dart';

final class MessageKeys {
  const MessageKeys._();

  static const id = 'id';
  static const roomId = 'roomId';
  static const senderId = 'senderId';
  static const content = 'content';
  static const type = 'type';
  static const statuses = 'statuses';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
  static const urls = 'urls';
  static const url = 'url';
  static const replyId = 'replyId';
  static const reactions = 'reactions';
  static const pins = 'pins';
  static const durationInSec = 'durationInSec';
  static const thumbnail = 'thumbnail';
  static const deletes = 'deletes';
  static const removes = 'removes';
  static const isDeleted = 'isDeleted';
  static const isEdited = 'isEdited';
  static const editedAt = 'editedAt';
  static const isForwarded = 'isForwarded';
}

enum MessageType { none, audio, image, link, text, video }

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

  final bool isDeleted;
  final bool isEdited;
  final bool isForwarded;

  bool get isDeletedByMe => deletes[me] ?? false;

  bool get isRemovedByMe => removes[me] ?? false;

  bool get isReactedByMe {
    final x = reactByMe;
    return x != null && x.isNotEmpty;
  }

  bool get isRemovable => isDeleted || isDeletedByMe;

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
    final msg = ChatManager.i.mappedMessages[replyId];
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
    final isMe = senderId == me && !notification;

    String body = '${isMe ? "You" : "{SENDER}"} sent a message';

    if (edited) {
      body = "${isMe ? "You" : "{SENDER}"} edited a message";
    } else if (deleted) {
      body = "${isMe ? "You" : "{SENDER}"} deleted a message";
    } else {
      if (msg is TextMessage) {
        body = isMe
            ? 'You: ${msg.text}'
            : notification
                ? msg.text
                : "{SENDER_FOR_YOU}${msg.text}";
      } else if (msg is ImageMessage) {
        body =
            '${isMe ? "You" : "{SENDER}"} sent ${msg.urls.length > 1 ? 'photos' : 'a photo'}';
      } else if (msg is VideoMessage) {
        body = '${isMe ? "You" : "{SENDER}"} sent a video';
      } else if (msg is AudioMessage) {
        body = '${isMe ? "You" : "{SENDER}"} sent a voice message';
      } else if (msg is LinkMessage) {
        body = '${isMe ? "You" : "{SENDER}"} sent a link';
      }
    }
    if (sender != null && sender.isNotEmpty) {
      return body.replaceAll("{SENDER}", sender);
    }
    return body;
  }

  String notificationBody(String sender) {
    final body = lastMessage(senderId: me, sender: sender, notification: true);
    return body;
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
    );
  }

  factory Message.parse(Object? source) {
    if (source is Message) return source;
    if (source is! Map) return Message.empty();
    final id = source[MessageKeys.id];
    final roomId = source[MessageKeys.roomId];
    final senderId = source[MessageKeys.senderId];
    final type = source[MessageKeys.type];
    final statuses = source[MessageKeys.statuses];
    final createdAt = source[MessageKeys.createdAt];
    final updatedAt = source[MessageKeys.updatedAt];
    final replyId = source[MessageKeys.replyId];
    final reactions = source[MessageKeys.reactions];
    final pins = source[MessageKeys.pins];
    final deletes = source[MessageKeys.deletes];
    final removes = source[MessageKeys.removes];
    final isDeleted = source[MessageKeys.isDeleted];
    final isEdited = source[MessageKeys.isEdited];
    final editedAt = source[MessageKeys.editedAt];
    final isForwarded = source[MessageKeys.isForwarded];

    final content = source[MessageKeys.content];
    final url = source[MessageKeys.url];
    final duration = source[MessageKeys.durationInSec];

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
    );

    final mContent = content is String && content.isNotEmpty ? content : null;
    final mDuration = duration is num && duration > 0 ? duration.toInt() : null;
    final mUrl = url is String && url.isNotEmpty ? url : null;

    switch (msg.type) {
      case MessageType.none:
        return Message.empty();
      case MessageType.audio:
        if (mDuration == null || mUrl == null) return Message.empty();
        return AudioMessage.from(msg, mDuration, mUrl);
      case MessageType.image:
        final urls = source[MessageKeys.urls];
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
        final t = source[MessageKeys.thumbnail];
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
    String? react,
    ChatValueTimestamp? createdAt,
    ChatValueTimestamp? editedAt,
    ChatValueTimestamp? updatedAt,
    MessageStatus? status,
  }) {
    final deletes = this.deletes;
    if (isDeletedForMe == true) deletes[me] = true;

    final pins = this.pins;
    if (isPinned == true) {
      pins[me] = true;
    } else {
      if (pins.containsKey(me)) pins.remove(me);
    }

    final removes = this.removes;
    if (isRemoved == true) removes[me] = true;

    final reactions = this.reactions;
    if (react != null) {
      reactions[me] = react;
    } else {
      if (reactions.containsKey(me)) {
        reactions.remove(me);
      }
    }

    final statuses = this.statuses;
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
      replyId: replyId,
      reactions: reactions,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      isForwarded: isForwarded ?? this.isForwarded,
      pins: pins,
      removes: removes,
      type: type,
    );
  }

  Map<String, dynamic> get source {
    return {
      if (id.isNotEmpty) MessageKeys.id: id,
      if (roomId.isNotEmpty) MessageKeys.roomId: roomId,
      if (senderId.isNotEmpty) MessageKeys.senderId: senderId,
      if (type != MessageType.none) MessageKeys.type: type.name,
      if (!createdAt.isEmpty) MessageKeys.createdAt: createdAt,
      if (!updatedAt.isEmpty) MessageKeys.updatedAt: updatedAt,
      if (statuses.isNotEmpty)
        MessageKeys.statuses: statuses.map((k, v) => MapEntry(k, v.name)),
      if (deletes.isNotEmpty) MessageKeys.deletes: deletes,
      if (removes.isNotEmpty) MessageKeys.removes: removes,
      if (!editedAt.isEmpty) MessageKeys.editedAt: editedAt,
      if (reactions.isNotEmpty) MessageKeys.reactions: reactions,
      if (replyId.isNotEmpty) MessageKeys.replyId: replyId,
      if (isDeleted) MessageKeys.isDeleted: isDeleted,
      if (isEdited) MessageKeys.isEdited: isEdited,
      if (isForwarded) MessageKeys.isForwarded: isForwarded,
      if (pins.isNotEmpty) MessageKeys.pins: pins,
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
    ];
  }
}

class AudioMessage extends Message {
  final int durationInSec;
  final String url;

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
    this.durationInSec = 0,
    this.url = '',
  }) : super(type: MessageType.audio);

  const AudioMessage.empty() : this._();

  factory AudioMessage.create(
    String path,
    int durationInSec, {
    String? id,
    String? roomId,
    String? senderId,
    String? replyId,
    ChatValueTimestamp? createdAt,
  }) {
    senderId ??= RoomManager.i.me;
    if (senderId.isEmpty) return AudioMessage.empty();
    id ??= ChatHelper.generateMessageId();
    roomId ??= ChatManager.i.roomId;
    replyId ??= ChatManager.i.replyMsg?.id;
    createdAt ??= ChatValueTimestamp.now();
    return AudioMessage._(
      id: id,
      roomId: roomId,
      senderId: senderId,
      replyId: replyId,
      createdAt: createdAt,
      updatedAt: createdAt,
      durationInSec: durationInSec,
      url: path,
      statuses: {senderId: MessageStatus.sending},
    );
  }

  factory AudioMessage.from(Message msg, int durationInSec, String url) {
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
      durationInSec: durationInSec,
      url: url,
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
    String? react,
    ChatValueTimestamp? createdAt,
    ChatValueTimestamp? editedAt,
    ChatValueTimestamp? updatedAt,
    MessageStatus? status,
    int? durationInSec,
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
      react: react,
      createdAt: createdAt,
      editedAt: editedAt,
      updatedAt: updatedAt,
      status: status,
    );
    return AudioMessage._(
      id: msg.id,
      roomId: msg.roomId,
      senderId: msg.senderId,
      createdAt: msg.createdAt,
      statuses: msg.statuses,
      deletes: msg.deletes,
      pins: msg.pins,
      removes: msg.removes,
      editedAt: msg.editedAt,
      updatedAt: msg.updatedAt,
      replyId: msg.replyId,
      reactions: msg.reactions,
      isDeleted: msg.isDeleted,
      isEdited: msg.isEdited,
      isForwarded: msg.isForwarded,
      durationInSec: durationInSec ?? this.durationInSec,
      url: url ?? this.url,
    );
  }

  @override
  Map<String, dynamic> get source {
    return {
      ...super.source,
      if (durationInSec > 0) MessageKeys.durationInSec: durationInSec,
      if (url.isNotEmpty) MessageKeys.url: url,
    };
  }

  @override
  List<Object?> get props => [...super.props, durationInSec, url];

  @override
  String toString() => "$AudioMessage#$hashCode($url)";
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
    this.caption,
    this.urls = const [],
  }) : super(type: MessageType.image);

  const ImageMessage.empty() : this._();

  factory ImageMessage.create(
    List<String> paths,
    String? caption, {
    String? id,
    String? roomId,
    String? senderId,
    String? replyId,
    ChatValueTimestamp? createdAt,
  }) {
    senderId ??= RoomManager.i.me;
    if (senderId.isEmpty) return ImageMessage.empty();
    id ??= ChatHelper.generateMessageId();
    roomId ??= ChatManager.i.roomId;
    replyId ??= ChatManager.i.replyMsg?.id;
    createdAt ??= ChatValueTimestamp.now();
    return ImageMessage._(
      id: id,
      roomId: roomId,
      senderId: senderId,
      createdAt: createdAt,
      updatedAt: createdAt,
      statuses: {senderId: MessageStatus.sending},
      replyId: replyId,
      caption: caption,
      urls: paths,
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
    String? react,
    ChatValueTimestamp? createdAt,
    ChatValueTimestamp? editedAt,
    ChatValueTimestamp? updatedAt,
    MessageStatus? status,
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
      react: react,
      createdAt: createdAt,
      editedAt: editedAt,
      updatedAt: updatedAt,
      status: status,
    );
    return ImageMessage._(
      id: msg.id,
      roomId: msg.roomId,
      senderId: msg.senderId,
      createdAt: msg.createdAt,
      statuses: msg.statuses,
      deletes: msg.deletes,
      pins: msg.pins,
      removes: msg.removes,
      editedAt: msg.editedAt,
      updatedAt: msg.updatedAt,
      replyId: msg.replyId,
      reactions: msg.reactions,
      isDeleted: msg.isDeleted,
      isEdited: msg.isEdited,
      isForwarded: msg.isForwarded,
      caption: caption ?? this.caption,
      urls: urls ?? this.urls,
    );
  }

  @override
  Map<String, dynamic> get source {
    return {
      ...super.source,
      if (caption != null && caption!.isNotEmpty) MessageKeys.content: caption,
      if (urls.isNotEmpty) MessageKeys.urls: urls,
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
    this.link = '',
  }) : super(type: MessageType.link);

  const LinkMessage.empty() : this._();

  factory LinkMessage.create(
    String link, {
    String? roomId,
    String? id,
    String? senderId,
    String? replyId,
    ChatValueTimestamp? createdAt,
  }) {
    senderId ??= RoomManager.i.me;
    if (senderId.isEmpty) return LinkMessage.empty();
    id ??= ChatHelper.generateMessageId();
    roomId ??= ChatManager.i.roomId;
    replyId ??= ChatManager.i.replyMsg?.id;
    createdAt ??= ChatValueTimestamp.now();
    return LinkMessage._(
      id: id,
      roomId: roomId,
      senderId: senderId,
      createdAt: createdAt,
      updatedAt: createdAt,
      statuses: {senderId: MessageStatus.sending},
      replyId: replyId,
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
    String? react,
    ChatValueTimestamp? createdAt,
    ChatValueTimestamp? editedAt,
    ChatValueTimestamp? updatedAt,
    MessageStatus? status,
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
      react: react,
      createdAt: createdAt,
      editedAt: editedAt,
      updatedAt: updatedAt,
      status: status,
    );
    return LinkMessage._(
      id: msg.id,
      roomId: msg.roomId,
      senderId: msg.senderId,
      createdAt: msg.createdAt,
      statuses: msg.statuses,
      deletes: msg.deletes,
      pins: msg.pins,
      removes: msg.removes,
      editedAt: msg.editedAt,
      updatedAt: msg.updatedAt,
      replyId: msg.replyId,
      reactions: msg.reactions,
      isDeleted: msg.isDeleted,
      isEdited: msg.isEdited,
      isForwarded: msg.isForwarded,
      link: link ?? this.link,
    );
  }

  @override
  Map<String, dynamic> get source {
    return {...super.source, if (link.isNotEmpty) MessageKeys.content: link};
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
    this.text = '',
  }) : super(type: MessageType.text);

  const TextMessage.empty() : this._();

  factory TextMessage.create(
    String text, {
    String? roomId,
    String? id,
    String? senderId,
    String? replyId,
    ChatValueTimestamp? createdAt,
  }) {
    senderId ??= RoomManager.i.me;
    if (senderId.isEmpty) return TextMessage.empty();
    id ??= ChatHelper.generateMessageId();
    roomId ??= ChatManager.i.roomId;
    replyId ??= ChatManager.i.replyMsg?.id;
    createdAt ??= ChatValueTimestamp.now();
    return TextMessage._(
      id: id,
      roomId: roomId,
      senderId: senderId,
      createdAt: createdAt,
      updatedAt: createdAt,
      statuses: {senderId: MessageStatus.sending},
      replyId: replyId,
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
    String? react,
    ChatValueTimestamp? createdAt,
    ChatValueTimestamp? editedAt,
    ChatValueTimestamp? updatedAt,
    MessageStatus? status,
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
      react: react,
      createdAt: createdAt,
      editedAt: editedAt,
      updatedAt: updatedAt,
      status: status,
    );
    return TextMessage._(
      id: msg.id,
      roomId: msg.roomId,
      senderId: msg.senderId,
      createdAt: msg.createdAt,
      statuses: msg.statuses,
      deletes: msg.deletes,
      pins: msg.pins,
      removes: msg.removes,
      editedAt: msg.editedAt,
      updatedAt: msg.updatedAt,
      replyId: msg.replyId,
      reactions: msg.reactions,
      isDeleted: msg.isDeleted,
      isEdited: msg.isEdited,
      isForwarded: msg.isForwarded,
      text: text ?? this.text,
    );
  }

  @override
  Map<String, dynamic> get source {
    return {...super.source, if (text.isNotEmpty) MessageKeys.content: text};
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
    this.caption,
    this.durationInSec = 0,
    this.thumbnail = '',
    this.url = '',
  }) : super(type: MessageType.video);

  const VideoMessage.empty() : this._();

  factory VideoMessage.create(
    String path,
    String thumbnail,
    int durationInSec,
    String? caption, {
    String? roomId,
    String? id,
    String? senderId,
    String? replyId,
    ChatValueTimestamp? createdAt,
  }) {
    senderId ??= RoomManager.i.me;
    if (senderId.isEmpty) return VideoMessage.empty();
    id ??= ChatHelper.generateMessageId();
    roomId ??= ChatManager.i.roomId;
    replyId ??= ChatManager.i.replyMsg?.id;
    createdAt ??= ChatValueTimestamp.now();
    return VideoMessage._(
      id: id,
      roomId: roomId,
      senderId: senderId,
      createdAt: createdAt,
      updatedAt: createdAt,
      statuses: {senderId: MessageStatus.sending},
      replyId: replyId,
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
    String? react,
    ChatValueTimestamp? createdAt,
    ChatValueTimestamp? editedAt,
    ChatValueTimestamp? updatedAt,
    MessageStatus? status,
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
      react: react,
      createdAt: createdAt,
      editedAt: editedAt,
      updatedAt: updatedAt,
      status: status,
    );
    return VideoMessage._(
      id: msg.id,
      roomId: msg.roomId,
      senderId: msg.senderId,
      createdAt: msg.createdAt,
      statuses: msg.statuses,
      deletes: msg.deletes,
      pins: msg.pins,
      removes: msg.removes,
      editedAt: msg.editedAt,
      updatedAt: msg.updatedAt,
      replyId: msg.replyId,
      reactions: msg.reactions,
      isDeleted: msg.isDeleted,
      isEdited: msg.isEdited,
      isForwarded: msg.isForwarded,
      caption: caption ?? this.caption,
      thumbnail: thumbnail ?? this.thumbnail,
      durationInSec: durationInSec ?? this.durationInSec,
      url: url ?? this.url,
    );
  }

  @override
  Map<String, dynamic> get source {
    return {
      ...super.source,
      if (caption != null && caption!.isNotEmpty) MessageKeys.content: caption,
      if (durationInSec > 0) MessageKeys.durationInSec: durationInSec,
      if (thumbnail.isNotEmpty) MessageKeys.thumbnail: thumbnail,
      if (url.isNotEmpty) MessageKeys.url: url,
    };
  }

  @override
  List<Object?> get props {
    return [...super.props, caption, durationInSec, thumbnail, url];
  }

  @override
  String toString() => "$VideoMessage#$hashCode($url)";
}
