import 'package:equatable/equatable.dart';

import '../managers/room.dart';
import '../utils/field_value.dart';
import '../utils/parser.dart';
import 'message.dart';

typedef RoomExtra = Map<String, dynamic>;

final class RoomKeys {
  const RoomKeys._();

  static const id = 'id';
  static const friendId = 'friendId';
  static const participants = 'participants';
  static const leaves = 'leaves';
  static const createdAt = 'createdAt';
  static const createdBy = 'createdBy';
  static const name = 'name';
  static const photo = 'photo';
  static const isGroup = 'isGroup';
  static const isDeleted = 'isDeleted';
  static const lastMessage = 'lastMessage';
  static const lastMessageId = 'lastMessageId';
  static const lastMessageSenderId = 'lastMessageSenderId';
  static const lastMessageDeleted = 'lastMessageDeletedForEveryone';
  static const lastMessageStatuses = 'lastMessageStatuses';
  static const unseenCount = 'unseenCount';
  static const updatedAt = 'updatedAt';
  static const mutes = 'mutes';
  static const blocks = 'blocks';
  static const pins = 'pins';
  static const extra = 'extra';
}

class Room extends Equatable {
  final bool isLocal;
  final bool isGroup;
  final bool isDeleted;
  final String id;
  final ChatValueTimestamp createdAt;
  final String createdBy;
  final Set<String> participants;
  final Set<String> leaves;
  final Set<String> blocks;
  final Map<String, bool> mutes;
  final Map<String, bool> pins;
  final RoomExtra extra;

  final String? lastMessage;
  final String lastMessageId;
  final String lastMessageSenderId;
  final bool lastMessageDeleted;
  final Map<String, MessageStatus> lastMessageStatuses;
  final Map<String, int> _unseenCount;
  final ChatValueTimestamp updatedAt;

  bool get isEmpty => id.isEmpty || participants.isEmpty;

  bool get isSentByMe => lastMessageSenderId == me;

  bool get isLeaveByMe => isDeleted || leaves.contains(me);

  bool get isBlockByMe => blocks.contains(me);

  bool get isMutedByMe => isMuted(me);

  bool get isPinnedByMe => isPinned(me);

  bool get isAdminByMe => createdBy == me;

  bool get isDisabledToSend => isLeaveByMe || isBlockByMe;

  int get unseenCount {
    final count = _unseenCount[me];
    return count ?? 0;
  }

  String get me => RoomManager.i.me;

  String? get lastMessageStatus {
    return lastMessageStatuses[me]?.name;
  }

  String formattedLastMessage({String? sender, bool isTyping = false}) {
    if (isTyping) {
      return 'Typing...';
    }
    final isMe = lastMessageSenderId == me;
    if (isMe && lastMessageStatus == 'sending') {
      return 'Sending...';
    }
    sender ??= RoomManager.i.mappedProfiles[lastMessageSenderId]?.name ?? '';
    if (lastMessageDeleted) {
      return '${isMe ? 'You' : sender} deleted a message';
    }
    final msg = lastMessage ?? '';
    return msg
        .replaceAll("{SENDER}", isMe ? "You" : sender)
        .replaceAll('{SENDER_FOR_YOU}', isMe ? "You: " : '');
  }

  bool isMuted(String uid) {
    if (uid.isEmpty) return false;
    return mutes[uid] ?? false;
  }

  bool isPinned(String uid) {
    if (uid.isEmpty) return false;
    return pins[uid] ?? false;
  }

  const Room.empty() : this();

  const Room({
    this.isLocal = false,
    this.isDeleted = false,
    this.isGroup = false,
    this.id = '',
    this.createdAt = const ChatValueTimestamp(),
    this.createdBy = '',
    this.participants = const {},
    this.leaves = const {},
    this.blocks = const {},
    this.mutes = const {},
    this.pins = const {},
    this.extra = const {},
    this.lastMessage,
    this.lastMessageId = '',
    this.lastMessageSenderId = '',
    this.lastMessageDeleted = false,
    this.lastMessageStatuses = const {},
    Map<String, int> unseenCount = const {},
    this.updatedAt = const ChatValueTimestamp(),
  }) : _unseenCount = unseenCount;

  factory Room.parse(Object? source, {RoomExtra? extra}) {
    if (source is Room) return source;
    if (source is! Map) return Room.empty();
    final isGroup = source[RoomKeys.isGroup];
    if (isGroup is! bool) return Room.empty();

    final ex = source[RoomKeys.extra];

    final isDeleted = source[RoomKeys.isDeleted];
    final createdAt = source[RoomKeys.createdAt];
    final createdBy = source[RoomKeys.createdBy];
    final id = source[RoomKeys.id];

    final lastMessage = source[RoomKeys.lastMessage];
    final lastMessageId = source[RoomKeys.lastMessageId];
    final lastMessageSenderId = source[RoomKeys.lastMessageSenderId];
    final lastMessageDeleted = source[RoomKeys.lastMessageDeleted];
    final lastMessageStatuses = source[RoomKeys.lastMessageStatuses];
    final unseenCount = source[RoomKeys.unseenCount];
    final updatedAt = source[RoomKeys.updatedAt];

    final participants = source[RoomKeys.participants];
    final leaves = source[RoomKeys.leaves];
    final blocks = source[RoomKeys.blocks];
    final mutes = source[RoomKeys.mutes];
    final pins = source[RoomKeys.pins];

    final room = Room(
      isLocal: false,
      isDeleted: isDeleted is bool ? isDeleted : false,
      id: id is String && id.isNotEmpty ? id : '',
      createdBy: createdBy is String && createdBy.isNotEmpty ? createdBy : '',
      createdAt: ChatValueTimestamp.parse(createdAt),
      participants: participants is Iterable
          ? participants
              .parse(
                parser: (e) => e.toString(),
                check: (e) => e.isNotEmpty && e != RoomManager.i.me,
              )
              .toSet()
          : {},
      leaves: leaves is Iterable
          ? leaves
              .parse(parser: (e) => e.toString(), check: (e) => e.isNotEmpty)
              .toSet()
          : {},
      blocks: blocks is Iterable
          ? blocks
              .parse(parser: (e) => e.toString(), check: (e) => e.isNotEmpty)
              .toSet()
          : {},
      mutes: mutes is Map ? mutes.parse() : {},
      pins: pins is Map ? pins.parse() : {},
      lastMessage:
          lastMessage is String && lastMessage.isNotEmpty ? lastMessage : null,
      lastMessageId: lastMessageId is String && lastMessageId.isNotEmpty
          ? lastMessageId
          : '',
      lastMessageSenderId:
          lastMessageSenderId is String && lastMessageSenderId.isNotEmpty
              ? lastMessageSenderId
              : '',
      lastMessageStatuses:
          lastMessageStatuses is Map && lastMessageStatuses.isNotEmpty
              ? lastMessageStatuses.parse()
              : {},
      lastMessageDeleted:
          lastMessageDeleted is bool ? lastMessageDeleted : false,
      unseenCount: unseenCount is Map && unseenCount.isNotEmpty
          ? unseenCount.parse()
          : {},
      extra: extra ?? (ex is Map ? ex.parse() : {}),
      updatedAt: ChatValueTimestamp.parse(updatedAt),
    );

    if (isGroup) {
      final name = source[RoomKeys.name];
      final photo = source[RoomKeys.photo];
      return GroupRoom.from(
        room,
        name is String && name.isNotEmpty ? name : null,
        photo is String && photo.isNotEmpty ? photo : null,
      );
    }
    return DirectRoom.from(room);
  }

  Room copyWith({
    bool? isLocal,
    bool? isGroup,
    bool? isDeleted,
    bool? isPinned,
    String? id,
    ChatValueTimestamp? createdAt,
    String? createdBy,
    Set<String>? participants,
    Set<String>? leaves,
    Set<String>? blocks,
    Map<String, bool>? mutes,
    RoomExtra? extra,
    String? lastMessage,
    String? lastMessageId,
    String? lastMessageSenderId,
    bool? lastMessageDeleted,
    Map<String, MessageStatus>? lastMessageStatuses,
    Map<String, int>? unseenCount,
    ChatValueTimestamp? updatedAt,
  }) {
    final pins = this.pins;
    if (isPinned != null) {
      if (isPinned) {
        pins[me] = true;
      } else {
        if (pins.containsKey(me)) pins.remove(me);
      }
    }

    return Room(
      blocks: blocks ?? this.blocks,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      extra: extra ?? this.extra,
      id: id ?? this.id,
      isDeleted: isDeleted ?? this.isDeleted,
      isGroup: isGroup ?? this.isGroup,
      isLocal: isLocal ?? this.isLocal,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageDeleted: lastMessageDeleted ?? this.lastMessageDeleted,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageStatuses: lastMessageStatuses ?? this.lastMessageStatuses,
      leaves: leaves ?? this.leaves,
      mutes: mutes ?? this.mutes,
      pins: pins,
      participants: participants ?? this.participants,
      unseenCount: unseenCount ?? _unseenCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> get source {
    return {
      if (id.isNotEmpty) RoomKeys.id: id,
      if (isDeleted) RoomKeys.isDeleted: isDeleted,
      if (isGroup) RoomKeys.isGroup: isGroup,
      if (!createdAt.isEmpty) RoomKeys.createdAt: createdAt,
      if (createdBy.isNotEmpty) RoomKeys.createdBy: createdBy,
      if (participants.isNotEmpty) RoomKeys.participants: participants.toList(),
      if (leaves.isNotEmpty) RoomKeys.leaves: leaves.toList(),
      if (blocks.isNotEmpty) RoomKeys.blocks: blocks.toList(),
      if (mutes.isNotEmpty) RoomKeys.mutes: mutes,
      if (pins.isNotEmpty) RoomKeys.pins: pins,
      if ((lastMessage ?? '').isNotEmpty) RoomKeys.lastMessage: lastMessage,
      if (lastMessageId.isNotEmpty) RoomKeys.lastMessageId: lastMessageId,
      if (lastMessageSenderId.isNotEmpty)
        RoomKeys.lastMessageSenderId: lastMessageSenderId,
      if (lastMessageStatuses.isNotEmpty)
        RoomKeys.lastMessageStatuses: lastMessageStatuses.map((k, v) {
          return MapEntry(k, v.name);
        }),
      if (lastMessageDeleted) RoomKeys.lastMessageDeleted: lastMessageDeleted,
      if (_unseenCount.isNotEmpty) RoomKeys.unseenCount: _unseenCount,
      if (!updatedAt.isEmpty) RoomKeys.updatedAt: updatedAt,
      if (extra.isNotEmpty) RoomKeys.extra: extra,
    };
  }

  @override
  List<Object?> get props {
    return [
      id,
      isDeleted,
      isGroup,
      createdAt,
      createdBy,
      participants,
      leaves,
      blocks,
      mutes,
      pins,
      lastMessage,
      lastMessageId,
      lastMessageSenderId,
      lastMessageStatuses,
      lastMessageDeleted,
      _unseenCount,
      updatedAt,
      extra,
    ];
  }
}

class DirectRoom extends Room {
  String get friendId => participants.firstOrNull ?? '';

  bool get isActiveFriend {
    final id = friendId;
    if (id.isEmpty) return false;
    return isMuted(id);
  }

  const DirectRoom.empty() : this();

  const DirectRoom({
    super.isLocal,
    super.id = '',
    super.createdAt,
    super.createdBy = '',
    super.participants = const {},
    super.leaves = const {},
    super.blocks = const {},
    super.mutes = const {},
    super.pins = const {},
    super.lastMessage,
    super.lastMessageId,
    super.lastMessageSenderId = '',
    super.lastMessageDeleted = false,
    super.lastMessageStatuses = const {},
    super.unseenCount = const {},
    super.updatedAt,
    super.isDeleted = false,
    super.extra,
  }) : super(isGroup: false);

  factory DirectRoom.from(Room room) {
    return DirectRoom(
      isLocal: room.isLocal,
      id: room.id,
      createdBy: room.createdBy,
      createdAt: room.createdAt,
      participants: room.participants,
      leaves: room.leaves,
      blocks: room.blocks,
      mutes: room.mutes,
      pins: room.pins,
      extra: room.extra,
      lastMessage: room.lastMessage,
      lastMessageId: room.lastMessageId,
      lastMessageSenderId: room.lastMessageSenderId,
      lastMessageStatuses: room.lastMessageStatuses,
      lastMessageDeleted: room.lastMessageDeleted,
      unseenCount: room._unseenCount,
      updatedAt: room.updatedAt,
      isDeleted: room.isDeleted,
    );
  }

  @override
  DirectRoom copyWith({
    bool? isLocal,
    bool? isGroup,
    bool? isDeleted,
    bool? isPinned,
    String? id,
    ChatValueTimestamp? createdAt,
    String? createdBy,
    Set<String>? participants,
    Set<String>? leaves,
    Set<String>? blocks,
    Map<String, bool>? mutes,
    RoomExtra? extra,
    String? lastMessage,
    String? lastMessageId,
    String? lastMessageSenderId,
    bool? lastMessageDeleted,
    Map<String, MessageStatus>? lastMessageStatuses,
    Map<String, int>? unseenCount,
    ChatValueTimestamp? updatedAt,
  }) {
    final room = super.copyWith(
      blocks: blocks,
      createdAt: createdAt,
      createdBy: createdBy,
      extra: extra,
      id: id,
      isDeleted: isDeleted,
      isLocal: isLocal,
      lastMessage: lastMessage,
      lastMessageDeleted: lastMessageDeleted,
      lastMessageId: lastMessageId,
      lastMessageSenderId: lastMessageSenderId,
      lastMessageStatuses: lastMessageStatuses,
      leaves: leaves,
      mutes: mutes,
      isPinned: isPinned,
      participants: participants,
      unseenCount: unseenCount,
      updatedAt: updatedAt,
      isGroup: isGroup,
    );
    return DirectRoom(
      blocks: room.blocks,
      createdAt: room.createdAt,
      createdBy: room.createdBy,
      extra: room.extra,
      id: room.id,
      isDeleted: room.isDeleted,
      isLocal: room.isLocal,
      lastMessage: room.lastMessage,
      lastMessageDeleted: room.lastMessageDeleted,
      lastMessageId: room.lastMessageId,
      lastMessageSenderId: room.lastMessageSenderId,
      lastMessageStatuses: room.lastMessageStatuses,
      leaves: room.leaves,
      mutes: room.mutes,
      pins: room.pins,
      participants: room.participants,
      unseenCount: room._unseenCount,
      updatedAt: room.updatedAt,
    );
  }
}

class GroupRoom extends Room {
  final String? name;
  final String? photo;

  const GroupRoom.empty() : this();

  const GroupRoom({
    super.isLocal,
    super.createdAt,
    super.updatedAt,
    super.id = '',
    super.createdBy = '',
    super.participants = const {},
    super.leaves = const {},
    super.blocks = const {},
    super.mutes = const {},
    super.pins = const {},
    super.extra,
    super.lastMessage,
    super.lastMessageId,
    super.lastMessageSenderId = '',
    super.lastMessageDeleted = false,
    super.lastMessageStatuses = const {},
    super.unseenCount = const {},
    super.isDeleted,
    this.name,
    this.photo,
  }) : super(isGroup: true);

  factory GroupRoom.from(Room room, String? name, String? photo) {
    return GroupRoom(
      isLocal: room.isLocal,
      id: room.id,
      createdBy: room.createdBy,
      createdAt: room.createdAt,
      participants: room.participants,
      leaves: room.leaves,
      blocks: room.blocks,
      mutes: room.mutes,
      pins: room.pins,
      extra: room.extra,
      lastMessage: room.lastMessage,
      lastMessageId: room.lastMessageId,
      lastMessageSenderId: room.lastMessageSenderId,
      lastMessageStatuses: room.lastMessageStatuses,
      lastMessageDeleted: room.lastMessageDeleted,
      unseenCount: room._unseenCount,
      updatedAt: room.updatedAt,
      isDeleted: room.isDeleted,
      name: name,
      photo: photo,
    );
  }

  @override
  GroupRoom copyWith({
    bool? isLocal,
    bool? isGroup,
    bool? isDeleted,
    bool? isPinned,
    String? id,
    ChatValueTimestamp? createdAt,
    String? createdBy,
    Set<String>? participants,
    Set<String>? leaves,
    Set<String>? blocks,
    Map<String, bool>? mutes,
    RoomExtra? extra,
    String? lastMessage,
    String? lastMessageId,
    String? lastMessageSenderId,
    bool? lastMessageDeleted,
    Map<String, MessageStatus>? lastMessageStatuses,
    Map<String, int>? unseenCount,
    ChatValueTimestamp? updatedAt,
    String? name,
    String? photo,
  }) {
    final room = super.copyWith(
      blocks: blocks,
      createdAt: createdAt,
      createdBy: createdBy,
      extra: extra,
      id: id,
      isDeleted: isDeleted,
      isLocal: isLocal,
      lastMessage: lastMessage,
      lastMessageDeleted: lastMessageDeleted,
      lastMessageId: lastMessageId,
      lastMessageSenderId: lastMessageSenderId,
      lastMessageStatuses: lastMessageStatuses,
      leaves: leaves,
      mutes: mutes,
      isPinned: isPinned,
      participants: participants,
      unseenCount: unseenCount,
      updatedAt: updatedAt,
      isGroup: isGroup,
    );
    return GroupRoom(
      blocks: room.blocks,
      createdAt: room.createdAt,
      createdBy: room.createdBy,
      extra: room.extra,
      id: room.id,
      isDeleted: room.isDeleted,
      isLocal: room.isLocal,
      lastMessage: room.lastMessage,
      lastMessageDeleted: room.lastMessageDeleted,
      lastMessageId: room.lastMessageId,
      lastMessageSenderId: room.lastMessageSenderId,
      lastMessageStatuses: room.lastMessageStatuses,
      leaves: room.leaves,
      mutes: room.mutes,
      pins: room.pins,
      participants: room.participants,
      unseenCount: room._unseenCount,
      updatedAt: room.updatedAt,
      name: name ?? this.name,
      photo: photo ?? this.photo,
    );
  }

  @override
  Map<String, dynamic> get source {
    return {
      ...super.source,
      if ((name ?? '').isNotEmpty) RoomKeys.name: name,
      if ((photo ?? '').isNotEmpty) RoomKeys.photo: photo,
    };
  }

  @override
  List<Object?> get props => [...super.props, name, photo];
}
