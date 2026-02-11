import 'package:equatable/equatable.dart';

import '../managers/room.dart';
import '../utils/field_value.dart';
import '../utils/parser.dart';
import 'message.dart';

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
}

class Room extends Equatable {
  final bool isGroup;
  final bool isDeleted;
  final String id;
  final ChatValueTimestamp createdAt;
  final String createdBy;
  final Set<String> participants;
  final Set<String> leaves;
  final Set<String> blocks;
  final Map<String, bool> mutes;

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

  const Room.empty() : this();

  const Room({
    this.isDeleted = false,
    this.isGroup = false,
    this.id = '',
    this.createdAt = const ChatValueTimestamp(),
    this.createdBy = '',
    this.participants = const {},
    this.leaves = const {},
    this.blocks = const {},
    this.mutes = const {},
    this.lastMessage,
    this.lastMessageId = '',
    this.lastMessageSenderId = '',
    this.lastMessageDeleted = false,
    this.lastMessageStatuses = const {},
    Map<String, int> unseenCount = const {},
    this.updatedAt = const ChatValueTimestamp(),
  }) : _unseenCount = unseenCount;

  factory Room.parse(Object? source) {
    if (source is Room) return source;
    if (source is! Map) return Room.empty();
    final isGroup = source[RoomKeys.isGroup];
    if (isGroup is! bool) return Room.empty();

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

    final room = Room(
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
      lastMessage,
      lastMessageId,
      lastMessageSenderId,
      lastMessageStatuses,
      lastMessageDeleted,
      _unseenCount,
      updatedAt,
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

  const DirectRoom.empty() : this._();

  const DirectRoom._({
    super.id = '',
    super.createdAt,
    super.createdBy = '',
    super.participants = const {},
    super.leaves = const {},
    super.blocks = const {},
    super.mutes = const {},
    super.lastMessage,
    super.lastMessageId,
    super.lastMessageSenderId = '',
    super.lastMessageDeleted = false,
    super.lastMessageStatuses = const {},
    super.unseenCount = const {},
    super.updatedAt,
    super.isDeleted = false,
  }) : super(isGroup: false);

  factory DirectRoom.from(Room room) {
    return DirectRoom._(
      id: room.id,
      createdBy: room.createdBy,
      createdAt: room.createdAt,
      participants: room.participants,
      leaves: room.leaves,
      blocks: room.blocks,
      mutes: room.mutes,
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
}

class GroupRoom extends Room {
  final String? name;
  final String? photo;

  const GroupRoom.empty() : this._();

  const GroupRoom._({
    super.createdAt,
    super.updatedAt,
    super.id = '',
    super.createdBy = '',
    super.participants = const {},
    super.leaves = const {},
    super.blocks = const {},
    super.mutes = const {},
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
    return GroupRoom._(
      id: room.id,
      createdBy: room.createdBy,
      createdAt: room.createdAt,
      participants: room.participants,
      leaves: room.leaves,
      blocks: room.blocks,
      mutes: room.mutes,
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
  List<Object?> get props => [...super.props, name, photo];
}
