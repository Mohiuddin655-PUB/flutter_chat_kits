import 'package:equatable/equatable.dart';

import '../managers/room.dart';
import '../utils/field_value.dart';
import '../utils/parser.dart';
import 'message.dart';

typedef RoomExtra = Map<String, dynamic>;

class RoomKeys {
  final String id;
  final String friendId;
  final String participants;
  final String leaves;
  final String createdAt;
  final String createdBy;
  final String name;
  final String photo;
  final String isGroup;
  final String isDeleted;
  final String lastMessage;
  final String lastMessageId;
  final String lastMessageSenderId;
  final String lastMessageDeleted;
  final String lastMessageStatuses;
  final String unseenCount;
  final String updatedAt;
  final String mutes;
  final String archives;
  final String blocks;
  final String pins;
  final String removes;
  final String restricts;
  final String extra;

  static RoomKeys get i => RoomManager.i.modelConfigs.roomKeys;

  const RoomKeys({
    this.id = 'id',
    this.friendId = 'friendId',
    this.participants = 'participants',
    this.leaves = 'leaves',
    this.createdAt = 'createdAt',
    this.createdBy = 'createdBy',
    this.name = 'name',
    this.photo = 'photo',
    this.isGroup = 'isGroup',
    this.isDeleted = 'isDeleted',
    this.lastMessage = 'lastMessage',
    this.lastMessageId = 'lastMessageId',
    this.lastMessageSenderId = 'lastMessageSenderId',
    this.lastMessageDeleted = 'lastMessageDeleted',
    this.lastMessageStatuses = 'lastMessageStatuses',
    this.unseenCount = 'unseenCount',
    this.updatedAt = 'updatedAt',
    this.mutes = 'mutes',
    this.archives = 'archives',
    this.blocks = 'blocks',
    this.pins = 'pins',
    this.removes = 'removes',
    this.restricts = 'restricts',
    this.extra = 'extra',
  });
}

class Room extends Equatable {
  final Set<String> archives;
  final Set<String> blocks;
  final ChatValueTimestamp createdAt;
  final String createdBy;
  final RoomExtra extra;
  final String id;
  final bool isDeleted;
  final bool isGroup;
  final bool isLocal;
  final String? lastMessage;
  final bool lastMessageDeleted;
  final String lastMessageId;
  final String lastMessageSenderId;
  final Map<String, MessageStatus> lastMessageStatuses;
  final Set<String> leaves;
  final Set<String> mutes;
  final Set<String> participants;
  final Set<String> pins;
  final Map<String, String> removes;
  final Set<String> restricts;
  final Map<String, int> _unseenCount;
  final ChatValueTimestamp updatedAt;

  bool get isEmpty => id.isEmpty || participants.isEmpty;

  bool get isAdminByMe => createdBy == me;

  bool get isArchivedByMe => archives.contains(me);

  bool get isBlockByMe => blocks.contains(me);

  bool get isLeaveByMe => isDeleted || leaves.contains(me);

  bool get isMutedByMe => mutes.contains(me);

  bool get isPinnedByMe => pins.contains(me);

  bool get isRemovedByMe {
    return removes.containsKey(me) && removes[me] == lastMessageId;
  }

  bool get isRestrictedByMe => restricts.contains(me);

  bool get isSentByMe => lastMessageSenderId == me;

  int get unseenCount {
    final count = _unseenCount[me];
    return count ?? 0;
  }

  String get me => RoomManager.i.me;

  String? get lastMessageStatus {
    return lastMessageStatuses[me]?.name;
  }

  String formattedLastMessage({
    String? sender,
    bool isTyping = false,
    String Function(String key, String value)? formatter,
  }) {
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
    String msg = lastMessage ?? '';
    if (formatter != null) {
      if (msg.startsWith('{SENDER}')) {
        msg = formatter('{SENDER}', msg);
      }
      if (msg.startsWith('{SENDER_OR_EMPTY}')) {
        msg = formatter('{SENDER_OR_EMPTY}', msg);
      }
      return msg;
    }
    return msg
        .replaceAll("{SENDER}", isMe ? "You" : sender)
        .replaceAll('{SENDER_OR_EMPTY}', isMe ? "You: " : '');
  }

  const Room.empty() : this();

  const Room({
    this.archives = const {},
    this.blocks = const {},
    this.createdAt = const ChatValueTimestamp(),
    this.createdBy = '',
    this.extra = const {},
    this.id = '',
    this.isDeleted = false,
    this.isGroup = false,
    this.isLocal = false,
    this.lastMessage,
    this.lastMessageDeleted = false,
    this.lastMessageId = '',
    this.lastMessageSenderId = '',
    this.lastMessageStatuses = const {},
    this.leaves = const {},
    this.mutes = const {},
    this.participants = const {},
    this.pins = const {},
    this.removes = const {},
    this.restricts = const {},
    Map<String, int> unseenCount = const {},
    this.updatedAt = const ChatValueTimestamp(),
  }) : _unseenCount = unseenCount;

  factory Room.parse(Object? source, {RoomExtra? extra}) {
    if (source is Room) return source;
    if (source is! Map) return Room.empty();
    final keys = RoomKeys.i;
    final isGroup = source[keys.isGroup];
    if (isGroup is! bool) return Room.empty();

    final archives = source[keys.archives];
    final blocks = source[keys.blocks];
    final createdAt = source[keys.createdAt];
    final createdBy = source[keys.createdBy];
    final ex = source[keys.extra];
    final id = source[keys.id];
    final isDeleted = source[keys.isDeleted];
    final lastMessage = source[keys.lastMessage];
    final lastMessageDeleted = source[keys.lastMessageDeleted];
    final lastMessageId = source[keys.lastMessageId];
    final lastMessageSenderId = source[keys.lastMessageSenderId];
    final lastMessageStatuses = source[keys.lastMessageStatuses];
    final leaves = source[keys.leaves];
    final mutes = source[keys.mutes];
    final participants = source[keys.participants];
    final pins = source[keys.pins];
    final removes = source[keys.removes];
    final restricts = source[keys.restricts];
    final unseenCount = source[keys.unseenCount];
    final updatedAt = source[keys.updatedAt];

    final room = Room(
      isLocal: false,
      isGroup: isGroup,
      archives: archives is Iterable ? archives.parsedStrings.toSet() : {},
      blocks: blocks is Iterable ? blocks.parsedStrings.toSet() : {},
      createdAt: ChatValueTimestamp.parse(createdAt),
      createdBy: createdBy is String && createdBy.isNotEmpty ? createdBy : '',
      extra: extra ?? (ex is Map ? ex.parse() : {}),
      id: id is String && id.isNotEmpty ? id : '',
      isDeleted: isDeleted is bool ? isDeleted : false,
      lastMessage:
          lastMessage is String && lastMessage.isNotEmpty ? lastMessage : null,
      lastMessageDeleted:
          lastMessageDeleted is bool ? lastMessageDeleted : false,
      lastMessageId: lastMessageId is String && lastMessageId.isNotEmpty
          ? lastMessageId
          : '',
      lastMessageSenderId:
          lastMessageSenderId is String ? lastMessageSenderId : '',
      lastMessageStatuses:
          lastMessageStatuses is Map ? lastMessageStatuses.parse() : {},
      leaves: leaves is Iterable ? leaves.parsedStrings.toSet() : {},
      mutes: mutes is Iterable ? mutes.parsedStrings.toSet() : {},
      participants:
          participants is Iterable ? participants.parsedStrings.toSet() : {},
      pins: pins is Iterable ? pins.parsedStrings.toSet() : {},
      removes: removes is Map ? removes.parse() : {},
      restricts: restricts is Iterable ? restricts.parsedStrings.toSet() : {},
      unseenCount: unseenCount is Map ? unseenCount.parse() : {},
      updatedAt: ChatValueTimestamp.parse(updatedAt),
    );

    if (isGroup) {
      final name = source[keys.name];
      final photo = source[keys.photo];
      return GroupRoom.from(
        room,
        name: name is String && name.isNotEmpty ? name : null,
        photo: photo is String && photo.isNotEmpty ? photo : null,
      );
    }
    return DirectRoom.from(room);
  }

  Room copyWith({
    Iterable<String>? blocks,
    ChatValueTimestamp? createdAt,
    String? createdBy,
    RoomExtra? extra,
    String? id,
    bool? isAddMember,
    bool? isArchived,
    bool? isBlocked,
    bool? isDeleted,
    bool? isGroup,
    bool? isLeaved,
    bool? isLocal,
    bool? isMuted,
    bool? isPinned,
    bool? isRemoved,
    bool? isRestricted,
    String? lastMessage,
    bool? lastMessageDeleted,
    String? lastMessageId,
    String? lastMessageSenderId,
    Map<String, MessageStatus>? lastMessageStatuses,
    Iterable<String>? participants,
    Iterable<String>? restricts,
    Map<String, int>? unseenCount,
    ChatValueTimestamp? updatedAt,
  }) {
    final mBlocks = {...this.blocks};
    if (isBlocked != null && blocks != null && blocks.isNotEmpty) {
      if (isBlocked) {
        mBlocks.addAll(blocks);
      } else {
        mBlocks.removeAll(blocks);
      }
    }

    final mArchives = {...archives};
    if (isArchived != null) {
      if (isArchived) {
        mArchives.add(me);
      } else {
        mArchives.remove(me);
      }
    }

    final mLeaves = {...leaves};
    if (isLeaved != null) {
      if (isLeaved) {
        mLeaves.add(me);
      } else {
        mLeaves.remove(me);
      }
    }

    final mMutes = {...mutes};
    if (isMuted != null) {
      if (isMuted) {
        mMutes.add(me);
      } else {
        mMutes.remove(me);
      }
    }

    final mPins = {...pins};
    if (isPinned != null) {
      if (isPinned) {
        mPins.add(me);
      } else {
        mPins.remove(me);
      }
    }

    final mParticipants = {...this.participants};
    if (isAddMember != null &&
        participants != null &&
        participants.isNotEmpty) {
      if (isAddMember) {
        mParticipants.addAll(participants);
      } else {
        mParticipants.removeAll(participants);
      }
    }

    final mRemoves = {...removes};
    if (isRemoved != null &&
        lastMessageId != null &&
        lastMessageId.isNotEmpty) {
      if (isRemoved) {
        mRemoves[me] = lastMessageId;
      } else {
        mRemoves.remove(me);
      }
    }

    final mRestricts = {...this.restricts};
    if (isRestricted != null && restricts != null && restricts.isNotEmpty) {
      if (isRestricted) {
        mRestricts.addAll(restricts);
      } else {
        mRestricts.removeAll(restricts);
      }
    }

    return Room(
      archives: mArchives,
      blocks: mBlocks,
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
      leaves: mLeaves,
      mutes: mMutes,
      participants: mParticipants,
      pins: mPins,
      removes: mRemoves,
      restricts: mRestricts,
      unseenCount: unseenCount ?? _unseenCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> get source {
    final keys = RoomKeys.i;
    return {
      if (archives.isNotEmpty) keys.archives: archives.toList(),
      if (blocks.isNotEmpty) keys.blocks: blocks.toList(),
      if (!createdAt.isEmpty) keys.createdAt: createdAt,
      if (createdBy.isNotEmpty) keys.createdBy: createdBy,
      if (id.isNotEmpty) keys.id: id,
      if (isDeleted) keys.isDeleted: isDeleted,
      if (isGroup) keys.isGroup: isGroup,
      if ((lastMessage ?? '').isNotEmpty) keys.lastMessage: lastMessage,
      if (lastMessageDeleted) keys.lastMessageDeleted: lastMessageDeleted,
      if (lastMessageId.isNotEmpty) keys.lastMessageId: lastMessageId,
      if (lastMessageSenderId.isNotEmpty)
        keys.lastMessageSenderId: lastMessageSenderId,
      if (lastMessageStatuses.isNotEmpty)
        keys.lastMessageStatuses: lastMessageStatuses.map((k, v) {
          return MapEntry(k, v.name);
        }),
      if (leaves.isNotEmpty) keys.leaves: leaves.toList(),
      if (mutes.isNotEmpty) keys.mutes: mutes.toList(),
      if (participants.isNotEmpty) keys.participants: participants.toList(),
      if (pins.isNotEmpty) keys.pins: pins.toList(),
      if (removes.isNotEmpty) keys.removes: removes,
      if (restricts.isNotEmpty) keys.restricts: restricts.toList(),
      if (_unseenCount.isNotEmpty) keys.unseenCount: _unseenCount,
      if (!updatedAt.isEmpty) keys.updatedAt: updatedAt,
      if (extra.isNotEmpty) keys.extra: extra,
    };
  }

  @override
  List<Object?> get props {
    return [
      archives,
      blocks,
      createdAt,
      createdBy,
      extra,
      id,
      isDeleted,
      isGroup,
      lastMessage,
      lastMessageDeleted,
      lastMessageId,
      lastMessageSenderId,
      lastMessageStatuses,
      leaves,
      mutes,
      participants,
      pins,
      removes,
      restricts,
      _unseenCount,
      updatedAt,
    ];
  }
}

class DirectRoom extends Room {
  String get friendId {
    return participants.firstWhere((e) => e != me, orElse: () => '');
  }

  const DirectRoom.empty() : this();

  const DirectRoom({
    super.archives,
    super.blocks,
    super.createdAt,
    super.createdBy,
    super.extra,
    super.id,
    super.isDeleted,
    super.isLocal,
    super.lastMessage,
    super.lastMessageDeleted,
    super.lastMessageId,
    super.lastMessageSenderId,
    super.lastMessageStatuses,
    super.leaves,
    super.mutes,
    super.participants,
    super.pins,
    super.removes,
    super.restricts,
    super.unseenCount,
    super.updatedAt,
  }) : super(isGroup: false);

  factory DirectRoom.from(Room room) {
    return DirectRoom(
      archives: room.archives,
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
      participants: room.participants,
      pins: room.pins,
      removes: room.removes,
      restricts: room.restricts,
      unseenCount: room._unseenCount,
      updatedAt: room.updatedAt,
    );
  }

  @override
  DirectRoom copyWith({
    Iterable<String>? blocks,
    ChatValueTimestamp? createdAt,
    String? createdBy,
    RoomExtra? extra,
    String? id,
    bool? isAddMember,
    bool? isArchived,
    bool? isBlocked,
    bool? isDeleted,
    bool? isGroup,
    bool? isLeaved,
    bool? isLocal,
    bool? isMuted,
    bool? isPinned,
    bool? isRemoved,
    bool? isRestricted,
    String? lastMessage,
    bool? lastMessageDeleted,
    String? lastMessageId,
    String? lastMessageSenderId,
    Map<String, MessageStatus>? lastMessageStatuses,
    Iterable<String>? participants,
    Iterable<String>? restricts,
    Map<String, int>? unseenCount,
    ChatValueTimestamp? updatedAt,
  }) {
    final room = super.copyWith(
      blocks: blocks,
      createdAt: createdAt,
      createdBy: createdBy,
      extra: extra,
      id: id,
      isAddMember: isAddMember,
      isArchived: isArchived,
      isBlocked: isBlocked,
      isDeleted: isDeleted,
      isGroup: isGroup,
      isLeaved: isLeaved,
      isLocal: isLocal,
      isMuted: isMuted,
      isPinned: isPinned,
      isRemoved: isRemoved,
      isRestricted: isRestricted,
      lastMessage: lastMessage,
      lastMessageDeleted: lastMessageDeleted,
      lastMessageId: lastMessageId,
      lastMessageSenderId: lastMessageSenderId,
      lastMessageStatuses: lastMessageStatuses,
      participants: participants,
      restricts: restricts,
      unseenCount: unseenCount,
      updatedAt: updatedAt,
    );
    return DirectRoom.from(room);
  }
}

class GroupRoom extends Room {
  final String? name;
  final String? photo;

  const GroupRoom.empty() : this();

  const GroupRoom({
    super.archives,
    super.blocks,
    super.createdAt,
    super.createdBy,
    super.extra,
    super.id,
    super.isDeleted,
    super.isLocal,
    super.lastMessage,
    super.lastMessageDeleted,
    super.lastMessageId,
    super.lastMessageSenderId,
    super.lastMessageStatuses,
    super.leaves,
    super.mutes,
    super.participants,
    super.pins,
    super.removes,
    super.restricts,
    super.unseenCount,
    super.updatedAt,
    this.name,
    this.photo,
  }) : super(isGroup: true);

  factory GroupRoom.from(Room room, {String? name, String? photo}) {
    return GroupRoom(
      archives: room.archives,
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
      participants: room.participants,
      pins: room.pins,
      removes: room.removes,
      restricts: room.restricts,
      unseenCount: room._unseenCount,
      updatedAt: room.updatedAt,
      name: name,
      photo: photo,
    );
  }

  @override
  GroupRoom copyWith({
    Iterable<String>? blocks,
    ChatValueTimestamp? createdAt,
    String? createdBy,
    RoomExtra? extra,
    String? id,
    bool? isAddMember,
    bool? isArchived,
    bool? isBlocked,
    bool? isDeleted,
    bool? isGroup,
    bool? isLeaved,
    bool? isLocal,
    bool? isMuted,
    bool? isPinned,
    bool? isRemoved,
    bool? isRestricted,
    String? lastMessage,
    bool? lastMessageDeleted,
    String? lastMessageId,
    String? lastMessageSenderId,
    Map<String, MessageStatus>? lastMessageStatuses,
    Iterable<String>? participants,
    Iterable<String>? restricts,
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
      isAddMember: isAddMember,
      isArchived: isArchived,
      isBlocked: isBlocked,
      isDeleted: isDeleted,
      isGroup: isGroup,
      isLeaved: isLeaved,
      isLocal: isLocal,
      isMuted: isMuted,
      isPinned: isPinned,
      isRemoved: isRemoved,
      isRestricted: isRestricted,
      lastMessage: lastMessage,
      lastMessageDeleted: lastMessageDeleted,
      lastMessageId: lastMessageId,
      lastMessageSenderId: lastMessageSenderId,
      lastMessageStatuses: lastMessageStatuses,
      participants: participants,
      restricts: restricts,
      unseenCount: unseenCount,
      updatedAt: updatedAt,
    );
    return GroupRoom.from(
      room,
      name: name ?? this.name,
      photo: photo ?? this.photo,
    );
  }

  @override
  Map<String, dynamic> get source {
    final keys = RoomKeys.i;
    return {
      ...super.source,
      if ((name ?? '').isNotEmpty) keys.name: name,
      if ((photo ?? '').isNotEmpty) keys.photo: photo,
    };
  }

  @override
  List<Object?> get props => [...super.props, name, photo];
}
